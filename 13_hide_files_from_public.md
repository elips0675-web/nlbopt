# Закрытие файлов от просмотра (кроме поисковиков)

## 1. Отключить листинг директорий

**Apache (.htaccess):**
```apache
Options -Indexes
```

**Nginx:**
```nginx
autoindex off;
```

## 2. Закрыть служебные папки от всех (включая поисковики)

**Apache (.htaccess в корне):**
```apache
<IfModule mod_rewrite.c>
    RewriteRule ^bitrix/(setup|modules|admin|tools)($|/) - [F,L]
    RewriteRule ^bitrix/.settings\.php - [F,L]
    RewriteRule ^bitrix/php_interface/ - [F,L]
    RewriteRule ^upload/.*\.(php|phtml|pl|py|jsp|asp|aspx|cgi)$ - [F,L]
</IfModule>
```

**Nginx:**
```nginx
location ~ ^/bitrix/(setup|modules|admin|tools) {
    deny all;
}
location ~ ^/bitrix/\.settings\.php {
    deny all;
}
location ~ ^/upload/.*\.(php|phtml|pl|py|jsp|asp|aspx|cgi)$ {
    deny all;
}
```

## 3. `robots.txt` — что можно индексировать

```apache
User-agent: *
Disallow: /bitrix/
Disallow: /local/
Disallow: /upload/  # если там пользовательские файлы без цензуры
Disallow: /auth/
Disallow: /personal/
Disallow: /*?*
Allow: /$

Sitemap: https://site.ru/sitemap.xml
```

> Поисковики НЕ заходят в `/bitrix/`, `/local/`, `/upload/` и служебные скрипты.  
> При этом сайт индексируется — главная, каталог, новости, статьи — через ЧПУ.

## 4. Защита конфиденциальных файлов (PHP)

В `/bitrix/php_interface/init.php`:
```php
// Не показывать ошибки PHP пользователям
ini_set('display_errors', 0);
ini_set('display_startup_errors', 0);
```

## 5. Дополнительно: auth на админку по IP

```apache
<FilesMatch "admin">
    Require ip 192.168.0.0/24
    Require ip 10.0.0.0/8
</FilesMatch>
```

## Итог

| Что | Результат |
|-----|-----------|
| `Options -Indexes` | Нет листинга папок |
| RewriteRule `/bitrix/admin/` | 403 для людей и ботов |
| `robots.txt` Disallow `/bitrix/` | Поисковики не заходят в служебные |
| Allow главной + ЧПУ | Контент индексируется |
| Deny `.php` в `/upload/` | Не выполняют скрипты из загрузок |

> **Главное:** закрыть от всех (и людей, и ботов) — `/bitrix/`, `/local/`, `.settings.php`, `php_interface/`, `.php` в `upload/`.
> А сам контент (каталог, статьи) — открыт для индексации через ЧПУ без параметров.
