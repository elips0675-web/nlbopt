# 20. Brotli + HTTP/3 (QUIC)

**Актуально на 26.10.2026.**

## Что реально включено на nlb

| Технология | Статус | Как проверено |
|---|---|---|
| HTTP/2 | ✅ работает | `ALPN: h2` |
| TLS 1.3 | ✅ работает | `TLSv1.3`, `TLS_AES_256_GCM_SHA384` |
| Gzip | ✅ работает | `Content-Encoding: gzip` на HTML/CSS/JS |
| **Brotli** | ❌ **нет** | запрос с `Accept-Encoding: br` вернул `Content-Length: 95016` без `Content-Encoding` |
| **HTTP/3** | ❌ **нет** | в ответах нет `Alt-Svc: h3=...` |

То есть из этой инструкции остались два пункта: Brotli и HTTP/3. HTTP/2 и TLS 1.3 уже настроены — ничего делать не нужно.

## Brotli

На CSS+JS+HTML сейчас ~320 КБ transfer. Brotli даёт ещё −15…−25%, то есть **40–60 КБ** на первую загрузку. Для текстовых ресурсов это самый дешёвый выигрыш после картинок.

### Вариант A: статические `.br` (рекомендуется)

Не тратит CPU на каждый запрос.

```bash
sudo apt install brotli

# Только текстовые файлы, q6 — разумный баланс
find /var/www/nlb -type f \( -name "*.js" -o -name "*.css" -o -name "*.html" -o -name "*.svg" -o -name "*.json" \) \
  -size +1k \
  -exec brotli --quality 6 --input {} --output {}.br \;
```

Nginx (нужен модуль `ngx_brotli`):

```nginx
brotli on;
brotli_static on;
brotli_comp_level 6;
brotli_types text/plain text/css application/json application/javascript
             text/xml application/xml text/javascript image/svg+xml;
```

Если модуля нет:

- собрать nginx с `--add-module=../ngx_brotli`;
- либо отдать сжатие Cloudflare (Brotli включён по умолчанию для проксируемых доменов);
- либо оставить gzip — но тогда не тратить время на этот пункт.

### Вариант B: динамический Brotli

```nginx
brotli on;
brotli_comp_level 5;
brotli_min_length 1024;
brotli_types text/css application/javascript application/json image/svg+xml;
```

Дешевле по CPU, чем q11, и почти так же эффективно.

### Обязательно

```nginx
gzip_vary on;
# или для brotli:
brotli_vary on;   # если поддерживается сборкой
```

Сейчас на сжатых ответах **нет** `Vary: Accept-Encoding` — это может привести к тому, что прокси отдаст gzip-версию клиенту без поддержки gzip. Проверьте:

```bash
curl -sI -H "Accept-Encoding: gzip" https://nlb/local/templates/index_2026/assets/css/main.css | grep -i vary
```

### Проверка

```bash
curl -sI -H "Accept-Encoding: br" https://nlb/local/templates/index_2026/assets/css/main.css | grep -i content-encoding
# ожидаем: Content-Encoding: br
```

## HTTP/3

Даёт 0-RTT, не блокируется на потерях пакетов, заметно лучше на мобильных сетях. Требует nginx 1.25+ (или сборки с QUIC) и открытого UDP/443.

```nginx
server {
    listen 443 ssl;
    listen 443 quic reuseport;
    http2 on;

    ssl_protocols TLSv1.2 TLSv1.3;

    add_header Alt-Svc 'h3=":443"; ma=86400' always;
}
```

Важно: `Alt-Svc` должен отдаваться на всех ответах, иначе браузер не узнает про h3. UDP/443 часто закрыт на хостинге — проверьте у провайдера.

### Проверка

`curl` на Windows часто собран **без** HTTP/2 и HTTP/3 — сначала посмотрите `curl -V`, есть ли `HTTP2`/`HTTP3` в Features. Если нет, используйте:

```bash
# ALPN (показывает, согласован ли h2)
python -c "import ssl,socket;c=ssl.create_default_context();c.set_alpn_protocols(['h2','http/1.1']);s=c.wrap_socket(socket.create_connection(('nlb',443)),server_hostname='nlb');print(s.selected_alpn_protocol(),s.version())"
```

Ожидаемо сейчас: `h2 TLSv1.3`.

Онлайн: `https://http3check.net/?host=nlb`.

## Приоритет

1. Brotli — 30 минут, −40…−60 КБ.
2. HTTP/3 — 1–2 часа + доступ к UDP/443, эффект в основном на мобильных и плохих сетях.
3. `Vary: Accept-Encoding` — 5 минут, предотвращает проблемы с кэшами.
