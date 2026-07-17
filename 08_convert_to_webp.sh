#!/bin/bash
# Массовая конвертация JPG/PNG → WebP
# Запускать на сервере: bash convert_to_webp.sh

# Путь к папке upload (укажите свой)
UPLOAD_DIR="/path/to/www/upload"

# Проверка наличия cwebp
if ! command -v cwebp &> /dev/null; then
    echo "cwebp не найден. Установите: sudo apt install webp"
    exit 1
fi

echo "Конвертация JPG → WebP..."
find "$UPLOAD_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" \) | while read file; do
    webp="${file%.*}.webp"
    if [ ! -f "$webp" ]; then
        echo "Конвертирую: $file"
        cwebp -q 80 "$file" -o "$webp" 2>/dev/null
    fi
done

echo "Конвертация PNG → WebP..."
find "$UPLOAD_DIR" -type f -iname "*.png" | while read file; do
    webp="${file%.*}.webp"
    if [ ! -f "$webp" ]; then
        echo "Конвертирую: $file"
        cwebp -q 80 -alpha_q 80 "$file" -o "$webp" 2>/dev/null
    fi
done

echo "Готово!"
echo ""
echo "Статистика:"
echo "JPG/PNG файлов: $(find "$UPLOAD_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) | wc -l)"
echo "WebP файлов:    $(find "$UPLOAD_DIR" -type f -iname "*.webp" | wc -l)"
