#!/bin/bash
# Массовая конвертация JPG/PNG → WebP
# Запускать на сервере: bash 08_convert_to_webp.sh
#
# ВАЖНО: создаёт суффиксные копии "photo.jpg.webp" рядом с оригиналом —
# именно такой путь ожидает nginx-конфиг из 02_webp_and_compress.md
# (try_files $uri$webp_suffix $uri).
#
# Перед запуском сделайте бэкап /upload/:
#   tar -czf upload-backup-$(date +%F).tar.gz /path/to/www/upload

set -u

UPLOAD_DIR="${1:-/path/to/www/upload}"
QUALITY="${QUALITY:-82}"
MIN_SIZE_KB="${MIN_SIZE_KB:-20}"   # мелочь меньше 20 КБ не трогаем
JOBS="${JOBS:-2}"

if ! command -v cwebp >/dev/null 2>&1; then
    echo "cwebp не найден. Установите: sudo apt install webp"
    exit 1
fi

if [ ! -d "$UPLOAD_DIR" ]; then
    echo "Нет такой папки: $UPLOAD_DIR"
    exit 1
fi

convert_one() {
    file="$1"
    webp="${file}.webp"

    # Уже сконвертировано и свежее оригинала — пропускаем
    if [ -f "$webp" ] && [ "$webp" -nt "$file" ]; then
        return
    fi

    size_kb=$(du -k "$file" | cut -f1)
    if [ "$size_kb" -lt "$MIN_SIZE_KB" ]; then
        return
    fi

    if cwebp -quiet -q "$QUALITY" -m 6 -mt "$file" -o "$webp" 2>/dev/null; then
        old=$(du -k "$file" | cut -f1)
        new=$(du -k "$webp" | cut -f1)
        # Если WebP оказался больше оригинала — удаляем, оставляем оригинал
        if [ "$new" -ge "$old" ]; then
            rm -f "$webp"
            echo "skip (webp больше): $file"
        else
            echo "ok ${old}K -> ${new}K: $file"
        fi
    else
        echo "FAIL: $file"
    fi
}
export -f convert_one
export QUALITY MIN_SIZE_KB

echo "Конвертация JPG/PNG → WebP (q=$QUALITY) в $UPLOAD_DIR"
find "$UPLOAD_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) -print0 \
  | xargs -0 -P "$JOBS" -I{} bash -c 'convert_one "$@"' _ {}

echo
echo "Готово."
echo "JPG/PNG: $(find "$UPLOAD_DIR" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \) | wc -l)"
echo "WebP:    $(find "$UPLOAD_DIR" -type f -iname '*.webp' | wc -l)"
echo "Вес до/после:"
du -sh "$UPLOAD_DIR"
