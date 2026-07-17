# 1. Добавление loading="lazy" для изображений

## Где править

В типовом Битриксе изображения выводятся через компоненты:
- `bitrix:news.list` — афиша, новости
- `bitrix:main.register` / `bitrix:system.auth.form`
- Кастомные компоненты слайдера

Нужно добавить атрибут `loading="lazy"` всем `<img>`, которые находятся ниже первого экрана (примерно первые 2-3 изображения можно не трогать).

## Быстрый способ — через result_modifier

Создайте файл `result_modifier.php` в нужном компоненте или добавьте в `init.php`:

```php
// В init.php или в result_modifier.php компонента
// Добавляет loading="lazy" для всех изображений, кроме первого
AddEventHandler("main", "OnEndBufferContent", function(&$content) {
    // Не трогаем админку и ajax
    if (defined("ADMIN_SECTION") || defined("BX_AJAX")) return;

    // Заменяем все <img> без loading на loading="lazy", 
    // но пропускаем первые 3 изображения (они выше сгиба)
    $count = 0;
    $content = preg_replace_callback(
        '/<img\s[^>]*?(?<!"loading")[^>]*>/i',
        function($match) use (&$count) {
            $count++;
            // Первые 3 изображения не трогаем (выше сгиба)
            if ($count <= 3) return $match[0];
            // Если уже есть loading — пропускаем
            if (stripos($match[0], 'loading=') !== false) return $match[0];
            // Вставляем loading="lazy" после тега <img
            return str_replace('<img', '<img loading="lazy"', $match[0]);
        },
        $content
    );
});
```

## Добавление в конкретные шаблоны компонентов

Если хотите точечно — добавьте `loading="lazy"` прямо в `.php` шаблонах:

```php
// В шаблоне news.list, slider и т.д.
<img loading="lazy" src="<?= $arItem["PREVIEW_PICTURE"]["SRC"] ?>" 
     alt="<?= $arItem["NAME"] ?>" width="<?= $arItem["PREVIEW_PICTURE"]["WIDTH"] ?>" height="<?= $arItem["PREVIEW_PICTURE"]["HEIGHT"] ?>">
```

**Важно:** Всегда указывайте `width` и `height` для изображений — это устраняет CLS (Layout Shift).

## Для фоновых изображений в CSS

Если изображения заданы через CSS background — замените на `<img loading="lazy">` или используйте `<link rel="preload" as="image">` для первого экрана.

## Проверка

```bash
grep -r "loading=" /path/to/site/bitrix/templates/ | grep -v ".bak"
```
