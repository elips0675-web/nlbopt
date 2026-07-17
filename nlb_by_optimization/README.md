# Оптимизация nlb.by — план работ

Порядок выполнения (по приоритету):

## Быстрый эффект (сделать за 1 день, даст +20-30 баллов)

1. **`03_minification.md`** — включить минификацию JS/CSS (5 мин в админке)
2. **`01_lazy_load_images.md`** — добавить loading="lazy" (копировать код в init.php)
3. **`04_remove_unused_modules.md`** — отключить pull/protobuf/dexie/rest.client (копировать код в init.php)
4. **`08_convert_to_webp.sh`** — запустить конвертацию изображений (залить и запустить скрипт)
5. **`02_webp_and_compress.md`** — настроить Nginx для WebP + сжатие

## Средний приоритет (ещё +10-15 баллов)

6. **`05_composite_and_cache.md`** — включить композит и Cache-Control
7. **`06_fonts_display_swap.md`** — display=swap + preconnect для шрифтов

## Дополнительно

8. **`07_defer_widgets.md`** — отложить загрузку Jivosite и megavenue.by

---

Для каждого пункта: прочитайте файл, скопируйте код на сервер, примените.
