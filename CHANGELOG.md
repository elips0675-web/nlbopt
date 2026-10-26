# Changelog

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
