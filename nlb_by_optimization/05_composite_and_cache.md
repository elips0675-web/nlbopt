# 5. Композитный сайт + Cache-Control для статики

## Композитный сайт (HTML-кэш)

### Включение через админку

**Настройки → Настройки продукта → Композитный сайт → Включить**

Параметры:
- **Режим кэширования:** Стандартный
- **Время кэширования:** 3600 с (1 час, для новостного сайта)
- **Исключить страницы:** `/bitrix/`, `/personal/` (если есть личный кабинет)
- **Использовать компрессию:** Да

### Если кнопка недоступна — через `init.php`

```php
// Принудительное включение композита
use Bitrix\Main\Config\Option;
Option::set("main", "enable_composite", "Y");
Option::set("main", "composite_mode", 1); // 1 — авто, 2 — ручной
```

Очистите кэш после включения.

## Cache-Control для статики через Nginx

```nginx
# В секции server или http

# Изображения и медиа — год
location ~* \.(jpg|jpeg|png|gif|ico|webp|svg|woff2?|ttf|eot)$ {
    expires 365d;
    add_header Cache-Control "public, immutable";
    access_log off;
}

# CSS и JS — год, с fingerprint'ом
location ~* \.(css|js)$ {
    expires 365d;
    add_header Cache-Control "public, immutable";
    access_log off;
}

# upload — год
location ^~ /upload/ {
    expires 365d;
    add_header Cache-Control "public, immutable";
    access_log off;
}

# bitrix/cache — год
location ^~ /bitrix/cache/ {
    expires 365d;
    add_header Cache-Control "public, immutable";
    access_log off;
}
```

## Если Apache (.htaccess)

```apache
# В корневом .htaccess
<IfModule mod_expires.c>
    ExpiresActive On
    ExpiresDefault "access plus 1 year"
    ExpiresByType image/jpeg "access plus 1 year"
    ExpiresByType image/png "access plus 1 year"
    ExpiresByType image/webp "access plus 1 year"
    ExpiresByType image/svg+xml "access plus 1 year"
    ExpiresByType text/css "access plus 1 year"
    ExpiresByType text/javascript "access plus 1 year"
    ExpiresByType application/javascript "access plus 1 year"
    ExpiresByType font/woff2 "access plus 1 year"
</IfModule>

<IfModule mod_headers.c>
    <FilesMatch "\.(jpg|jpeg|png|gif|ico|webp|svg|css|js|woff2?)$">
        Header set Cache-Control "public, immutable"
    </FilesMatch>
</IfModule>
```
