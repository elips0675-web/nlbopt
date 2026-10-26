# 2. WebP/AVIF + сжатие изображений

**Актуально на 26.10.2026.** Изображения — 7 972 КБ из 8 364 КБ страницы (95%). Здесь же лежит самая большая отдельная проблема сайта.

## Что конвертировать в первую очередь

| Файл | Сейчас | Ожидаемо WebP q80 | Экономия |
|---|---|---|---|
| `/upload/iblock/b26/.../OON.png` (1920×1079) | **4 277 КБ** | ~200–250 КБ | ~4 МБ |
| `/upload/iblock/7c9/.../Af_105_let_BGU.png` (800×566) | 781 КБ | ~70–90 КБ | ~700 КБ |
| `/upload/iblock/f87/.../sl_Fieliks_Humien.jpg` (800×450) | 714 КБ | ~90–120 КБ | ~600 КБ |
| `/upload/iblock/132/.../Vernost_rodine.jpg` (800×450) | 290 КБ | ~50–70 КБ | ~220 КБ |
| `/upload/iblock/669/.../af_pesniar.jpg` (800×603) | 263 КБ | ~50–70 КБ | ~200 КБ |
| `hero-bg-side-2.jpg` (фон hero) | 194 КБ | ~40–60 КБ | ~140 КБ |

PNG для фотографий — главная ошибка. PNG нужен только для логотипов/иконок с прозрачностью и резкими краями.

## Вариант A: nginx (рекомендуется)

Сначала сконвертируйте файлы скриптом `08_convert_to_webp.sh` — он создаёт **суффиксные** копии `photo.jpg.webp` рядом с оригиналом.

Затем в nginx:

```nginx
# В http-блоке: определяем, принимает ли клиент WebP
map $http_accept $webp_suffix {
    default        "";
    "~*image/webp" ".webp";
}

server {
    # ...
    location ~* ^/(upload|local/templates)/.+\.(jpe?g|png)$ {
        add_header Vary "Accept, Accept-Encoding";
        try_files $uri$webp_suffix $uri =404;
        expires 365d;
        add_header Cache-Control "public, immutable";
        access_log off;
    }

    # Сами WebP-копии
    location ~* \.webp$ {
        expires 365d;
        add_header Cache-Control "public, immutable";
        access_log off;
    }
}
```

Почему не `try_files $uri.webp $uri`: такая запись отдаёт WebP **всем**, включая клиентов без поддержки WebP. Правильно — через `map` по `Accept`.

Проверка:

```bash
# с WebP
curl -sI -H "Accept: image/webp" https://nlb.by/upload/.../OON.png | grep -i content-type
# без WebP
curl -sI -H "Accept: image/*"     https://nlb.by/upload/.../OON.png | grep -i content-type
```

## Вариант B: Битрикс (`CFile::ResizeImageGet` с WebP)

В новых версиях главного модуля WebP включается в настройках:

**Настройки → Настройки продукта → Настройки модуля «Главный» → Обработка изображений** — включить конвертацию в WebP (если доступна в вашей сборке).

В шаблонах компонентов вместо прямого SRC:

```php
$img = CFile::ResizeImageGet(
    $arItem["PREVIEW_PICTURE"],
    ["width" => 800, "height" => 450],
    BX_RESIZE_IMAGE_EXACT,
    true,
    false,
    false,
    ["convert_to_webp" => true] // поддерживается в актуальных сборках
);
?>
<img src="<?= $img["src"] ?>"
     width="<?= $img["width"] ?>" height="<?= $img["height"] ?>"
     alt="<?= htmlspecialchars($arItem["NAME"]) ?>"
     loading="lazy" decoding="async">
```

Плюс: размеры попадают в `resize_cache` и отдаются уже нужной ширины — не нужно грузить 1920 px туда, где показывается 400.

**Важно:** не делайте `preg_replace` по HTML с подстановкой `$2.webp`, если таких файлов нет — получите 404 на всех картинках. Сначала конвертация, потом разметка.

## Вариант C: AVIF

AVIF даёт ещё −20…−30% к WebP, но кодируется медленно. Разумно для статики шаблона (hero, баннеры), а не для 30 тысяч картинок `/upload/`.

```nginx
map $http_accept $img_suffix {
    default          "";
    "~*image/avif"   ".avif";
    "~*image/webp"   ".webp";
}

location ~* ^/(upload|local/templates)/.+\.(jpe?g|png)$ {
    add_header Vary "Accept, Accept-Encoding";
    try_files $uri$img_suffix $uri =404;
}
```

Порядок в `map` важен: AVIF проверяется первым.

## Ресайз «под показ»

Многие файлы отдаются 800 px, а показываются в 350–400 px. В Битриксе это решается размерами в настройках инфоблока / вызовом `CFile::ResizeImageGet` с реальной шириной слота. Для баннеров 1200 px по ширине — предел, дальше смысла нет.

## Сжатие при загрузке

Автоматически пережимать новые загрузки:

```php
// /local/php_interface/init.php
AddEventHandler("main", "OnAfterFileSave", function ($arFile) {
    if (!in_array($arFile["CONTENT_TYPE"], ["image/jpeg", "image/png"], true)) {
        return;
    }
    $path = $_SERVER["DOCUMENT_ROOT"] . "/" . $arFile["SUBDIR"] . "/" . $arFile["FILE_NAME"];
    if (!is_file($path)) {
        return;
    }
    [$w] = getimagesize($path) ?: [0];
    if ($w > 1600) {
        CFile::ResizeImageFile(
            $path, $path,
            ["width" => 1600, "height" => 99999],
            BX_RESIZE_IMAGE_PROPORTIONAL,
            ["quality" => 82]
        );
    }
});
```

Осторожно: хук срабатывает и на админку, и на импорт. Лучше тестировать на копии.

## Проверка результата

```bash
# вес главной до/после
curl -s -o /dev/null -w "%{size_download}\n" https://nlb.by/

# есть ли WebP-копии
curl -sI https://nlb.by/upload/iblock/b26/.../OON.png.webp | head -1
```

Цель: главная ≤ 1,5 МБ transfer, ни одна картинка не тяжелее 250 КБ.
