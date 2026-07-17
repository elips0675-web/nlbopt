# Оптимизация nlb.by

Прогнал сайт через Lighthouse локально — картина совпадает с вашими 46 баллами, причины оценки видны очень чётко. Вот разбор и план по приоритетам.

## Что тормозит мобильную версию

| Проблема | Масштаб |
|----------|---------|
| Изображения (нет lazy-load, не сжаты, не WebP) | ~7 МБ потенциальной экономии |
| JS-бандлы Битрикса (не минифицированы, лишние модули) | ~1,3 МБ, TBT ~1,2 с |
| Блокирующие CSS + Google Fonts | ~1 с задержки первой отрисовки |
| Ответ сервера (TTFB) | ~0,9 с |
| Короткое кэширование статики | 128 ресурсов |

**Конкретика:** на главной 92 изображения, из них 55 за пределами экрана — и ни одного с `loading="lazy"`. Самые тяжёлые: Af_Lecishcha.png (733 КБ), Sl_Kalyarovi_Susvet.jpg (712 КБ), Af_Danilov.jpg (702 КБ), Sl_Kryshtali_pamyaci.jpg (656 КБ). JS: шаблонный бандл template\_...js — 826 КБ, из них 208 КБ не минифицированы и 79% не используется на главной. Плюс грузятся protobuf.js (71 КБ, тоже не минифицирован), dexie, pull.client, rest.client — на публичной странице они не нужны.

## План по приоритету (эффект / трудозатраты)

### 1. Изображения — главный резерв, до +20 баллов

Добавить `loading="lazy"` всем `<img>` ниже первого экрана (в шаблоне Битрикса — правка компонентов слайдера/афиши/новостей). Это одна строка на тег, эффект — минус ~5–7 МБ трафика на старте.

Сконвертировать JPG/PNG в WebP (экономия ~6,8 МБ) и пережать баннеры: никакой картинке в слайдере не нужно быть 700 КБ — 1200px по ширине и качество 80 хватит с запасом.

В Битриксе: включить обработку изображений (resize\_cache, метод CFile::ResizeImageGet с WebP в новых версиях модуля «Главный»), либо отдать это на уровень nginx/CDN.

### 2. Настройки Битрикса — быстрые переключатели, до +10 баллов

В «Настройки → Главный модуль → Оптимизация CSS/JS» включить: минификацию JS и CSS, объединение файлов, перенос JS в конец страницы. Сейчас минификация выключена — отсюда 208 КБ «сырого» шаблонного JS и 71 КБ protobuf.js.

### 3. Убрать лишние модули Битрикса с публички

pull.client, protobuf, dexie, rest.client тянутся на каждую страницу. Если чат/уведомления на фронтенде не используются — отключить подключение этих модулей в шаблоне сайта. Минус ~400 КБ JS и заметная часть TBT.

### 4. Кэширование — и TTFB, и повторные визиты

Включить «Композитный сайт» (автокомпозит) — TTFB ~0,9 с для Битрикса означает, что страница каждый раз собирается заново.

На уровне nginx/Apache: длинный Cache-Control (год) для /upload/, /bitrix/cache/, шрифтов; сейчас аудит ругается на 128 ресурсов с коротким TTL.

### 5. Шрифты и блокирующий CSS (~1 с к FCP)

Google Fonts грузится без `display=swap` — добавить параметр или переехать на self-hosted шрифты (Open Sans + Noto Serif, подключить с `font-display: swap`).

Добавить `<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>`.

Критический CSS для первого экрана — инлайн, остальное с `media="print"` → onload-трюк или `rel="preload"`.

### 6. Сторонние виджеты

Jivosite и megavenue.by грузятся сразу. Переведите их на отложенную загрузку (через requestIdleCallback или по первому взаимодействию пользователя, задержка 3–5 с) — визуально ничего не изменится, а main thread освободится.

## Реалистичный прогноз

Пункты 1–2 (изображения + минификация) — самые дешёвые по труду и дадут основной скачок: с **46 до ~65–75**. Добавление кэширования и чистки модулей — к **~80**. CLS у вас и так неплохой (0,12), спецвозможности и SEO в порядке — так что вся работа именно про вес и блокировки.

---

# Файлы-инструкции

Порядок выполнения (по приоритету):

## Быстрый эффект (сделать за 1 день, даст +20-30 баллов)

1. **`03_minification.md`** — включить минификацию JS/CSS (5 мин в админке)
2. **`01_lazy_load_images.md`** — добавить loading="lazy" (копировать код в init.php)
3. **`04_remove_unused_modules.md`** — отключить pull/protobuf/dexie/rest.client (копировать код в init.php)
4. **`08_convert_to_webp.sh`** — запустить конвертацию изображений (залить и запустить скрипт)
5. **`02_webp_and_compress.md`** — настроить Nginx для WebP + сжатие

## Средний приоритет (ещё +10-15 баллов)

6. **`05_composite_and_cache.md`** — включить композит и Cache-Control
7. **`06_fonts_display_swap.md`** — display=swap + preconnect для шрифтов

## Дополнительно

8. **`07_defer_widgets.md`** — отложить загрузку Jivosite и megavenue.by
9. **`09_security_and_ssl.md`** — HTTP-заголовки безопасности (HSTS, CSP, X-Frame-Options и др.), усиление SSL/TLS, rate limiting

---

## Инструменты для проверки

| Инструмент | Ссылка |
|-----------|--------|
| PageSpeed Insights | https://pagespeed.web.dev/analysis/https-nlb-by |
| Security Headers | https://securityheaders.com/?q=nlb.by&followRedirects=on |
| SSL Labs | https://www.ssllabs.com/ssltest/analyze.html?d=nlb.by |
| GTmetrix | https://gtmetrix.com/?url=https://nlb.by |
| Mozilla Observatory | https://observatory.mozilla.org/analyze/nlb.by |
| Sucuri SiteCheck | https://sitecheck.sucuri.net/results/https/nlb.by |
| CSP Evaluator | https://csp-evaluator.withgoogle.com/ |
| urlscan.io | https://urlscan.io/ |
| VirusTotal | https://www.virustotal.com/gui/domain/nlb.by |
| Geekflare Tools | https://geekflare.com/tools/security-headers |
| WebPageTest | https://www.webpagetest.org/ |
| W3C Validator | https://validator.w3.org/ |
| Brotli Test | https://tools.keycdn.com/brotli |
| HTTP/3 Check | https://http3check.net/?host=nlb.by |
| Mobile-Friendly Test | https://search.google.com/test/mobile-friendly?id=nlb.by |
| WAVE (a11y) | https://wave.webaim.org/ |
| Schema Validator | https://validator.schema.org/ |

---

Для каждого пункта: прочитайте файл, скопируйте код на сервер, примените.
