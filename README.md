# Оптимизация nlb

**Аудит от 26.10.2026** — после редизайна сайта (новый шаблон `/local/templates/index_2026/`).

Прошлый разбор писался под старый шаблон и старые цифры (46 баллов, 92 картинки, 826 КБ шаблонного JS, Google Fonts). Часть проблем уже закрыта — новый шаблон заметно чище. Но главный резерв (изображения) остался нетронутым, а вес страницы даже вырос из-за одного PNG на 4,2 МБ.

---

## Что уже сделано в новом шаблоне

| Было (старый аудит) | Стало (26.10.2026) |
|---|---|
| Шаблонный JS-бандл `template_*.js` — 826 КБ, не минифицирован | **1,2 КБ**, минифицирован и объединён |
| Шаблонный CSS-бандл — блокирующий и большой | **1 КБ** + 4 локальных файла |
| Google Fonts с внешних доменов | **Self-hosted** Raleway + Lora, WOFF2, `font-display: swap` |
| Cache-Control короткий, 128 ресурсов с замечаниями | **30 дней** (`max-age=2592000`) на статике |
| megavenue.by грузился сразу | **убран** |
| HTTP/1.1? | **HTTP/2 + TLS 1.3** работают |
| `/bitrix/`, `/upload/`, `.git` открыты | **403**, `/adminer.php` — 404 |
| Нет 404-страницы | Стилизованная 404 (98 КБ HTML) |
| TTFB ~0,9 с | **0,47 с** |

То есть пункты 2, 5 (частично) и 6 из прошлого плана закрыты. Ниже — только то, что реально осталось.

---

## Замеры 26.10.2026

Главная страница, Chrome, десктоп, Минск. Метрики — из Resource Timing.

| Метрика | Значение |
|---|---|
| Вес страницы (transfer) | **8 364 КБ** |
| Изображения | **7 972 КБ** — 95% веса, 30 запросов |
| JS | 683 КБ decoded / 213 КБ transfer, 12 запросов |
| CSS | 199 КБ decoded / 47 КБ transfer, 6 запросов (все блокирующие) |
| Шрифты | 131 КБ, 4 файла WOFF2 |
| HTML | 220 КБ raw / 60 КБ gzip, **не минифицирован** (1830 переводов строк) |
| Запросов всего | 60 |
| DOM | 1 401 узел |
| TTFB | 471 мс |
| FCP (десктоп) | **1 056 мс** |
| DOMContentLoaded | 1 016 мс |
| Load | 2 684 мс |
| `<img>` в DOM / с `loading="lazy"` | 37 / **0** |
| `srcset` / `width`+`height` | 0 / 0 |

### Lighthouse 13.3 — мобильный

Прогон в Chrome DevTools (Lighthouse 13.3, эмуляция Moto G, Slow 4G). Это то, что видит Google в PageSpeed Insights.

| Категория | Балл |
|---|---|
| Performance | **89** |
| Accessibility | **83** |
| Best Practices | **100** |
| SEO | **83** |
| Agentic Browsing | **1/2** |

| Метрика | Значение | Оценка |
|---|---|---|
| LCP | 2,3 с | 🟡 до порога «хорошо» 2,5 с — запас всего 200 мс |
| FCP | 1,4 с | 🟢 |
| TBT | **390 мс** | 🔴 главный резерв балла |
| CLS | **0** | 🟢 |
| SI | 1,5 с | 🟢 |

### Диагностика Lighthouse

| Диагностика | Значение | Куда смотреть |
|---|---|---|
| Improve image delivery | **−5 141 KiB** | `02_webp_and_compress.md`, `08_convert_to_webp.sh` |
| Avoid enormous network payloads | 8 804 KiB | следствие картинок |
| Reduce unused JavaScript | **−190 KiB** | `04_remove_unused_modules.md` |
| Minify JavaScript | **−75 KiB** | `04` — `protobuf.js` не минифицирован |
| Minimize main-thread work | **3,0 с** | JS + Jivo: `04`, `07` |
| Avoid long main-thread tasks | 4 задачи | то же |
| Render-blocking requests | −170 мс | `16_critical_css.md` |
| Reduce unused CSS | −15 KiB | Coverage → `bitrix.css`, `16` |
| Minify CSS | −6 KiB | `03_minification.md`, `16` |
| Efficient cache lifetimes | −139 KiB | `05_composite_and_cache.md` |
| Image elements without width/height | — | `01_lazy_load_images.md` |
| Back/forward cache | 2 причины | `05` + `07` |
| Non-composited animations | 1 элемент | `22_containment_server_timing.md` |
| LCP request discovery | — | preload hero: `19_preload_and_iframe.md` |
| Network dependency tree | — | CSS и шрифты: `16`, `19` |
| 3rd parties | — | Jivo: `07_defer_widgets.md` |

Суммарный вес в этом прогоне — **8 804 KiB** (в Resource Timing было 8 364 КБ; разница — кэш, версии файлов и округление). Вывод тот же: 95% веса — картинки, и Lighthouse оценивает экономию от их сжатия в **5,1 МБ**.

**Почему 89 при 8 МБ картинок.** Performance в Lighthouse считается по LCP (25%), TBT (30%), CLS (25%), FCP (10%) и SI (10%). Вес страницы сам по себе балл не снижает — важно, когда отрисовался LCP-элемент и сколько JS заблокировало поток. LCP здесь — текстовый hero, а не тяжёлый PNG, поэтому 2,3 с. Но 8 МБ — это реальный трафик, мобильный интернет и полевые Core Web Vitals, которые Google меряет на живых пользователях. Балл 89 их не отменяет.

**Что это значит для приоритетов.** Балл сейчас двигают две вещи: TBT 390 мс (лишний JS) и LCP 2,3 с (критический CSS, preload, композит). Картинки и lazy-load — это трафик и полевые метрики, а не +20 баллов, как казалось по прошлому аудиту.

Страница «Новости» (`/content/news/`): 3 122 КБ, 22 картинки, 17 из них ниже первого экрана, `loading="lazy"` — 0, meta description и canonical — нет.

### Самые тяжёлые ресурсы

| Ресурс | Вес | Комментарий |
|---|---|---|
| `OON.png` (1920×1079) | **4 277 КБ** | PNG для фотографии — 51% веса главной |
| `Af_105_let_BGU.png` (800×566) | 781 КБ | PNG вместо JPEG/WebP |
| `sl_Fieliks_Humien.jpg` (800×450) | 714 КБ | 800 px при показе ~400 px |
| `Vernost_rodine.jpg` (800×450) | 290 КБ | |
| `af_pesniar.jpg` (800×603) | 263 КБ | |
| `hero-bg-side-2.jpg` (фон hero) | 194 КБ | CSS background, не preload |
| `protobuf.js` | 268 КБ | не минифицирован, 8 712 строк |
| `core.min.js` | 177 КБ | нужен |
| `dexie.bundle.min.js` | 100 КБ | нужен только для Pull |
| `main.css` | 95 КБ | блокирующий |
| `bitrix.css` | 75 КБ | блокирующий, 321 правило |
| `pull.client.min.js` | 49 КБ | чат/уведомления |
| `rest.client.min.js` | 9 КБ | публичке не нужен |

Итого только уникальных картинок на главной — 29 файлов на 7 769 КБ.

---

## Что осталось — по приоритету

| # | Задача | Эффект | Трудоёмкость |
|---|---|---|---|
| 1 | Убрать `protobuf` / `dexie` / `pull.client` / `rest.client`, отложить Jivo | TBT 390 → ~150–250 мс, **+3–6 баллов**; −190 КиБ unused JS, ещё −75 КиБ после минификации | 1–2 часа |
| 2 | WebP/AVIF + ресайз под реальный размер | Lighthouse: **−5,1 МБ** доставки; полевые LCP/CWV (балл почти не изменится) | 1 день |
| 3 | `loading="lazy"` + `decoding="async"` | −5…−6 МБ на первом экране; CLS уже 0, размеры — «не сломать» | 1–2 часа |
| 4 | Brotli (сейчас только gzip) | −40…−60 КБ на CSS/JS/HTML | 30 мин |
| 5 | Cache-Control 30 дней → 1 год + `immutable` | Lighthouse: −139 КиБ на повторных визитах | 30 мин |
| 6 | Композит / кэш HTML (сейчас `no-store`) | TTFB 0,47 → 0,1–0,2 с, LCP; **снимает главную причину отказа bfcache** | 1–2 часа |
| 7 | Критический CSS + preload шрифтов и hero-фона | Render-blocking −170 мс, FCP 1,4 → ~1,0 с, LCP 2,3 → ~2,0 с | 1 день |
| 8 | SEO: meta description, canonical, OG, один H1, sitemap | SEO 83 → 100 (балл дают только description и canonical); OG/H1/sitemap — для выдачи | 2–4 часа |
| 9 | Доступность: link-name, alt, контраст, тач-цели | A11y 83 → 95+, Agentic 1/2 → 2/2 | 1 день |
| 10 | `llms.txt` (после починки `.txt` на сервере) | Agentic: третья проверка; формат важнее наличия | 30 мин |
| 11 | Заголовки безопасности: HSTS, CSP, Referrer-Policy, Permissions-Policy | SecurityHeaders A | 2 часа |
| 12 | Починить MIME шрифтов (`application/force-download`) | надёжная загрузка шрифтов | 15 мин |

### 1. Изображения — 95% веса, но не 20 баллов

`Performance 89` не значит, что картинки можно не трогать. Балл считается по LCP/TBT/CLS, а 8 МБ — это то, что скачивает каждый посетитель с мобильного интернета. В полевых данных Google (CrUX) такие страницы почти всегда выпадают из «хороших» по LCP. Lighthouse оценивает экономию от **Improve image delivery** в **5 141 КиБ** — это 58% текущего веса страницы.

Главная проблема теперь одна и очень конкретная: `OON.png` — 4,2 МБ. Это фотография, сохранённая в PNG. В WebP качества 80 она весит ~200–250 КБ, в AVIF — ~150 КБ. Плюс `Af_105_let_BGU.png` (781 КБ) и три JPEG по 260–714 КБ при показе в 400–800 px.

Порядок действий:

1. Прогнать `08_convert_to_webp.sh` по `/upload/` (с бэкапом).
2. Включить отдачу WebP через nginx (`map $http_accept $webp_suffix`) — см. `02_webp_and_compress.md`. Существующий вариант с `try_files $uri.webp $uri` отдаёт WebP даже тем, кто его не принимает — так нельзя.
3. В компонентах заменить прямые `$arItem["PREVIEW_PICTURE"]["SRC"]` на `CFile::ResizeImageGet()` с нужной шириной и `WEBP`.
4. Для hero-фона — отдельный WebP/AVIF + `preload` (это LCP-ресурс).

### 2. Lazy-load

`loading="lazy"` нет ни на одной из 37 картинок. На главной 11 из них ниже первого экрана, на «Новостях» — 17 из 22. Первые две картинки (герб и флаг в шапке) трогать не нужно, остальные — можно.

Важно: не ставьте `lazy` на LCP-изображение. На главной LCP — hero-блок (фон + заголовок), поэтому карточкам ниже можно смело ставить `lazy`. Код и правила — в `01_lazy_load_images.md`.

CLS сейчас **0** — шаблон уже резервирует место под картинки через CSS, поэтому `width`/`height` не приоритет. Но их стоит добавить: это страховка от сдвигов при смене шаблона и на внутренних страницах.

### 3. Лишние модули Битрикса

`protobuf.js` (268 КБ, не минифицирован) + `dexie` (100 КБ) + `pull.client` (49 КБ) + `rest.client` (9 КБ) = **427 КБ decoded**. На публичных страницах не нужны, если не используется чат/уведомления. Jivo — это отдельный виджет, он от Pull не зависит.

Скрипты подключены в `<head>` нового шаблона. Убирать — через `OnEndBufferContent` с учётом query-строк (`?17865184254439`), иначе регулярка из старой версии инструкции не сработает. Готовый код — в `04_remove_unused_modules.md`.

### 4. Сжатие

Сервер отдаёт **только gzip**. Запрос с `Accept-Encoding: br` возвращает `Content-Length: 95016` без `Content-Encoding` — Brotli не включён. На CSS+JS+HTML это ~320 КБ transfer, экономия от Brotli — 40–60 КБ. HTTP/2 и TLS 1.3 уже есть, HTTP/3 нет (нет `Alt-Svc`).

### 5. Кэширование

Статика сейчас: `Cache-Control: max-age=2592000` (30 дней), без `immutable`, без `Vary: Accept-Encoding` на сжатых ответах. Для файлов с версионным суффиксом (`?v=20261026j`, `?1793004833`) можно смело ставить год + `immutable`.

HTML отдаётся с `Cache-Control: no-store` и `Expires: Thu, 19 Nov 1981` — это значит, что каждый переход (включая «назад») заново собирает страницу. Композит не включён.

### 6. Критический CSS и шрифты

Пять блокирующих стилей: `main.css` (95 КБ), `bitrix.css` (75 КБ), `fonts-local.css` (21 КБ), `a11y-2026.css` (9 КБ), шаблонный бандл (1 КБ). FCP — 1,05 с на десктопе и 1,4 с в мобильном Lighthouse; почти всё это ожидание CSS.

Шрифты уже self-hosted (это плюс), но:

- нет `preload` для двух критичных WOFF2 (кириллица Raleway + Lora);
- в `fonts-local.css` 41 правило `@font-face` (латиница, вьетнамский, математика, символы) — для русского сайта достаточно cyrillic + latin;
- шрифты отдаются с `Content-Type: application/force-download` — неверный MIME, при `nosniff` это риск блокировки в части браузеров;
- кэш 30 дней вместо года.

### 7. Jivo

Остался только Jivo (`code-eu1.jivosite.com/widget/TnYiZsuEsx`), грузится в `<head>` с `async` и `data-skip-moving`. Тянет три домена: `code-eu1.jivosite.com`, `code.jivosite.com`, `node-sb1-az2-23.jivosite.com`. Отложить до первого взаимодействия/`requestIdleCallback` — см. `07_defer_widgets.md`.

### 8. SEO и доступность

Lighthouse 13.3: **SEO 83, Accessibility 83**. В прошлом прогоне на старом Lighthouse было SEO 67 — это разница версий и весов, а не улучшение сайта: `meta description` и `canonical` как не было, так и нет.

SEO 83 — это 10 из 12 аудитов. Не хватает ровно двух:

- `meta-description` — нет ни на главной, ни на внутренних;
- `canonical` — нет ни на одной проверенной странице.

Остальное в SEO-категории проходит. Но за её пределами остаются вещи, которые важнее балла:

- нет Open Graph — репосты в соцсетях и мессенджерах идут без картинки и описания;
- **два `<h1>` на главной** — hero-блок и картинки слайдера продублированы в DOM (похоже, десктопная и мобильная копии);
- `sitemap_index.xml` → `sitemap_000.xml`: 37 051 URL, у 22 606 `lastmod` 2017–2018, внутри 29 ссылок на `/adminer.php` (сейчас 404) и `/shop/login/`;
- в `robots.txt` нет директивы `Sitemap:`;
- доступность: контраст текста, размер тач-целей, 3 ссылки без доступного имени (из-за них же Agentic Browsing 1/2).

Подробно — в `30_seo_meta_a11y.md` и `31_agentic_browsing.md`.

### 9. Безопасность

Есть: `X-Frame-Options: SAMEORIGIN`, `X-Content-Type-Options: nosniff`, cookie `Secure; HttpOnly`, закрытые `/bitrix/`, `/upload/`, `.git`.

Нет: `Strict-Transport-Security`, `Content-Security-Policy`, `Referrer-Policy`, `Permissions-Policy`, `Cross-Origin-Opener-Policy`. Cookie без `SameSite`. Заголовок `X-Powered-CMS: Bitrix Site Manager (hash)` раскрывает CMS и сборку. Подробно — в `09_security_and_ssl.md` и `10_security_audit_and_headers.md`.

### 10. bfcache и анимации

Две диагностики, которые не влияют на Performance напрямую, но видны в отчёте:

- **Page prevented back/forward cache restoration — 2 failure reasons.** Главная причина — `Cache-Control: no-store` на HTML. Вторая — скорее всего открытый WebSocket (Pull/Jivo) или `unload`-обработчик; точную причину покажет DevTools → Application → Back/Forward Cache → Test. Пока bfcache не работает, кнопка «назад» каждый раз пересобирает страницу. Исправление — в `05_composite_and_cache.md` и `07_defer_widgets.md`.
- **Avoid non-composited animations — 1 animated element.** Анимация, вероятно, меняет `top/left/width/height` или `box-shadow`. Перевести на `transform`/`opacity` — тогда кадры рисует композитор, а не main thread. Примеры — в `22_containment_server_timing.md`.

---

## Реалистичный прогноз

Отправная точка — **Performance 89, A11y 83, SEO 83, Agentic 1/2** (Lighthouse 13.3, мобильный).

| Что делаем | Performance | Другие категории |
|---|---|---|
| Сейчас | **89** | A11y 83, SEO 83, Agentic 1/2 |
| Убрать лишний JS + отложить Jivo (TBT 390 → ~200 мс) | 92–94 | — |
| + критический CSS, preload, композит (LCP 2,3 → ~2,0 с) | 94–96 | — |
| + Brotli, годовой кэш | 95–97 | — |
| Картинки WebP + lazy | почти без роста балла | трафик −7 МБ, полевые LCP/CLS |
| SEO-правки (description + canonical) | — | SEO 83 → 100 |
| Доступность (link-name, alt, контраст, тач-цели) | — | A11y 95+, Agentic 2/2 |
| `llms.txt` (формат: H1 + ссылки) | — | Agentic 2/2 → 3/3 |

Потолок без переписывания фронтенда — **~97–98**: остаются TTFB без полного композита и 199 КБ блокирующего CSS. Выше — только через критический CSS по-настоящему (inline + async) и отказ от части JS Битрикса.

CLS уже **0** — это не проблема и не резерв. Главное — не сломать его, когда будете менять картинки и вставлять баннеры.

---

# Файлы-инструкции

Статус на 26.10.2026: ✅ — сделано, 🔧 — актуально, 🆕 — добавлено после редизайна.

## Сначала (даёт основной скачок)

1. **`29_audit_2026_10_26.md`** 🆕 — полный отчёт с замерами, что изменилось, что осталось.
2. **`02_webp_and_compress.md`** 🔧 — WebP/AVIF + сжатие (главный резерв).
3. **`08_convert_to_webp.sh`** 🔧 — массовая конвертация `/upload/`.
4. **`01_lazy_load_images.md`** 🔧 — `loading="lazy"` + размеры (обновлено под `index_2026`).
5. **`04_remove_unused_modules.md`** 🔧 — pull/protobuf/dexie/rest (427 КБ).

## Затем

6. **`05_composite_and_cache.md`** 🔧 — композит + годовой кэш.
7. **`20_brotli_http3.md`** 🔧 — Brotli (HTTP/2 и TLS 1.3 уже есть, HTTP/3 нет).
8. **`16_critical_css.md`** 🔧 — 199 КБ блокирующего CSS.
9. **`19_preload_and_iframe.md`** 🔧 — preload шрифтов и hero-фона.
10. **`06_fonts_display_swap.md`** ✅/🔧 — self-hosted уже сделан, остались preload, MIME, кэш.
11. **`07_defer_widgets.md`** 🔧 — отложить Jivo (megavenue больше нет).
12. **`30_seo_meta_a11y.md`** 🆕 — description, canonical, OG, H1, sitemap, доступность.
13. **`31_agentic_browsing.md`** 🆕 — Agentic Browsing 1/2: accessibility tree, CLS, `llms.txt`, WebMCP.

## Безопасность

13. **`09_security_and_ssl.md`** 🔧 — HSTS, CSP, Referrer-Policy, Permissions-Policy.
14. **`10_security_audit_and_headers.md`** 🔧 — аудит заголовков и служебных файлов.

## Уже неактуально

- **`03_minification.md`** ✅ — минификация и объединение включены, шаблонный бандл 1,2 КБ. Осталось только `protobuf.js` (это файл ядра, не шаблона) — см. `04_remove_unused_modules.md`.
- **`06_fonts_display_swap.md`** — в части Google Fonts: шрифты уже локальные. Инструкция оставлена как чек-лист по preload/MIME/кэшу.

---

## Инструменты для проверки

### 🚀 Производительность

| Инструмент | Что даёт | Как использовать |
|-----------|----------|-----------------|
| **PageSpeed Insights** | Lighthouse с серверов Google для моб. и десктоп. Оценки + рекомендации. | Прогнать после каждого изменения, следить за динамикой. |
| **GTmetrix** | Водопад запросов, видео загрузки, рекомендации. | Полезно для поиска узких мест: какие скрипты блокируют отрисовку, где задержки. |
| **WebPageTest** | Видео загрузки, водопад, выбор устройства/браузера/региона, 3G-симуляция. | Запускать из Европы, смотреть водопад и Suggested Metrics. |
| **Brotli Test** | Проверяет, включено ли сжатие Brotli. | Сейчас на nlb — нет, см. `20_brotli_http3.md`. |
| **HTTP/3 Check** | Проверяет поддержку HTTP/3 (QUIC). | HTTP/2 и TLS 1.3 есть, HTTP/3 — нет. |
| **Lighthouse CI** | Прогон Lighthouse в CI/CD на каждый коммит. | Не допускать регрессий производительности. |
| **Chrome DevTools → Coverage** | Сколько CSS/JS реально используется. | Проверить `bitrix.css` (75 КБ) и `main.css` (95 КБ). |
| **Chrome DevTools (Performance)** | Запись событий с точностью до мс. | Найти тяжёлые функции JS, долгую отрисовку. |
| **Webpack Bundle Analyzer** | Состав JS-бандла. | Если появится сборка — найти лишние зависимости. |

### 🛡️ Безопасность

| Инструмент | Что даёт | Как использовать |
|-----------|----------|-----------------|
| **Mozilla Observatory** | CSP, HSTS, CORS, Referrer-Policy и др. | Запустить первым делом. Цель — A+. |
| **SSL Labs** | SSL/TLS: протоколы, шифры, уязвимости, цепочка. | TLS 1.3 уже есть; проверить после правок. |
| **Security Headers** | Оценка HTTP-заголовков. | Сейчас HSTS/CSP/Referrer-Policy отсутствуют. |
| **OWASP ZAP** | SQLi, XSS, CSRF и др. | Раз в месяц пассивное сканирование. |
| **Snyk** | CVE в зависимостях. | Подключить в CI/CD. |
| **CSP Evaluator** | Слабые места CSP. | После включения Report-Only. |
| **Sucuri SiteCheck** | Малварь, блоклисты, редиректы. | Ежемесячно. |
| **urlscan.io** | Все запросы, поддомены, скрипты. | Найти неожиданные сторонние скрипты. |
| **VirusTotal** | Домен в 70+ антивирусах. | При подозрении на заражение. |
| **REDbot** | Cache-Control, ETag, Vary. | Сейчас `Vary: Accept-Encoding` на сжатой статике отсутствует. |

### 🔍 SEO и техническое состояние

| Инструмент | Что даёт | Как использовать |
|-----------|----------|-----------------|
| **Screaming Frog SEO Spider** | Битые ссылки, дубли мета-тегов, отсутствие H1, canonical. | Прогнать после правок структуры. |
| **Ahrefs Site Audit / Semrush** | 100+ параметров, sitemap, robots. | Проверить 37 051 URL из `sitemap_000.xml`. |
| **Google Search Console** | Core Web Vitals от реальных пользователей. | Раздел «Core Web Vitals» и «Мобильная удобность». |
| **W3C Validator** | Валидация HTML/CSS. | Ошибки ломают поведение в разных браузерах. |
| **Schema Validator** | JSON-LD/Microdata/OG. | На главной 2 блока JSON-LD — проверить. |
| **Lighthouse (Agentic Browsing)** | 1/2: accessibility tree, CLS, `llms.txt`, WebMCP. | `npx lighthouse https://nlb/ --only-categories=agentic-browsing` — см. `31_agentic_browsing.md`. |
| **Webhint** | Линтер безопасности/производительности/a11y/SEO. | В CI/CD или разово. |
| **JSON-LD Playground** | Визуализация структурированных данных. | Вставить JSON-LD с главной. |

### ♿ Доступность и UX

| Инструмент | Что даёт | Как использовать |
|-----------|----------|-----------------|
| **axe DevTools** | WCAG 2.1, конкретные элементы и исправления. | Расширение браузера. |
| **WAVE** | alt, контраст, aria прямо на странице. | Быстрая проверка. |
| **Lighthouse (Accessibility)** | Балл и рекомендации. | Сейчас 83. |
| **Color Contrast Checker** | Контраст текста и фона. | AA минимум, AAA — хорошо. |

### 📊 Мониторинг и нагрузка

| Инструмент | Что даёт | Как использовать |
|-----------|----------|-----------------|
| **k6** | Нагрузочное тестирование. | Перед релизом. |
| **New Relic / Datadog** | APM: SQL, внешние вызовы, PHP. | Найти узкие места бэкенда. |
| **UptimeRobot / StatusCake** | Доступность и TTFB из разных точек. | Добавить проверку времени ответа. |
| **Pingdom** | Скорость и аптайм по регионам. | Альтернатива UptimeRobot. |

### 🧪 Дополнительно

| Инструмент | Что даёт | Как использовать |
|-----------|----------|-----------------|
| **Can I Use** | Поддержка CSS/JS-фич. | Перед новыми фичами. |
| **WebPageTest (повторно)** | Сравнение «до» и «после». | Записать видео загрузки. |
| **Calibre** | Мониторинг Core Web Vitals. | Бесплатно для 1 сайта. |
| **Yellow Lab Tools** | Детальный анализ JS. | Дубли кода, лишние полифиллы. |
| **Hardenize** | DNS, SPF, DMARC, TLS. | Комплексный чек инфраструктуры. |
| **Wappalyzer** | Технологии сайта. | Быстрый тех-анализ. |
| **Burp Suite Community** | Перехват трафика, отладка API. | Пройтись по формам и API. |
| **WhatWeb** | CMS, библиотеки, версии из терминала. | `whatweb nlb`. |
| **Sitebulb** | SEO-аудит с визуализациями. | Раз в месяц. |

---

## 💡 Стратегия проверок

1. **Сначала** — Mozilla Observatory + SSL Labs: HSTS/CSP отсутствуют, TLS в порядке.
2. **Затем** — Lighthouse/PSI с эмуляцией 4G: главный резерв — картинки.
3. **Контроль** — UptimeRobot + Snyk.
4. **Периодически** — Screaming Frog (sitemap 2018 года!), axe DevTools, OWASP ZAP.
5. **После изменений** — PageSpeed Insights и повторные замеры по методике из `29_audit_2026_10_26.md`.

---

Для каждого пункта: прочитайте файл, скопируйте код на сервер, примените. Все замеры и «до/после» — в `29_audit_2026_10_26.md`, история изменений репозитория — в `CHANGELOG.md`.
