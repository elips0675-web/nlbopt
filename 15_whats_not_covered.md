# Что ещё не покрыто — производительность и безопасность

В репозитории 14 файлов (01–14), но следующие темы остались за бортом. Ниже — список того, что можно добавить.

---

## Производительность — не покрыто

### 1. Critical CSS (критические стили «над сгибом»)

**Суть:** Inline-стили для первого экрана в `<head>`, остальное загружать асинхронно. Битрикс генерирует много CSS — без Critical CSS первый рендер ждёт загрузки всех стилей.

**Что сделать:**
- Выделить стили для шапки, главного меню, первого блока
- Вписать их inline в `<head>` через `header.php`
- Остальные стили грузить через `media="print" onload="this.media='all'"` или `loadCSS`

### 2. PHP OPcache

**Суть:** Битрикс — тяжёлый фреймворк. Без OPcache каждый запрос компилирует PHP-файлы заново.

```
opcache.enable=1
opcache.memory_consumption=256
opcache.max_accelerated_files=40000
opcache.revalidate_freq=60
opcache.validate_timestamps=1
```

### 3. PHP-FPM tuning

**Суть:** Неверный `pm.max_children` — либо OOM (kill), либо простой ресурсов.

```
pm = dynamic
pm.max_children = 50
pm.start_servers = 8
pm.min_spare_servers = 4
pm.max_spare_servers = 16
pm.max_requests = 500
```

### 4. MySQL / MariaDB tuning

**Суть:** Дефолтный my.cnf рассчитан на 128MB ОЗУ — для Битрикс нужно больше.

```
innodb_buffer_pool_size = 2G       # 70% от ОЗУ сервера БД
innodb_log_file_size = 512M
innodb_flush_log_at_trx_commit = 2 # 0 для скорости, 2 для баланса
query_cache_type = 0               # отключить (innoDB не использует)
tmp_table_size = 256M
max_execution_time = 5000          # убивать медленные запросы
```

### 5. Медленные SQL-запросы (slow query log)

```
slow_query_log = 1
slow_query_log_file = /var/log/mysql/slow.log
long_query_time = 1
```

Проверить индексы: `EXPLAIN SELECT ...` на все запросы каталога и поиска.

### 6. Preload критических ресурсов

```html
<link rel="preload" href="/fonts/OpenSans-Regular.woff2" as="font" crossorigin>
<link rel="preload" href="/upload/hero.webp" as="image">
<link rel="preload" href="/bitrix/templates/.../critical.css" as="style">
```

### 7. Lazy load для iframe (YouTube, карты)

```html
<iframe src="about:blank" data-src="https://youtube.com/embed/..." loading="lazy">
```

Или через IntersectionObserver.

### 8. Brotli vs Gzip — уровень сжатия

Brotli эффективнее gzip на ~20%, но уровень 11 жрёт CPU при каждом запросе. Лучше статику сжимать заранее (brotli --quality 6 --input file.js --output file.js.br).

```
# nginx: предсозданные .br файлы
brotli_static on;
brotli_level 6;
```

### 9. CDN для статики

Вынести `/bitrix/js/`, `/bitrix/templates/`, `/upload/` на CDN (Cloudflare, Selectel, Qrator). Сокращает TTFB для удалённых пользователей.

### 10. HTTP/3 (QUIC)

**Суть:** Один запрос вместо 3 round-trip (TCP + TLS 1.3). Даёт +10–30% на мобильных.

### 11. Server-Timing header

Помогает увидеть узкие места через DevTools:

```php
header("Server-Timing: db={$dbTime};php={$phpTime};composite={$cacheHit}");
```

### 12. AVIF — формат изображений

**Суть:** AVIF сжимает на ~30% лучше WebP при том же качестве. Поддержка: Chrome/Edge/Opera, Safari 16+, Firefox.

**Что сделать:**
- Добавить `<source type="image/avif" srcset="...">` в `<picture>`
- Или через Nginx try_files (аналогично WebP из `02_webp_and_compress.md`)

### 13. CSS containment

```css
.product-card { contain: layout style paint; }
```

Ограничивает область перерисовки — помогает при reflow после загрузки изображений.

### 14. Resource Hints (preconnect, prefetch, prerender)

```html
<link rel="preconnect" href="https://api.jivosite.com">
<link rel="dns-prefetch" href="https://cdn.cloudflare.net">
<link rel="prerender" href="https://site.ru/catalog/">
```

### 15. Font subsetting

**Суть:** Open Sans Regular весит ~150KB, но кириллице нужно только ~40KB. Вырезать через `pyftsubset` или Google Fonts trims.

### 16. Уменьшить количество HTTP-запросов

- Иконки → SVG-спрайт
- Иконки соцсетей → inline SVG (<symbol>)
- Счётчики → склеить в один запрос

---

## Безопасность — не покрыто

### 1. Двухфакторная аутентификация (2FA)

Битрикс поддерживает 2FA через модуль «Проактивная защита». Включить:
- `/bitrix/admin/security_otp.php`
- Принудительно для админов, опционально для пользователей

### 2. Fail2ban — защита от брутфорса

**Суть:** Банить IP после N неудачных попыток логина.

```
# /etc/fail2ban/jail.local
[bitrix-admin]
enabled  = true
port     = http,https
filter   = bitrix-admin
logpath  = /var/log/nginx/access.log
maxretry = 5
bantime  = 3600
findtime = 300
```

### 3. ModSecurity (WAF)

**Суть:** Промышленный WAF на уровне веб-сервера. Блокирует SQLi, XSS, RFI, LFI до того, как запрос дойдёт до PHP.

```nginx
modsecurity on;
modsecurity_rules_file /etc/nginx/modsec/main.conf;
```

### 4. Мониторинг целостности файлов (AIDE / Tripwire)

**Суть:** Любое изменение файла ядра Битрикс (бэкдор, вредоносная правка) — тревога.

```bash
aide --init
aide --check  # ежедневно по cron
```

### 5. SELinux / AppArmor

**Суть:** Если веб-сервер скомпрометирован — он не сможет читать `/etc/shadow` или писать в `/tmp/shell.php`.

```bash
setsebool -P httpd_can_network_connect on
chcon -R -t httpd_sys_content_t /var/www/site
```

### 6. Session security

```php
ini_set('session.cookie_httponly', 1);
ini_set('session.cookie_secure', 1);
ini_set('session.cookie_samesite', 'Lax');
ini_set('session.gc_maxlifetime', 1800);
ini_set('session.use_strict_mode', 1);
ini_set('session.sid_length', 128);
```

### 7. Subresource Integrity (SRI)

**Суть:** Если CDN скомпрометируют — браузер не загрузит изменённый скрипт.

```html
<script src="https://cdn.jsdelivr.net/.../jquery.min.js"
        integrity="sha384-..."
        crossorigin="anonymous"></script>
```

### 8. Блокировка по IP для админки

Доступ к `/bitrix/admin/` — только с IP офиса/VPN.

```nginx
location ^~ /bitrix/admin/ {
    allow 192.168.1.0/24;
    allow 10.0.0.0/8;
    deny all;
}
```

### 9. SSH hardening

```
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
Port 22022    # не 22
MaxAuthTries 3
```

### 10. MySQL security

```sql
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1');
CREATE USER 'bitrix'@'localhost' IDENTIFIED BY 'сильный_пароль';
GRANT ALL ON bitrix_db.* TO 'bitrix'@'localhost';
```

### 11. Шифрование бэкапов

```bash
gpg --symmetric --cipher-algo AES256 backup.sql
# или
openssl enc -aes-256-cbc -salt -pbkdf2 -in backup.sql -out backup.sql.enc
```

### 12. Email security (SPF, DKIM, DMARC)

**Суть:** Чтобы мошенники не отправляли письма с вашего домена.

| Запись | Пример |
|--------|--------|
| SPF | `v=spf1 mx a include:_spf.google.com ~all` |
| DKIM | Подпись в DNS от почтовой системы |
| DMARC | `v=DMARC1; p=quarantine; rua=mailto:dmarc@site.ru` |

### 13. DNS security (DNSSEC, CAA)

- **DNSSEC** — защита от подмены DNS
- **CAA** — какие CA могут выпускать SSL для вашего домена
  ```
  example.com. CAA 0 issue "letsencrypt.org"
  example.com. CAA 0 issue "comodoca.com"
  ```

### 14. Security.txt

Файл `/.well-known/security.txt` — стандарт для связи с security-исследователями.

```
Contact: mailto:security@site.ru
Encryption: https://site.ru/pgp-key.txt
Preferred-Languages: ru, en
Policy: https://site.ru/security-policy
```

### 15. Удаление ServerSignature

Включать лишнюю информацию о сервере в ответах.

```nginx
server_tokens off;
```

```apache
ServerSignature Off
ServerTokens Prod
```

### 16. Vulnerability scanning (Nikto, OWASP ZAP)

Регулярное сканирование внешнего периметра.

```bash
nikto -h https://site.ru
zap-cli quick-scan https://site.ru
```

### 17. API rate limiting — детально

Для каждого эндпоинта свой лимит (а не 5r/s на всю админку).

```nginx
limit_req_zone $binary_remote_addr zone=search:10m rate=3r/s;
location /search/ {
    limit_req zone=search burst=5 nodelay;
}
```

### 18. Content Security Policy — продвинутые директивы

- `report-to` вместо `report-uri` (Reporting API)
- `strict-dynamic` для отказа от белого списка хешей
- `worker-src` для изоляции Service Worker

```
Content-Security-Policy: default-src 'self'; script-src 'strict-dynamic' 'sha256-...';
```

### 19. Trusted Types — защита от DOM-XSS

Блокирует `innerHTML`, `document.write`, `eval` на уровне браузера.

```php
header("Content-Security-Policy: require-trusted-types-for 'script'; trusted-types default");
```

**Проблема:** Битрикс активно использует `innerHTML`. Нужно писать полифиллы для стандартных компонентов.

### 20. Registry of Known Exploited Vulnerabilities (CVE)

Раз в месяц проверять свежие CVE для вашей версии Битрикс:

- `https://cve.mitre.org/cgi-bin/cvekey.cgi?keyword=bitrix`
- `https://packetstormsecurity.com/search/?q=bitrix`
- Подписаться на бюллетени Битрикс: `https://www.1c-bitrix.ru/support/security/`

---

## Итог: что можно добавить в репозиторий

| № | Тема | Тип |
|---|------|-----|
| 15 | Critical CSS | Производительность |
| 16 | PHP OPcache + PHP-FPM | Производительность |
| 17 | MySQL tuning + slow query log | Производительность |
| 18 | Preload / Resource Hints | Производительность |
| 19 | Lazy load iframe (YouTube, карты) | Производительность |
| 20 | Brotli статика + HTTP/3 | Производительность |
| 21 | CDN для статики | Производительность |
| 22 | AVIF изображения | Производительность |
| 23 | CSS containment + Server-Timing | Производительность |
| 24 | 2FA / Fail2ban / ModSecurity | Безопасность |
| 25 | AIDE / SELinux / SSH hardening | Безопасность |
| 26 | Session security / SRI / CSP strict-dynamic | Безопасность |
| 27 | SPF/DKIM/DMARC / DNSSEC / CAA | Безопасность |
| 28 | Vulnerability scanning / CVE monitoring | Безопасность |
