# CDN для статики + AVIF изображения

## CDN для статики

### Что выносить на CDN

| Тип | Путь | CDN |
|-----|------|-----|
| JS | `/bitrix/js/` | + |
| CSS | `/bitrix/templates/` | + |
| Изображения | `/upload/` | + |
| Шрифты | `/bitrix/fonts/` | + |
| Динамика | — | оставить на сервере |

### Варианты CDN

| Провайдер | Бесплатно | Особенность |
|-----------|-----------|-------------|
| Cloudflare | Да | + WAF, DDoS, HTTP/3 |
| Qrator | Нет | + защита от DDoS |
| Selectel CDN | Нет | Популярен в РФ |
| StackPath | Нет | Глобальная сеть |

### Настройка в Битрикс

Админка → Настройки → Главный модуль → Хранение файлов:

```
CDN-сервер: https://cdn.site.ru
```

Или через `init.php`:

```php
define("BX_CDN_DOMAIN", "cdn.site.ru");
```

### Nginx reverse proxy для статики через CDN

```nginx
location ~* \.(js|css|png|jpg|jpeg|gif|ico|webp|woff2?)$ {
    proxy_pass https://cdn.site.ru;
    proxy_set_header Host cdn.site.ru;
}
```

## AVIF изображения

AVIF сжимает на ~30% лучше WebP при том же качестве.

### Поддержка браузерами

| Браузер | Версия |
|---------|--------|
| Chrome | 85+ |
| Edge | 121+ |
| Firefox | 93+ |
| Safari | 17+ |
| Opera | 71+ |

### Конвертация

```bash
# Через avifenc (libavif)
avifenc --quality 50 --speed 6 input.jpg output.avif

# Через ImageMagick 7+
magick input.jpg -quality 50 output.avif

# Пакетная
for img in *.jpg; do
    avifenc --quality 50 --speed 6 "$img" "${img%.*}.avif"
done
```

### Вывод через `<picture>` с fallback

```html
<picture>
    <source srcset="/upload/image.avif" type="image/avif">
    <source srcset="/upload/image.webp" type="image/webp">
    <img src="/upload/image.jpg" alt="..." loading="lazy">
</picture>
```

### Nginx try_files (аналог WebP)

```nginx
location ~* ^/upload/.+\.(jpg|jpeg|png)$ {
    try_files $uri.avif $uri.webp $uri =404;
    expires 365d;
}
```

### Проверка

DevTools → Network → тип ответа `image/avif`.
