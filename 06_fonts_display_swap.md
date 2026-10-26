# 6. Шрифты: self-hosted уже есть — что осталось

**Статус на 26.10.2026: миграция с Google Fonts выполнена ✅.** Старая версия этой инструкции (preconnect + `display=swap` для `fonts.googleapis.com`) больше не нужна — оставлена как чек-лист по остаткам.

## Что сделано

- Шрифты **Raleway** (текст) и **Lora** (заголовки) лежат локально в `/local/templates/index_2026/assets/fonts/`.
- Формат WOFF2, `font-display: swap` у всех 41 правила `@font-face`.
- Внешних запросов к `fonts.googleapis.com` / `fonts.gstatic.com` нет.
- Файлы разбиты по `unicode-range` (cyrillic, latin, latin-ext, vietnamese, math, symbols и т.д.).

Фактически браузер грузит 4 файла на 131 КБ: Raleway cyrillic 25 КБ + latin 47 КБ, Lora cyrillic 21 КБ + latin 37 КБ.

## Проблема 1: неверный MIME

```bash
curl -sI https://nlb.by/local/templates/index_2026/assets/fonts/raleway/1Ptug8zYS_SKggPNyCkIT5lu.woff2
# Content-Type: application/force-download
```

Должно быть `font/woff2`. Сейчас браузеры шрифт всё же применяют, но при `X-Content-Type-Options: nosniff` это хрупко: часть браузеров/прокси может отбросить файл.

Nginx:

```nginx
# В http-блоке
include mime.types;
types {
    font/woff2 woff2;
    font/woff  woff;
}
default_type application/octet-stream;  # НЕ application/force-download
```

Если `default_type application/force-download` задан глобально — он и есть причина. Проверьте `nginx -T | grep force-download`.

## Проблема 2: нет preload

Критичные для первого экрана — два кириллических файла:

```html
<link rel="preload"
      href="/local/templates/index_2026/assets/fonts/raleway/1Ptug8zYS_SKggPNyCkIT5lu.woff2"
      as="font" type="font/woff2" crossorigin>
<link rel="preload"
      href="/local/templates/index_2026/assets/fonts/lora/0QIvMX1D_JOuMw77I-NP.woff2"
      as="font" type="font/woff2" crossorigin>
```

Правила:

- только 2 файла, не 4 и не 12 — иначе preload конкурирует с LCP-картинкой;
- обязательно `crossorigin`, иначе браузер скачает шрифт дважды;
- латиницу не preload-ить: она нужна для цифр и латинских имён, догрузится сама.

## Проблема 3: 41 правило `@font-face` на 21 КБ CSS

Для русскоязычного сайта реально нужны только `cyrillic` и `latin`. `cyrillic-ext`, `vietnamese`, `math`, `symbols` можно убрать — это ~60% CSS шрифтов.

Если файлы — вариативные (один URL на веса 400–700), корректнее так:

```css
@font-face {
    font-family: 'Raleway';
    font-style: normal;
    font-weight: 400 700;          /* диапазон вместо 4 правил */
    font-display: swap;
    src: url('/local/templates/index_2026/assets/fonts/raleway/...woff2') format('woff2');
    unicode-range: U+0301, U+0400-045F, U+0490-0491, U+04B0-04B1, U+2116;
}
```

Проверьте, вариативный ли файл:

```bash
python -c "from fontTools.ttLib import TTFont; f=TTFont('file.woff2'); print('fvar' in f)"
```

Если `fvar` есть — это вариативный шрифт, и 4 одинаковых `@font-face` с разным `font-weight` избыточны.

## Проблема 4: кэш 30 дней

```nginx
location ~* \.(woff2?|ttf|otf)$ {
    add_header Cache-Control "public, max-age=31536000, immutable";
    add_header Vary "Accept-Encoding";
    expires 365d;
}
```

## Проблема 5: сдвиг при swap

Пока шрифт грузится, текст рисуется системным (Arial). Чтобы метрики совпадали и не было скачка, добавьте fallback с подгонкой:

```css
@font-face {
    font-family: 'Raleway-fallback';
    src: local('Arial');
    size-adjust: 97%;
    ascent-override: 94%;
    descent-override: 24%;
    line-gap-override: 0%;
}

body { font-family: 'Raleway', 'Raleway-fallback', Arial, sans-serif; }
```

Точные проценты подбираются по `font-size-adjust`/DevTools; это убирает вклад шрифтов в CLS.

## Проверка

```bash
# MIME
curl -sI https://nlb.by/local/templates/index_2026/assets/fonts/raleway/1Ptug8zYS_SKggPNyCkIT5lu.woff2 | grep -i content-type

# preload в HTML
curl -s https://nlb.by/ | grep -c 'rel="preload".*woff2'

# сколько шрифтов реально грузится
# DevTools → Network → фильтр Font
```

Цель: 2 preload, 4 файла максимум, `font/woff2`, кэш год.
