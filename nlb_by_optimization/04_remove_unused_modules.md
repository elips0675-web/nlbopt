# 4. Отключить лишние модули (pull, protobuf, dexie, rest.client)

## Проблема

На публичных страницах грузятся:
- `pull.client` и `pull.js` — для Push & Pull (чат, уведомления)
- `protobuf.js` (71 КБ) — зависимость pull
- `dexie.js` — IndexedDB для pull
- `rest.client` — для REST API

Если на сайте нет онлайн-чата/уведомлений — это лишний ~400 КБ JS.

## Способ 1: Через шаблон сайта (рекомендуется)

В файле `bitrix/templates/ваш_шаблон/header.php` или лучше в `result_modifier.php`:

```php
// В init.php
AddEventHandler("main", "OnEndBufferContent", function(&$content) {
    if (defined("ADMIN_SECTION") || defined("BX_AJAX")) return;
    
    // Удаляем ненужные скрипты по URL
    $removePatterns = [
        '/pull\.client\.js/i',
        '/protobuf\.js/i',
        '/dexie\.js/i',
        '/rest\.client\.js/i',
        '/pull\.js/i',
    ];
    
    foreach ($removePatterns as $pattern) {
        // Удаляем <script src="..."></script>
        $content = preg_replace(
            '/<script[^>]*src="[^"]*(' . str_replace('/', '\/', $pattern) . ')[^"]*"[^>]*><\/script>\s*\n?/i',
            '',
            $content
        );
    }
});
```

## Способ 2: Отключить модуль Pull в админке

**Настройки → Настройки продукта → Модули → Push & Pull** → нажать «Удалить» (деактивация).

Если модуль используется — оставьте, отключите только подключение на публичных страницах.

## Способ 3: Через result_modifier компонента

Если скрипты тянутся через `epilog.php` — создайте `/bitrix/templates/ваш_шаблон/epilog.php`:

```php
<?php
// Отключаем pull на публичных страницах
if (CModule::IncludeModule('pull')) {
    $GLOBALS['APPLICATION']->SetAdditionalCSS('/bitrix/js/pull/pull.css', true, true); // оставляем CSS
    // JS отключаем — не добавляем pull скрипты
}
?>
```

## Проверка

Откройте вкладку Network в DevTools и убедитесь, что файлы `pull.*`, `protobuf*`, `dexie*`, `rest.client*` больше не загружаются.
