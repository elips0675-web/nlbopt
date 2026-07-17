# Brotli сжатие + HTTP/3 (QUIC)

## Brotli

Brotli эффективнее gzip на ~20% при том же уровне сжатия.

### Предсозданные .br файлы (рекомендуется)

Статику сжимать заранее — не тратить CPU на каждый запрос.

```bash
# Установка
sudo apt install brotli

# Конвертация всех JS/CSS/HTML
find /var/www/site -type f \( -name "*.js" -o -name "*.css" -o -name "*.html" \) \
  -exec brotli --quality 6 --input {} --output {}.br \;
```

### Nginx

```nginx
brotli on;
brotli_static on;          # отдаёт предсозданные .br файлы
brotli_comp_level 6;       # 0-11, 6 = баланс скорости и сжатия
brotli_types text/plain text/css application/json application/javascript text/xml application/xml text/javascript image/svg+xml;
```

### Apache

```apache
AddOutputFilterByType BROTLI text/html text/plain text/css application/javascript
```

### Проверка

```bash
curl -H "Accept-Encoding: br" -I https://site.ru | grep Content-Encoding
# Должно быть: Content-Encoding: br
```

## HTTP/3 (QUIC)

### Преимущества

- 0-RTT соединение (вместо 3 round-trip TCP + TLS)
- Не блокируется при потере пакетов (в отличие от TCP)
- До +30% на мобильных сетях

### Nginx

```nginx
server {
    listen 443 quic reuseport;
    listen 443 ssl;
    http2 on;

    add_header Alt-Svc 'h3=":443"; ma=86400';
}
```

### Cloudflare

Включить через dashboard: Speed → Optimization → HTTP/3.

### Проверка

```bash
curl --http3 -I https://site.ru
```

Или DevTools → Network → Protocol — `h3` вместо `h2`.
