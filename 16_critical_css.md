# 16. Critical CSS — критические стили первого экрана

**Актуально на 26.10.2026.**

## Что сейчас

Пять блокирующих `<link rel="stylesheet">` в `<head>`:

| Файл | Decoded | Gzip | Что внутри |
|---|---|---|---|
| `main.css` | 95 КБ | ~20 КБ | весь шаблон: шапка, hero, карточки, футер, медиазапросы |
| `bitrix.css` | 75 КБ | ~12 КБ | стили ядра/компонентов |
| `fonts-local.css` | 21 КБ | ~5 КБ | 41 `@font-face` |
| `a11y-2026.css` | 9 КБ | ~2 КБ | режим «Слабовидящим» |
| шаблонный бандл | 1 КБ | — | остатки |

Итого **199 КБ decoded / ~47 КБ gzip**, и всё это render-blocking. FCP — **1 056 мс** на десктопе и **1,4 с** в мобильном Lighthouse, то есть больше секунды браузер ждёт CSS, прежде чем показать хоть что-то.

Lighthouse 13.3 уточняет: **Render-blocking requests — −170 мс**, **Reduce unused CSS — −15 КиБ**, **Minify CSS — −6 КиБ**. 170 мс — это вклад именно блокировки; остальное время FCP — TTFB и JS. Поэтому критический CSS даёт заметный, но не десятикратный выигрыш.

## План

1. Выделить критический CSS первого экрана (шапка + hero + cookie-баннер + сетка карточек) — обычно 10–15 КБ.
2. Встроить его `<style>` в `<head>`.
3. Остальное грузить асинхронно.
4. `a11y-2026.css` оставить синхронным или тоже инлайнить — это переключатель версии для слабовидящих, он не должен «мигать».

### Шаг 1. Сгенерировать критический CSS

```bash
npx critical https://nlb/ \
  --base https://nlb/ \
  --inline \
  --width 390 --height 844 \
  --minify \
  --out /tmp/critical
```

Или через Penthouse (даёт более чистый результат):

```bash
npx penthouse https://nlb/ /tmp/critical.css \
  --width 390 --height 844 --maxEmbeddedBase64Length 0
```

Проверьте глазами: в критический CSS должны попасть `.header`, `.hero`, `.cookie`, `.container`, базовые `body`/`h1`.

### Шаг 2. Встроить в `header.php`

```php
<?php
// /local/templates/index_2026/header.php
$critical = $_SERVER["DOCUMENT_ROOT"] . "/local/templates/index_2026/assets/css/critical.css";
if (is_file($critical)) {
    echo "<style>" . file_get_contents($critical) . "</style>";
}
?>
```

Не инлайньте туда base64-картинки — получите +100 КБ HTML.

### Шаг 3. Асинхронная загрузка остального

```html
<link rel="preload" href="/local/templates/index_2026/assets/css/main.css?v=..." as="style">
<link rel="stylesheet" href="/local/templates/index_2026/assets/css/main.css?v=..."
      media="print" onload="this.media='all'">
<noscript>
    <link rel="stylesheet" href="/local/templates/index_2026/assets/css/main.css?v=...">
</noscript>
```

То же для `bitrix.css`. Для `fonts-local.css` лучше не `media=print`, а оставить синхронным: без него будет FOUT/скачок текста. Либо инлайнить только `@font-face` для cyrillic+latin.

### Шаг 4. Разобраться с `bitrix.css`

75 КБ и 321 правило на публичной странице — много. Проверьте Coverage (DevTools → Ctrl+Shift+P → «Show Coverage»): если используется <30%, вырежьте нужное в `main.css`, а `bitrix.css` не подключайте на главной.

## Через `init.php` (если нет доступа к шаблону)

```php
AddEventHandler("main", "OnEndBufferContent", function (&$content) {
    if (defined("ADMIN_SECTION") || defined("BX_AJAX")) return;

    $content = preg_replace(
        '#<link[^>]*href="([^"]*index_2026/assets/css/(?:main|bitrix)\.css[^"]*)"[^>]*>#i',
        '<link rel="stylesheet" href="$1" media="print" onload="this.media=\'all\'">' .
        '<noscript><link rel="stylesheet" href="$1"></noscript>',
        $content
    );
});
```

Осторожно: при таком подходе возможен FOUC. Обязательно с критическим CSS inline.

## Проверка

- Lighthouse → «Render-blocking requests» — 0 CSS, экономия ~170 мс.
- FCP: 1 056 мс на десктопе / 1,4 с на мобиле, цель 700–900 мс.
- DevTools → Coverage → unused CSS < 20% (сейчас Lighthouse оценивает −15 КиБ).
- Визуально: шапка и hero отрисованы сразу, без «прыжка» стилей.

## Чего не делать

- Не делать `media="print"` для всех стилей без критического CSS — пользователь увидит «голую» страницу.
- Не инлайнить 95 КБ `main.css` целиком в HTML — это ухудшит TTFB и не закэшируется.
- Не забывать про `<noscript>`.
