# 9. Безопасность: HTTP-заголовки + SSL/TLS

## HTTP-заголовки безопасности (Nginx)

Добавьте в `server` блок:

```nginx
add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload" always;
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-XSS-Protection "0" always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;
add_header Permissions-Policy "camera=(), microphone=(), geolocation=()" always;

# CSP — базовый, подстройте под свои нужды
add_header Content-Security-Policy "
    default-src 'self';
    script-src 'self' 'unsafe-inline' 'unsafe-eval' https://www.googletagmanager.com https://www.google-analytics.com https://code.jivosite.com https://mc.yandex.ru;
    style-src 'self' 'unsafe-inline' https://fonts.googleapis.com;
    font-src 'self' https://fonts.gstatic.com;
    img-src 'self' data: https://www.google-analytics.com https://mc.yandex.ru;
    connect-src 'self' https://mc.yandex.ru;
    frame-src 'self' https://www.googletagmanager.com;
" always;
```

**Важно:** CSP нужно настраивать осторожно — сначала в режиме report-only (`Content-Security-Policy-Report-Only`) и смотреть логи, иначе что-то может сломаться.

## Если Apache (через .htaccess)

```apache
<IfModule mod_headers.c>
    Header always set Strict-Transport-Security "max-age=63072000; includeSubDomains; preload"
    Header always set X-Frame-Options "SAMEORIGIN"
    Header always set X-Content-Type-Options "nosniff"
    Header set Referrer-Policy "strict-origin-when-cross-origin"
</IfModule>
```

## SSL/TLS (Nginx)

```nginx
ssl_protocols TLSv1.2 TLSv1.3;
ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
ssl_prefer_server_ciphers off;
ssl_session_cache shared:SSL:10m;
ssl_session_timeout 10m;
ssl_session_tickets off;
```

## Rate limiting (DDoS-защита)

```nginx
# В http block
limit_req_zone $binary_remote_addr zone=login:10m rate=5r/s;

# В server block для админки
location /bitrix/admin/ {
    limit_req zone=login burst=10 nodelay;
}
```

## Проверка

- https://securityheaders.com/?q=nlb.by&followRedirects=on
- https://www.ssllabs.com/ssltest/analyze.html?d=nlb.by
