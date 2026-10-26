# Полный чеклист аудита 1C-Bitrix — Безопасность + Производительность

## Безопасность

### Критически важные файлы (проверить утечки)

- [ ] `/bitrix/.settings.php` — пароли, ключи шифрования, подключение к БД
- [ ] `/bitrix/php_interface/after_connect.php` или `after_connect_d7.php`
- [ ] `/bitrix/php_interface/dbconn.php` (старые версии)
- [ ] `/bitrix/.access.php` — права доступа в админке
- [ ] `/bitrix/modules/main/admin/define.php` — ключи лицензии

### Уязвимости и доступы

- [ ] `.htaccess` корня и `/bitrix/` — закрыты ли служебные папки
- [ ] `/bitrix/modules/main/classes/general/version.php` — версия ядра (CVE)
- [ ] `/bitrix/modules/security/` — модуль проактивной защиты включён?
- [ ] `/bitrix/.settings_extra.php` — кастомные настройки
- [ ] Логи ошибок PHP — не светят ли пути и пароли
- [ ] `/bitrix/php_interface/init.php` — есть ли бэкдоры в хуках
- [ ] `/bitrix/templates/` — `header.php` / `footer.php` на вредоносный JS/PHP
- [ ] `/bitrix/backup/` — доступен ли архив бэкапа извне
- [ ] `/bitrix/.htaccess.php` — защита от выполнения PHP в `/upload/`

### HTTP-заголовки (security headers)

- [ ] **CSP** — `Content-Security-Policy` (начать с Report-Only)
- [ ] **HSTS** — `Strict-Transport-Security` (`max-age=31536000; includeSubDomains`)
- [ ] **COOP** — `Cross-Origin-Opener-Policy: same-origin`
- [ ] **COEP** — `Cross-Origin-Embedder-Policy: require-corp`
- [ ] **CORP** — `Cross-Origin-Resource-Policy: same-origin`
- [ ] **X-Content-Type-Options:** `nosniff`
- [ ] **X-Frame-Options:** `DENY`
- [ ] **Referrer-Policy:** `strict-origin-when-cross-origin`
- [ ] **Permissions-Policy:** геолокация, камера, микрофон отключены
- [ ] **Trusted Types** — `require-trusted-types-for 'script'`

### Инструменты проверки

- [ ] `curl -I https://ваш-сайт.ru` — проверить заголовки
- [ ] [securityheaders.com](https://securityheaders.com) — оценка заголовков
- [ ] Проверить HTTPS на всех поддоменах (перед HSTS preload)

---

## Производительность

### Изображения (~80% проблемы)

- [ ] Настроена конвертация WebP/AVIF в настройках главного модуля
- [ ] `resize_cache` в инфоблоках — правильные размеры, нет избыточных
- [ ] `CFile::ResizeImageGet()` используется вместо прямых URL
- [ ] Добавлен `srcset` для адаптивных изображений
- [ ] Ленивая загрузка (`loading="lazy"`) на всех картинках
- [ ] Фоновые `background-image` заменены на `<img>` с lazy
- [ ] Нет картинок с избыточным разрешением (752px при показе 694px)

### JavaScript

- [ ] Скрипты перенесены из `<head>` перед `</body>`
- [ ] Устаревшие библиотеки удалены (OwlCarousel, jQuery если не нужен)
- [ ] Сторонние скрипты (метрики, аналитика) — defer/async
- [ ] Нет inline-скриптов, блокирующих рендер

### CSS

- [ ] Неиспользуемые стили удалены (Bootstrap, jQuery UI)
- [ ] Отключены ненужные стили ядра Битрикс
- [ ] Inline-`style=""` заменены на классы

### Сервер / Кэширование

- [ ] **Gzip/Brotli** включён в `.htaccess` или nginx *(на 26.10.2026 — только gzip, Brotli нет)*
- [ ] **Кэширование статики** — далёкий `Expires` / `Cache-Control` для CSS, JS, изображений *(сейчас 30 дней, без `immutable`)*
- [ ] **Композитный режим** (HTML-кэш) включён в `.settings.php` *(сейчас HTML отдаётся с `no-store`)*
- [ ] **HTTP/2 или HTTP/3** на сервере *(HTTP/2 и TLS 1.3 есть, HTTP/3 нет)*
- [ ] Медленные SQL-запросы — `after_connect.php` / `dbconn.php`

### Шрифты и внешние ресурсы

- [x] Шрифты self-hosted (Raleway/Lora, WOFF2, `font-display: swap`) — сделано в шаблоне `index_2026`
- [ ] Шрифты: preload двух кириллических WOFF2, MIME `font/woff2`, кэш на год
- [ ] Виджеты, кнопки соцсетей — отложенная загрузка *(Jivo всё ещё в `<head>`)*

### Agentic Browsing (Lighthouse 13.3, экспериментально)

- [ ] **Accessibility tree**: у каждой ссылки/кнопки есть доступное имя *(сейчас 3 ссылки без имени → 1/2)*
- [x] **CLS = 0** — проверка стабильности проходит
- [ ] **`llms.txt`** в корне: Markdown-H1, минимум одна ссылка `[текст](url)`, больше 50 символов
- [ ] Любой `.txt` отдаётся с 200, а не 403 *(сейчас 403 на всё, кроме `robots.txt`)*
- [ ] WebMCP — только если нужен пилот: origin trial Chrome 149–156, без него аудиты N/A

Подробно — `31_agentic_browsing.md`.

---

## Итог

| Область | Статус | Приоритет |
|---------|--------|-----------|
| Утечки учетных данных | | 🔴 |
| Устаревшая версия / CVE | | 🔴 |
| HTTP-заголовки | | 🟠 |
| Изображения (WebP, lazy, srcset) | | 🟠 |
| JS/CSS оптимизация | | 🟡 |
| Кэширование / Композит | | 🟡 |
| Шрифты / Внешние ресурсы | | 🟢 |
| Agentic Browsing (`llms.txt`, a11y tree) | 1/2 | 🟢 |
