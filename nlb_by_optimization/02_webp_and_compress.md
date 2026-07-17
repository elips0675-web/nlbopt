# 2. WebP + сжатие изображений

## Вариант A: Через PHP Битрикса (CFile::ResizeImageGet)

В `init.php` добавьте:

```php
// Включение WebP в Битриксе (работает с модулем "Главный" версии 22+)
use Bitrix\Main;
use Bitrix\Main\IO;

// Автоматическая конвертация при ресайзе
AddEventHandler("main", "OnAfterResizeImage", function($arFile, &$arResult) {
    if (Main\Config\Option::get("main", "convert_to_webp", "N") === "N") {
        Main\Config\Option::set("main", "convert_to_webp", "Y");
    }
    return true;
});

// Перехват вывода изображений — конвертация в WebP через тег <picture>
AddEventHandler("main", "OnEndBufferContent", function(&$content) {
    if (defined("ADMIN_SECTION") || defined("BX_AJAX")) return;
    
    // Замена .jpg/.png на .webp в тегах <img> (с добавлением <picture>)
    $content = preg_replace(
        '/<img([^>]*)src="([^"]+\.(jpg|jpeg|png))"([^>]*)>/i',
        '<picture><source srcset="$2.webp" type="image/webp"><img$1src="$2"$4></picture>',
        $content
    );
});
```

**Но это костыль.** Лучше обрабатывать через nginx.

## Вариант B: Nginx — try_files для WebP

```nginx
# В server block
location ~* ^/(upload|bitrix)/.+\.(jpg|jpeg|png)$ {
    add_header Vary "Accept-Encoding, Accept";
    try_files $uri.webp $uri =404;
    
    # Кэширование на год
    expires 365d;
    add_header Cache-Control "public, immutable";
}

location ~* ^/(upload|bitrix)/.+\.webp$ {
    expires 365d;
    add_header Cache-Control "public, immutable";
}
```

Создайте WebP-версии всех изображений (см. скрипт `convert_to_webp.sh`).

## Вариант C: CDN с автоматической конвертацией

Если используете Cloudflare — включите Polish (Lossy) в разделе Speed → Optimization.

## Сжатие баннеров

Для слайдера и больших изображений в `init.php`:

```php
// Автоматический ресайс загружаемых изображений до 1200px
AddEventHandler("main", "OnAfterFileSave", function($arFile) {
    if (!in_array($arFile["CONTENT_TYPE"], ["image/jpeg", "image/png"])) return;
    
    $filePath = $_SERVER["DOCUMENT_ROOT"] . "/" . $arFile["SUBDIR"] . "/" . $arFile["FILE_NAME"];
    
    // Если ширина больше 1200px — ресайзим
    list($width, $height) = getimagesize($filePath);
    if ($width > 1200) {
        CFile::ResizeImageFile(
            $filePath,
            $filePath,
            ["width" => 1200, "height" => 99999],
            BX_RESIZE_IMAGE_PROPORTIONAL,
            ["quality" => 80]
        );
    }
});
```
