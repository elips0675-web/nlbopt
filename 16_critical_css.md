# Critical CSS — критические стили для первого экрана

## Проблема

Битрикс грузит все стили ядра + шаблона сразу в `<head>`. Пока они не загрузятся — страница не рендерится. Это **render-blocking** ресурс.

## Решение

1. Выделить стили, которые нужны для первого экрана (шапка, меню, первый блок)
2. Встроить их inline в `<head>` через `header.php`
3. Остальные стили загружать асинхронно

### Инструменты для генерации Critical CSS

| Инструмент | Команда |
|------------|---------|
| Critical (npm) | `npx critical https://site.ru --base . --inline` |
| Penthouse | `npx penthouse https://site.ru critical.css` |
| Addy Osmani critical | `npm -g critical` |

### Асинхронная загрузка остальных стилей

```html
<link rel="stylesheet" href="/bitrix/templates/.default/template_styles.css"
      media="print" onload="this.media='all'">
<noscript>
    <link rel="stylesheet" href="/bitrix/templates/.default/template_styles.css">
</noscript>
```

Or через `loadCSS`:
```html
<script>
    loadCSS("/bitrix/templates/.default/template_styles.css");
</script>
```

### Через init.php (для шаблонов Битрикс)

```php
AddEventHandler("main", "OnEndBufferContent", function(&$content) {
    // Подмена ссылок на CSS — async load
    $content = preg_replace(
        '/<link[^>]*href="([^"]*template_styles[^"]*)"[^>]*>/',
        '<link rel="stylesheet" href="$1" media="print" onload="this.media=\'all\'"><noscript><link rel="stylesheet" href="$1"></noscript>',
        $content
    );
});
```

## Проверка

- Lighthouse → "Eliminate render-blocking resources" — 0
- DevTools → Coverage → unused CSS < 20%
