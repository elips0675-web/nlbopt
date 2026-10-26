# Changelog

## 26.10.2026 — диагностика Lighthouse: 8,8 МБ, unused JS, bfcache

Второй прогон Lighthouse 13.3 дал детальные insights и diagnostics. Внёс их в документы и уточнил приоритеты: картинки подтверждены как **−5,1 МБ** доставки, а главный резерв балла — JS (unused 190 КиБ, minify 75 КиБ, main-thread 3,0 с).

### Обновлено

- `README.md` — таблица «Диагностика Lighthouse» (16 пунктов), точные оценки в приоритетах, раздел про bfcache и non-composited animations, вес 8 804 КиБ.
- `29_audit_2026_10_26.md` — раздел диагностики с расшифровкой каждого пункта, включая bfcache, long tasks и LCP request discovery.
- `01_lazy_load_images.md` — Lighthouse всё ещё ругается на отсутствие `width`/`height`, даже при CLS 0.
- `04_remove_unused_modules.md` — подтверждение: −190 КиБ unused JS, −75 КиБ minify, main-thread 3,0 с, 4 long task.
- `05_composite_and_cache.md` — новый раздел про bfcache: `no-store` + WebSocket/unload, как проверить и починить; −139 КиБ cache lifetimes.
- `07_defer_widgets.md` — Jivo держит WebSocket и мешает bfcache.
- `16_critical_css.md` — render-blocking −170 мс, unused CSS −15 КиБ, minify CSS −6 КиБ.
- `19_preload_and_iframe.md` — LCP request discovery и network dependency tree.
- `22_containment_server_timing.md` — non-composited animations: только `transform`/`opacity`.
- `12_full_audit_checklist.md`, `14_audit_checklist_with_references.md` — чекбоксы bfcache, анимаций, `width`/`height`; итого 90 пунктов.
- `02_webp_and_compress.md`, `11_performance_audit_checklist.md` — добавлена оценка Lighthouse 5,1 МБ и метрики 13.3.
- `15_whats_not_covered.md` — помечен как исторический список: темы 15–28 уже реализованы, актуальные ссылки в таблице.
- `CHANGELOG.md` — эта запись.

---

## 26.10.2026 — Lighthouse 13.3: реальные оценки и Agentic Browsing

Прогон в Chrome DevTools (Lighthouse 13.3, эмуляция Moto G / Slow 4G): **Performance 89, Accessibility 83, Best Practices 100, SEO 83, Agentic Browsing 1/2**; LCP 2,3 с, FCP 1,4 с, TBT 390 мс, CLS 0, SI 1,5 с. Пересобрал приоритеты под эти цифры.

### Добавлено

- `31_agentic_browsing.md` — как считается дробь, почему 1/2 (accessibility tree), формат `llms.txt` с готовым файлом для nlb, починка 403 на `.txt` в Apache/nginx, WebMCP и границы пользы.

### Обновлено

- `README.md` — отдельная таблица Lighthouse 13.3 (мобильный), объяснение, почему 89 при 8 МБ картинок, новый порядок приоритетов (TBT и JS — первыми, картинки — трафик, а не балл), новый прогноз, ссылка на `31`.
- `29_audit_2026_10_26.md` — раздел Lighthouse 13.3 с LCP/FCP/TBT/CLS/SI, объяснение SEO 67 → 83 (версия Lighthouse, а не изменения сайта), Agentic 1/2, переписан прогноз.
- `30_seo_meta_a11y.md` — SEO 83 = 10 из 12, валят только `meta-description` и `canonical`; добавлен раздел про Agentic и `llms.txt`; приоритеты переставлены.
- `01_lazy_load_images.md` — CLS уже 0: `lazy` остаётся ради трафика, `width`/`height` — страховка, а не срочный фикс.
- `12_full_audit_checklist.md`, `14_audit_checklist_with_references.md` — блок Agentic Browsing, `llms.txt`, статус 1/2, итого 88 пунктов.
- `CHANGELOG.md` — эта запись.

### Что изменилось в выводах

- **Performance 89 не отменяет работу с картинками**, но и не двигается ими: балл считается по LCP/TBT/CLS. 8 МБ — это трафик и полевые Core Web Vitals. Главный резерв балла — **TBT 390 мс**, то есть лишний JS.
- **SEO 67 → 83** — не улучшение сайта, а разница версий Lighthouse. Сравнивать эти числа нельзя; внутри 13.3 SEO держат два аудита: description и canonical.
- **CLS 0** — размеры картинок больше не приоритет, но их стоит добавить как защиту от регрессий.
- **Agentic 1/2** — провалено дерево доступности (3 ссылки без имени), CLS проходит, `llms.txt` в знаменатель не попал из-за 403 на `.txt`.

---

## 26.10.2026 — ревизия после редизайна nlb.by

Сайт переехал на новый шаблон `/local/templates/index_2026/`. Перепроверил всё заново (curl + Resource Timing + Lighthouse) и обновил репозиторий под фактическое состояние.

### Добавлено

- `29_audit_2026_10_26.md` — полный отчёт: методика, замеры главной и «Новостей», список всех картинок, JS/CSS, заголовки, sitemap, прогноз.
- `30_seo_meta_a11y.md` — SEO и доступность: дублирующийся хост, meta description, canonical, OG, два H1, alt, sitemap 2018 года, контраст и тач-цели.
- `CHANGELOG.md` — этот файл.

### Обновлено

- `README.md` — новые цифры (8,4 МБ, 95% веса — картинки, TTFB 471 мс, FCP 1 056 мс, SEO 67, a11y 83), статус «сделано / осталось», новый порядок приоритетов.
- `01_lazy_load_images.md` — под шаблон `index_2026`: 37 картинок, 0 lazy, 11 ниже сгиба; рабочий хук с `decoding="async"`, правила для LCP.
- `02_webp_and_compress.md` — актуальные тяжёлые файлы (`OON.png` 4,2 МБ и др.), корректный nginx `map` по `Accept` вместо ошибочного `try_files $uri.webp $uri`, AVIF, ресайз.
- `08_convert_to_webp.sh` — теперь создаёт суффиксные копии `photo.jpg.webp` (как ожидает nginx), пропускает мелочь, не оставляет WebP больше оригинала.
- `03_minification.md` — отмечено как сделанное: шаблонный бандл 826 КБ → 1,2 КБ; остался `protobuf.js` 268 КБ.
- `04_remove_unused_modules.md` — точные размеры (426 КБ decoded), регулярки с учётом `?version`, порядок проверки после удаления Pull.
- `05_composite_and_cache.md` — факты: 30 дней, без `immutable`, HTML `no-store`, композит выключен; конфиг на год + `Vary`.
- `06_fonts_display_swap.md` — переписан: Google Fonts больше нет, шрифты self-hosted; остались preload, MIME `application/force-download`, 41 `@font-face`, кэш.
- `07_defer_widgets.md` — megavenue удалён, остался Jivo (`TnYiZsuEsx`, 3 домена, 8 запросов); загрузчик по взаимодействию/idle.
- `09_security_and_ssl.md` — таблица «что есть / чего нет», HSTS поэтапно, CSP Report-Only под Jivo, `SameSite`, скрытие `X-Powered-CMS`.
- `16_critical_css.md` — 199 КБ блокирующего CSS, FCP 1,05 с, конкретные файлы `index_2026`, `bitrix.css` 75 КБ.
- `19_preload_and_iframe.md` — ровно 3 preload: hero-фон и два кириллических WOFF2; `fetchpriority`, правила для iframe.
- `20_brotli_http3.md` — факты: HTTP/2 и TLS 1.3 работают, Brotli и HTTP/3 нет; проверки через ALPN, а не через curl без h2.
- `11_performance_audit_checklist.md`, `12_full_audit_checklist.md`, `14_audit_checklist_with_references.md`, `15_whats_not_covered.md` — убраны устаревшие пункты про Google Fonts/megavenue, добавлены ссылки на новые замеры.

### Что показал аудит (кратко)

- Стало лучше: минификация, self-hosted шрифты, кэш 30 дней, HTTP/2, TLS 1.3, TTFB 0,47 с, закрытые служебные пути.
- Осталось: 7,97 МБ картинок (один PNG — 4,2 МБ), 0 lazy, 0 WebP, 426 КБ лишнего JS, только gzip, HTML `no-store`, 199 КБ блокирующего CSS, SEO 67, sitemap 2018 года, нет HSTS/CSP/Referrer-Policy.

---

## Ранее (до редизайна)

Первая версия репозитория: разбор главной на старом шаблоне — 46 баллов Lighthouse, 92 изображения, 826 КБ шаблонного JS, Google Fonts, megavenue.by. Инструкции 01–28.
