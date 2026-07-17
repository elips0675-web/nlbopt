# 3. Включить минификацию JS/CSS в админке Битрикса

## Путь в админке

**Настройки → Настройки продукта → Настройки модуля «Главный» → Оптимизация CSS/JS**

Включите:
- ✅ **Минифицировать JS-файлы** (все 3 опции)
- ✅ **Минифицировать CSS-файлы**
- ✅ **Объединять JS-файлы в один**
- ✅ **Объединять CSS-файлы в один**
- ✅ **Переносить JS в конец страницы**
- ✅ **Использовать компрессию** (gzip)

## Если пункт меню недоступен

Добавьте в `bitrix/php_interface/init.php`:

```php
// Принудительное включение минификации
define("BX_HTML5", true);
define("BX_MINIFY_SCRIPT", true);
define("BX_MINIFY_STYLE", true);
define("BX_ASSET_CACHE", true);

// Или через API
use Bitrix\Main\Config\Option;
Option::set("main", "optimize_js_files", "Y");
Option::set("main", "optimize_css_files", "Y");
Option::set("main", "use_minify_assets", "Y");
Option::set("main", "move_js_to_bottom", "Y");
```

## Проверка

После включения очистите кэш: **Настройки → Инструменты → Очистить кэш** (или удалите вручную `/bitrix/cache/`).

Откройте исходный код страницы — должны быть `<script>` в конце `<body>`, а не в `<head>`.
