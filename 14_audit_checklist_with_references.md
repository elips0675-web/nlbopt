# Чеклист аудита 1C-Bitrix — с источниками решений

## Как пользоваться

Каждый пункт — задача для проверки. Напротив — файл в репозитории с готовым решением/инструкцией. Делай по порядку: **изображения → JS/CSS → кэш → шрифты → виджеты → безопасность**.

---

## 1. Изображения (80% проблемы)

| № | Что проверить / сделать | Где решение | Статус |
|---|------------------------|-------------|--------|
| 1.1 | Добавить `loading="lazy"` всем изображениям ниже первого экрана | [`01_lazy_load_images.md`](01_lazy_load_images.md) — хук `OnEndBufferContent` или правка шаблонов | |
| 1.2 | Включить WebP (через Nginx try_files, CDN или PHP) | [`02_webp_and_compress.md`](02_webp_and_compress.md) — 3 варианта: Nginx, PHP `OnAfterResizeImage`, CDN | |
| 1.3 | Сжать существующие JPG/PNG до q80, ресайз до 1200px | [`02_webp_and_compress.md`](02_webp_and_compress.md) — обработчик `OnAfterFileSave` | |
| 1.4 | Массово конвертировать загруженные файлы в WebP | [`08_convert_to_webp.sh`](08_convert_to_webp.sh) — bash-скрипт через `cwebp -q 80` | |
| 1.5 | Проверить `resize_cache` в инфоблоках — убрать лишние размеры | [`11_performance_audit_checklist.md`](11_performance_audit_checklist.md) — раздел «Изображения» | |
| 1.6 | Добавить `srcset` для адаптивных картинок | [`11_performance_audit_checklist.md`](11_performance_audit_checklist.md) — замена `CFile::ResizeImageGet` | |
| 1.7 | Заменить фоновые `background-image` на `<img loading="lazy">` | [`11_performance_audit_checklist.md`](11_performance_audit_checklist.md) — конкретные проблемы | |

## 2. JavaScript

| № | Что проверить / сделать | Где решение | Статус |
|---|------------------------|-------------|--------|
| 2.1 | Включить минификацию JS в админке Битрикс | [`03_minification.md`](03_minification.md) — Настройки → Главный модуль | |
| 2.2 | Объединить JS в один файл | [`03_minification.md`](03_minification.md) — константы `BX_MINIFY_SCRIPT`, `BX_ASSET_CACHE` | |
| 2.3 | Перенести скрипты из `<head>` перед `</body>` | [`03_minification.md`](03_minification.md) — настройка «Переносить JS в конец» | |
| 2.4 | Удалить неиспользуемые JS-модули (pull.client, protobuf, dexie, rest.client) | [`04_remove_unused_modules.md`](04_remove_unused_modules.md) — хук `OnEndBufferContent` | |
| 2.5 | Проверить устаревшие библиотеки (OwlCarousel, jQuery) | [`04_remove_unused_modules.md`](04_remove_unused_modules.md) — DevTools → Network | |
| 2.6 | Сторонние скрипты (метрики, аналитика) — defer/async | [`07_defer_widgets.md`](07_defer_widgets.md) — общий принцип | |

## 3. CSS

| № | Что проверить / сделать | Где решение | Статус |
|---|------------------------|-------------|--------|
| 3.1 | Включить минификацию CSS в админке Битрикс | [`03_minification.md`](03_minification.md) — Настройки → Главный модуль | |
| 3.2 | Объединить CSS в один файл | [`03_minification.md`](03_minification.md) — та же настройка | |
| 3.3 | Удалить неиспользуемые стили (Bootstrap, jQuery UI) | [`11_performance_audit_checklist.md`](11_performance_audit_checklist.md) — раздел CSS | |
| 3.4 | Inline-`style=""` заменить на классы | [`11_performance_audit_checklist.md`](11_performance_audit_checklist.md) — раздел CSS | |
| 3.5 | Отключить ненужные стили ядра Битрикс | [`11_performance_audit_checklist.md`](11_performance_audit_checklist.md) — `/bitrix/css/` | |

## 4. Кэширование и сервер

| № | Что проверить / сделать | Где решение | Статус |
|---|------------------------|-------------|--------|
| 4.1 | Включить композитный режим (HTML-кэш) | [`05_composite_and_cache.md`](05_composite_and_cache.md) — админка или принудительно в `init.php` | |
| 4.2 | Настроить Cache-Control для статики (365d, public, immutable) | [`05_composite_and_cache.md`](05_composite_and_cache.md) — Nginx или Apache | |
| 4.3 | Включить Gzip/Brotli | [`05_composite_and_cache.md`](05_composite_and_cache.md) — `.htaccess` или nginx | |
| 4.4 | Проверить HTTP/2 или HTTP/3 на сервере | [`11_performance_audit_checklist.md`](11_performance_audit_checklist.md) — раздел «Сервер/Кэширование» | |
| 4.5 | Настроить Expires-заголовки для изображений, CSS, JS | [`05_composite_and_cache.md`](05_composite_and_cache.md) — Apache `mod_expires` | |

## 5. Шрифты и внешние ресурсы

| № | Что проверить / сделать | Где решение | Статус |
|---|------------------------|-------------|--------|
| 5.1 | Добавить `preconnect` для Google Fonts | [`06_fonts_display_swap.md`](06_fonts_display_swap.md) — `fonts.googleapis.com` + `fonts.gstatic.com` | |
| 5.2 | Установить `display=swap` в URL Google Fonts | [`06_fonts_display_swap.md`](06_fonts_display_swap.md) — параметр в href | |
| 5.3 | Перевести шрифты на self-hosted (WOFF2) с `font-display: swap` | [`06_fonts_display_swap.md`](06_fonts_display_swap.md) — `@font-face` + `font-display: swap` | |
| 5.4 | Отложить загрузку Jivosite до взаимодействия с пользователем | [`07_defer_widgets.md`](07_defer_widgets.md) — событийный подход (scroll/click/touchstart) | |
| 5.5 | Отложить загрузку megavenue.by через `requestIdleCallback` | [`07_defer_widgets.md`](07_defer_widgets.md) — `requestIdleCallback` с таймаутом 5s | |

## 6. Безопасность

| № | Что проверить / сделать | Где решение | Статус |
|---|------------------------|-------------|--------|
| 6.1 | Проверить `/bitrix/.settings.php` на утечку паролей | [`10_security_audit_and_headers.md`](10_security_audit_and_headers.md) — критически важные файлы | |
| 6.2 | Проверить `dbconn.php` / `after_connect.php` на учётные данные | [`10_security_audit_and_headers.md`](10_security_audit_and_headers.md) — файл 2-3 | |
| 6.3 | Проверить версию ядра Битрикс на известные CVE | [`10_security_audit_and_headers.md`](10_security_audit_and_headers.md) — `version.php` | |
| 6.4 | Проверить модуль «Проактивная защита» — включён ли? | [`10_security_audit_and_headers.md`](10_security_audit_and_headers.md) — `/bitrix/modules/security/` | |
| 6.5 | Добавить HSTS (Strict-Transport-Security) | [`10_security_audit_and_headers.md`](10_security_audit_and_headers.md) — Nginx/Apache/PHP | |
| 6.6 | Добавить CSP (Content-Security-Policy) в режиме Report-Only | [`10_security_audit_and_headers.md`](10_security_audit_and_headers.md) — хук `OnProlog` в `init.php` | |
| 6.7 | Добавить COOP + COEP + CORP (изоляция источников) | [`10_security_audit_and_headers.md`](10_security_audit_and_headers.md) — те же заголовки | |
| 6.8 | Добавить X-Frame-Options: DENY, X-Content-Type-Options: nosniff | [`10_security_audit_and_headers.md`](10_security_audit_and_headers.md) — доп. заголовки | |
| 6.9 | Настроить Referrer-Policy и Permissions-Policy | [`10_security_audit_and_headers.md`](10_security_audit_and_headers.md) — в блоке OnProlog | |
| 6.10 | Отключить листинг директорий | [`13_hide_files_from_public.md`](13_hide_files_from_public.md) — `Options -Indexes` | |
| 6.11 | Закрыть служебные папки (bitrix/admin, modules, setup, tools) | [`13_hide_files_from_public.md`](13_hide_files_from_public.md) — RewriteRule 403 / deny all | |
| 6.12 | Запретить выполнение PHP в `/upload/` | [`13_hide_files_from_public.md`](13_hide_files_from_public.md) — Nginx location / Apache FilesMatch | |
| 6.13 | Настроить `robots.txt` — Disallow `/bitrix/`, `/local/`, `/upload/` | [`13_hide_files_from_public.md`](13_hide_files_from_public.md) — секция robots.txt | |
| 6.14 | Проверить `/bitrix/php_interface/init.php` на бэкдоры | [`10_security_audit_and_headers.md`](10_security_audit_and_headers.md) — доп. файлы | |
| 6.15 | SSL/TLS: TLSv1.2 + TLSv1.3, безопасные шифры, отключить session tickets | [`09_security_and_ssl.md`](09_security_and_ssl.md) — секция SSL/TLS | |
| 6.16 | Rate limiting на `/bitrix/admin/` (5r/s burst 10) | [`09_security_and_ssl.md`](09_security_and_ssl.md) — `limit_req_zone` nginx | |
| 6.17 | Проверить бэкапы — не лежат ли в открытом доступе | [`10_security_audit_and_headers.md`](10_security_audit_and_headers.md) — `/bitrix/backup/` | |
| 6.18 | Закрыть `.settings.php`, `php_interface/`, `.access.php` от внешнего доступа | [`13_hide_files_from_public.md`](13_hide_files_from_public.md) — точечные RewriteRule | |
| 6.19 | Проверить заголовки через `curl -I` или securityheaders.com | [`10_security_audit_and_headers.md`](10_security_audit_and_headers.md) — инструменты проверки | |
| 6.20 | Итоговый блок заголовков — скопировать в `/bitrix/php_interface/init.php` | [`10_security_audit_and_headers.md`](10_security_audit_and_headers.md) — итоговый код | |

## Итоговый статус

| Категория | Всего | Сделано | Осталось |
|-----------|-------|---------|----------|
| 1. Изображения | 7 | | |
| 2. JavaScript | 6 | | |
| 3. CSS | 5 | | |
| 4. Кэширование | 5 | | |
| 5. Шрифты / Виджеты | 5 | | |
| 6. Безопасность | 20 | | |
| **Итого** | **48** | | |

---

## Структура репозитория

```
01_lazy_load_images.md          — Ленивая загрузка изображений
02_webp_and_compress.md         — WebP + сжатие
03_minification.md              — Минификация JS/CSS
04_remove_unused_modules.md     — Удаление лишних JS-модулей
05_composite_and_cache.md       — Композитный режим + Cache-Control
06_fonts_display_swap.md        — Оптимизация шрифтов
07_defer_widgets.md             — Отложенная загрузка виджетов
08_convert_to_webp.sh           — Bash-скрипт конвертации в WebP
09_security_and_ssl.md          — HTTP-заголовки + SSL/TLS
10_security_audit_and_headers.md — Аудит безопасности + заголовки
11_performance_audit_checklist.md — Чеклист производительности
12_full_audit_checklist.md      — Сводный чеклист
13_hide_files_from_public.md    — Закрытие файлов от публичного доступа
14_audit_checklist_with_references.md — Этот файл
```
