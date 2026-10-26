# 30. SEO, мета-теги и доступность

**Актуально на 26.10.2026.** Lighthouse: **SEO 67**, **Accessibility 83**, Best Practices 100.

Здесь собраны конкретные провалы и исправления. Это не «оптимизация ради баллов»: отсутствие description/canonical и битый sitemap напрямую влияют на выдачу.

---

## 1. Дублирующийся хост

`https://nlb.by/` и `https://www.nlb.by/` отдают **одинаковый HTML 200 OK** (218 884 байта, одинаковый title). Canonical при этом отсутствует, а sitemap использует `www`.

Исправление — выбрать один хост и 301 на него:

```nginx
server {
    listen 443 ssl;
    server_name nlb.by;
    return 301 https://www.nlb.by$request_uri;
}
```

Если канонический — без `www`, то наоборот. Главное: один хост, один canonical, sitemap на том же хосте.

## 2. Meta description

На главной и внутренних страницах `<meta name="description">` **нет**. Google сам формирует сниппет — часто неудачно.

В Битриксе:

```php
// В шаблоне страницы или компоненте
$APPLICATION->SetPageProperty(
    "description",
    "Национальная библиотека Беларуси: электронный каталог, электронная библиотека, выставки и экскурсии, обзорная площадка. Минск, пр. Независимости, 116."
);
```

Для главной — 140–160 символов, для новостей — из `PREVIEW_TEXT`:

```php
$APPLICATION->SetPageProperty("description", strip_tags($arResult["PREVIEW_TEXT"]));
```

Проверка:

```bash
curl -s https://nlb.by/ | grep -o '<meta name="description"[^>]*>'
```

## 3. Canonical

Отсутствует на всех проверенных страницах. Без него пагинация, `?utm_`, `?clear_cache=Y` и два хоста плодят дубли.

```php
// header.php, после <head>
$canonical = "https://www.nlb.by" . $APPLICATION->GetCurPage();
// убрать query-строку, кроме значимых параметров пагинации
?>
<link rel="canonical" href="<?= htmlspecialchars($canonical) ?>">
```

Для страниц с пагинацией canonical должен указывать на конкретную страницу (`?PAGEN_1=2`), а не на первую — иначе Google не увидит остальные.

## 4. Open Graph

Нет ни одного `og:`-тега. При репосте в соцсети/мессенджеры картинка и описание не подтягиваются.

```php
<meta property="og:type" content="website">
<meta property="og:site_name" content="Национальная библиотека Беларуси">
<meta property="og:title" content="<?= htmlspecialchars($APPLICATION->GetTitle()) ?>">
<meta property="og:description" content="...">
<meta property="og:url" content="<?= htmlspecialchars($canonical) ?>">
<meta property="og:image" content="https://www.nlb.by/upload/og-default.jpg">
<meta property="og:image:width" content="1200">
<meta property="og:image:height" content="630">
<meta name="twitter:card" content="summary_large_image">
```

Картинка 1200×630, ≤300 КБ. Для новостей — `PREVIEW_PICTURE`.

## 5. Два `<h1>` на главной

В HTML hero-блок и набор картинок слайдера присутствуют **дважды** — судя по разметке, это две копии для десктопа и мобилки. Отсюда два `<h1>` с одинаковым текстом и дубли изображений в DOM.

Варианты:

1. **Лучше:** один экземпляр разметки, адаптив только на CSS.
2. **Быстро:** у мобильной/десктопной копии заменить `<h1>` на `<div class="h1">` и скрыть дубль через `aria-hidden="true"` (но не `display:none`, если он нужен визуально).

Проверка:

```bash
curl -s https://nlb.by/ | grep -o '<h1' | wc -l   # должно быть 1
```

## 6. Alt у изображений

Формально `alt` есть у всех, но у многих значение `" "` (пробел) — для скринридера это пустая строка. В карточках новостей/событий alt должен быть осмысленным:

```php
alt="<?= htmlspecialchars($arItem["NAME"]) ?>"
```

Для декоративных (герб, флаг, иконки соцсетей) — `alt=""` (пустой, без пробела).

Lighthouse также ругается на `image-alt` — проверьте динамические картинки, которые выводятся без атрибута.

## 7. Ссылки без доступного имени

3 ссылки без текста/alt/`aria-label` — вероятно иконки соцсетей в футере и стрелки слайдера.

```html
<a href="https://vk.com/nlb_by" aria-label="ВКонтакте">
    <svg aria-hidden="true">...</svg>
</a>
```

Иконка внутри — `aria-hidden="true"`, имя даёт `aria-label`.

## 8. Контраст и тач-цели

Lighthouse: `color-contrast` и `target-size`.

- Контраст: серый текст на белом и белый текст на полупрозрачном hero. Минимум WCAG AA — 4,5:1 для обычного текста, 3:1 для крупного. Проверять через axe DevTools — он покажет конкретные элементы.
- Тач-цели: кнопки меню, соцсети, стрелки слайдера. Минимум 24×24 CSS px (WCAG 2.2), лучше 44×44. Добавить padding, а не увеличивать иконку.

```css
.social a { display: inline-flex; align-items: center; justify-content: center; min-width: 44px; min-height: 44px; }
```

## 9. Sitemap

```
/sitemap_index.xml → /sitemap_000.xml
```

| Параметр | Значение |
|---|---|
| URL в sitemap | **37 051** |
| `lastmod` 2017–2018 | **22 606** |
| Упоминаний `/adminer.php` | 29 (сейчас 404) |
| Размер файла | 6,2 МБ |
| `Sitemap:` в robots.txt | нет |

Проблемы:

- sitemap не обновлялся с 2018 года;
- внутри мусор: `/adminer.php`, `/shop/login/`, старые URL;
- 6,2 МБ в одном файле — медленно для краулеров (лимит 50 000 URL / 50 МБ, формально проходит, но лучше разбить);
- `robots.txt` не указывает на карту.

Что сделать:

1. Перегенерировать карту в Битриксе: **Настройки → Поиск → Карта сайта** (или модуль `search` → `sitemap`), включить только публичные разделы.
2. Исключить `/bitrix/`, `/local/`, `/upload/`, `/adminer.php`, `/shop/`, `/user/`, `/search/`.
3. Разбить по разделам (news, events, content, projects).
4. Добавить в `robots.txt`:

```
Sitemap: https://www.nlb.by/sitemap_index.xml
```

5. Проверить в Google Search Console → «Файлы Sitemap» и Яндекс.Вебмастер.

## 10. hreflang

Есть три языковые версии: `/` (ru), `/by/` (be), `/en/` (en), но `hreflang` не размечен. Добавить в `<head>` каждой версии:

```html
<link rel="alternate" hreflang="ru" href="https://www.nlb.by/">
<link rel="alternate" hreflang="be" href="https://www.nlb.by/by/">
<link rel="alternate" hreflang="en" href="https://www.nlb.by/en/">
<link rel="alternate" hreflang="x-default" href="https://www.nlb.by/">
```

## 11. Мелочи, которые уже в порядке

- `lang="ru"` на `<html>` — есть.
- `viewport` с `viewport-fit=cover` — есть.
- Favicon-набор (ico, svg, png, apple-touch, manifest) — есть.
- 404 отдаёт код 404 — правильно.
- JSON-LD на главной — 2 блока, проверить в Schema Validator.

## Проверка

```bash
# description / canonical / og / h1
curl -s https://nlb.by/ | grep -c 'name="description"'
curl -s https://nlb.by/ | grep -c 'rel="canonical"'
curl -s https://nlb.by/ | grep -c 'property="og:'
curl -s https://nlb.by/ | grep -o '<h1' | wc -l

# дублирующийся хост
curl -sI https://nlb.by/ | head -1
curl -sI https://www.nlb.by/ | head -1

# sitemap
curl -s https://nlb.by/robots.txt | grep -i sitemap
```

Онлайн: Google Rich Results Test, Schema Validator, Screaming Frog (дубли title/description, битые ссылки), axe DevTools (контраст, alt, target-size).

## Приоритет

1. Canonical + 301 на один хост — самое важное, 1 час.
2. Meta description + OG — 2 часа, даёт нормальные сниппеты.
3. Sitemap — 2–4 часа, иначе 37 тысяч URL живут в 2018 году.
4. Один H1, alt, aria-label, контраст — 1 день по всему шаблону.
