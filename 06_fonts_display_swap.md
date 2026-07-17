# 6. Google Fonts: display=swap + preconnect

## Найдите, где подключены шрифты

Поищите в шаблонах sites:
```bash
grep -r "fonts.googleapis.com" /path/to/site/bitrix/templates/
```

## Исправьте подключение

Было:
```html
<link href="https://fonts.googleapis.com/css2?family=Open+Sans:wght@400;700&family=Noto+Serif:wght@400;700&display=swap" rel="stylesheet">
```

Добавьте **preconnect** и **display=swap**:

```html
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Open+Sans:wght@400;700&family=Noto+Serif:wght@400;700&display=swap" rel="stylesheet">
```

**Ключевое:** `display=swap` уже есть в URL? Если нет — добавьте параметр.

## Если шрифты тянутся через PHP

```php
// В header.php
use Bitrix\Main\Page\Asset;
$asset = Asset::getInstance();

// Preconnect
$asset->addString('<link rel="preconnect" href="https://fonts.googleapis.com">', true);
$asset->addString('<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>', true);

// CSS со шрифтами
$asset->addCss('https://fonts.googleapis.com/css2?family=Open+Sans:wght@400;700&family=Noto+Serif:wght@400;700&display=swap', true);
```

## Self-hosted шрифты (оптимально)

Скачайте шрифты (Open Sans, Noto Serif), положите в `/bitrix/fonts/` и подключите:

```css
/* В CSS-файле */
@font-face {
    font-family: 'Open Sans';
    src: url('/bitrix/fonts/OpenSans-Regular.woff2') format('woff2');
    font-display: swap;
    font-weight: 400;
}
@font-face {
    font-family: 'Open Sans';
    src: url('/bitrix/fonts/OpenSans-Bold.woff2') format('woff2');
    font-display: swap;
    font-weight: 700;
}
/* Аналогично для Noto Serif */
```

Преимущества: нет DNS-запроса, нет TLS-handshake, полный контроль кэширования.
