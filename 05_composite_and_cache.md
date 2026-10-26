# 5. Композитный сайт + Cache-Control

**Актуально на 26.10.2026.**

## Что сейчас

| Что | Значение | Оценка |
|---|---|---|
| TTFB главной | 471 мс | средне, есть куда расти |
| HTML `Cache-Control` | `no-store, no-cache, must-revalidate` | страница не кэшируется вообще |
| HTML `Expires` | `Thu, 19 Nov 1981 08:52:00 GMT` | следствие старта сессии |
| Статика (`/upload/`, `/local/`, `/bitrix/cache/`) | `max-age=2592000` (30 дней) | лучше, чем было, но не год |
| `immutable` | нет | при обновлении файла браузер делает лишний запрос |
| `Vary: Accept-Encoding` | нет на сжатых ответах | риск для промежуточных кэшей |
| Композит | не включён | каждая страница собирается заново |

30 дней — уже неплохо, но у всех статических файлов есть версионный суффикс (`?v=20261026j`, `?1793004833`), поэтому можно ставить год и `immutable`.

## 1. Композит (HTML-кэш)

**Настройки → Настройки продукта → Композитный сайт → Включить**

Параметры для новостного сайта:

- режим: стандартный (автокомпозит);
- время кэширования: 3600 с;
- исключить: `/bitrix/`, `/user/`, `/personal/`, `/search/`, формы;
- сжатие: включить.

После включения проверьте, что HTML перестал отдаваться с `no-store`:

```bash
curl -sI https://nlb.by/ | grep -iE 'cache-control|x-bitrix'
```

Ожидаемо: `X-Bitrix-Composite: Cache` и `Cache-Control` без `no-store`.

Если кнопка недоступна — через `init.php`:

```php
use Bitrix\Main\Config\Option;
Option::set("main", "enable_composite", "Y");
Option::set("main", "composite_mode", 1); // 1 — авто, 2 — ручной
```

**Важно:** композит и персональные данные. Если на странице выводится имя пользователя или корзина — её нужно вынести в динамическую зону (`$APPLICATION->SetPageProperty` / ajax), иначе пользователи увидят чужой закэшированный контент.

## 2. Годовой кэш статики (nginx)

```nginx
# В http-блоке
map $sent_http_content_type $static_immutable {
    default "";
    ~*image/            "public, max-age=31536000, immutable";
    ~*font/             "public, max-age=31536000, immutable";
    ~*text/css          "public, max-age=31536000, immutable";
    ~*javascript        "public, max-age=31536000, immutable";
}

server {
    # Сжатие должно сопровождаться Vary
    gzip_vary on;

    location ~* ^/(upload|local|bitrix/cache)/.+\.(jpe?g|png|gif|webp|avif|svg|ico|woff2?|ttf|css|js)$ {
        add_header Cache-Control $static_immutable always;
        add_header Vary "Accept, Accept-Encoding" always;
        access_log off;
        expires 365d;
    }

    # HTML — не кэшировать надолго (или отдать композиту)
    location ~* \.(html|php)$ {
        add_header Cache-Control "public, max-age=0, must-revalidate" always;
    }
}
```

Почему `immutable`: браузер не будет даже условно перепроверять файл (`If-None-Match`) — а версия в URL уже меняется при деплое.

Проверка:

```bash
curl -sI https://nlb.by/local/templates/index_2026/assets/css/main.css | grep -iE 'cache-control|vary'
# ожидаем: public, max-age=31536000, immutable  +  Vary: Accept, Accept-Encoding
```

## 3. Если Apache

```apache
<IfModule mod_expires.c>
    ExpiresActive On
    ExpiresByType image/jpeg "access plus 1 year"
    ExpiresByType image/png  "access plus 1 year"
    ExpiresByType image/webp "access plus 1 year"
    ExpiresByType image/avif "access plus 1 year"
    ExpiresByType image/svg+xml "access plus 1 year"
    ExpiresByType text/css "access plus 1 year"
    ExpiresByType application/javascript "access plus 1 year"
    ExpiresByType font/woff2 "access plus 1 year"
</IfModule>

<IfModule mod_headers.c>
    <FilesMatch "\.(jpg|jpeg|png|gif|ico|webp|avif|svg|css|js|woff2)$">
        Header set Cache-Control "public, max-age=31536000, immutable"
        Header append Vary "Accept-Encoding"
    </FilesMatch>
</IfModule>
```

## 4. Отдельно про шрифты

Сейчас WOFF2 отдаются с `Cache-Control: max-age=2592000` и неверным `Content-Type: application/force-download`. Кэш — в этой инструкции, MIME — в `06_fonts_display_swap.md`.

## Ожидаемый эффект

- повторные визиты: статика не запрашивается вообще (сейчас — условные запросы каждые 30 дней);
- TTFB с композитом: 100–200 мс вместо 471 мс;
- «назад» в браузере перестанет перезагружать страницу (сейчас `no-store` это ломает).
