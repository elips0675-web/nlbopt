# 9. Безопасность: HTTP-заголовки + SSL/TLS

**Актуально на 26.10.2026.**

## Что уже есть

| Заголовок / механизм | Статус |
|---|---|
| `X-Frame-Options: SAMEORIGIN` | ✅ |
| `X-Content-Type-Options: nosniff` | ✅ |
| Cookie `Secure; HttpOnly` | ✅ |
| `/bitrix/`, `/upload/`, `.git` | ✅ 403 |
| `/adminer.php` | ✅ 404 |
| TLS 1.2 + **TLS 1.3** | ✅ |
| HTTP/2 | ✅ |
| **HSTS** | ❌ нет |
| **CSP** | ❌ нет |
| **Referrer-Policy** | ❌ нет |
| **Permissions-Policy** | ❌ нет |
| **COOP** | ❌ нет |
| Cookie `SameSite` | ❌ нет |
| `X-Powered-CMS: Bitrix Site Manager (hash)` | ⚠️ раскрывает CMS и сборку |

Проверка одной командой:

```bash
curl -sI https://nlb/ | grep -iE 'strict-transport|content-security|referrer|permissions|cross-origin|x-powered|x-frame|x-content'
```

## 1. HSTS — начинать с малого

Не включайте сразу `max-age=63072000; preload`: если какой-то поддомен живёт по HTTP, вы отрежете к нему доступ на два года.

Порядок:

```nginx
# Этап 1 — 5 минут, проверяем, что всё работает
add_header Strict-Transport-Security "max-age=300" always;

# Этап 2 — через неделю
add_header Strict-Transport-Security "max-age=15552000" always;

# Этап 3 — через месяц, когда все поддомены на HTTPS
add_header Strict-Transport-Security "max-age=63072000; includeSubDomains" always;

# Этап 4 — только после проверки всех поддоменов
add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload" always;
```

`preload` — это заявка в браузерные списки, откат занимает месяцы. Не спешите.

## 2. Referrer-Policy и Permissions-Policy

Безопасно включать сразу:

```nginx
add_header Referrer-Policy "strict-origin-when-cross-origin" always;
add_header Permissions-Policy "camera=(), geolocation=(), payment=(), usb=(), interest-cohort=()" always;
```

`microphone` не запрещайте жёстко, если в Jivo включены голосовые сообщения. Тогда:

```nginx
add_header Permissions-Policy "camera=(), geolocation=(), payment=(), usb=(), microphone=(self \"https://code-eu1.jivosite.com\")" always;
```

## 3. CSP — только Report-Only на старте

На сайте 22 inline-скрипта, Битрикс и Jivo. Жёсткая CSP сразу всё сломает.

```nginx
add_header Content-Security-Policy-Report-Only "
    default-src 'self';
    script-src 'self' 'unsafe-inline' 'unsafe-eval'
               https://code-eu1.jivosite.com https://code.jivosite.com;
    style-src 'self' 'unsafe-inline';
    font-src 'self';
    img-src 'self' data: blob: https://code.jivosite.com;
    connect-src 'self' https://code.jivosite.com https://code-eu1.jivosite.com
                wss://node-sb1-az2-23.jivosite.com;
    frame-src 'self' https://code.jivosite.com;
    object-src 'none';
    base-uri 'self';
    form-action 'self';
    report-uri /local/csp-report.php;
" always;
```

Соберите отчёты за 1–2 недели, уберите лишние домены, затем переключите на `Content-Security-Policy` (без `-Report-Only`). Цель — убрать `'unsafe-inline'`/`'unsafe-eval'` хотя бы для скриптов (Битрикс умеет nonce не всегда, но inline-код шаблона можно вынести в `site.js`).

## 4. Убрать утечку CMS

```nginx
fastcgi_hide_header X-Powered-CMS;
fastcgi_hide_header X-Powered-By;
```

Проверка: `curl -sI https://nlb/ | grep -i powered` → пусто.

Заодно уберите `Vary: HTTPS` (нестандартный, никому не нужен) — он приходит из PHP; ищите в `init.php`/`.htaccess` `header("Vary: HTTPS")`.

## 5. Cookie SameSite

В `php.ini`:

```ini
session.cookie_samesite = "Lax"
session.cookie_secure = "On"
session.cookie_httponly = "On"
```

Или в `init.php` **до** старта сессии:

```php
ini_set('session.cookie_samesite', 'Lax');
```

`Lax` — безопасный дефолт: формы и переходы работают, CSRF-риск ниже. `Strict` может ломать возврат с внешних платёжных страниц — проверьте сценарий покупки билетов.

## 6. SSL/TLS

TLS 1.3 уже работает, трогать не обязательно. Если хотите A+ на SSL Labs:

```nginx
ssl_protocols TLSv1.2 TLSv1.3;
ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305;
ssl_prefer_server_ciphers off;
ssl_session_cache shared:SSL:10m;
ssl_session_timeout 1d;
ssl_session_tickets off;
```

OCSP stapling:

```nginx
ssl_stapling on;
ssl_stapling_verify on;
resolver 1.1.1.1 8.8.8.8 valid=300s;
```

## 7. Rate limiting для админки

```nginx
limit_req_zone $binary_remote_addr zone=login:10m rate=5r/s;
limit_req_zone $binary_remote_addr zone=bitrix:10m rate=20r/s;

location /bitrix/admin/ {
    limit_req zone=login burst=10 nodelay;
}

location /bitrix/ {
    limit_req zone=bitrix burst=40 nodelay;
}
```

`/bitrix/admin/` уже отдаёт 403 — это хорошо, но rate limit всё равно полезен.

## Проверка

- https://securityheaders.com/?q=nlb — цель A/A+
- https://www.ssllabs.com/ssltest/analyze.html?d=nlb — цель A+
- https://observatory.mozilla.org/analyze/nlb
- `curl -sI https://nlb/ | grep -i strict-transport`

## Порядок внедрения

1. `Referrer-Policy` + `Permissions-Policy` + `fastcgi_hide_header X-Powered-CMS` — 10 минут, ничего не ломают.
2. HSTS `max-age=300` → постепенно увеличивать.
3. CSP в Report-Only, сбор отчётов.
4. `SameSite=Lax` для cookie.
5. Только потом — CSP в боевом режиме.
