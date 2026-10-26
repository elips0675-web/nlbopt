# 19. Preload / Resource Hints / lazy iframe

**Актуально на 26.10.2026.** Сейчас в HTML главной **ни одного** `preload`, `preconnect` или `dns-prefetch`. Iframe на главной нет.

Lighthouse 13.3 отдельно отмечает **LCP request discovery** и **Network dependency tree**: LCP-фон задан в CSS, поэтому браузер узнаёт о нём только после разбора `main.css` (HTML → CSS → фон/шрифты). Preload ниже убирает эту задержку и закрывает оба замечания.

## Что стоит preload-ить на nlb.by

Только три ресурса. Больше — вредно: preload конкурирует с LCP за приоритет.

### 1. Hero-фон (LCP-ресурс)

```html
<link rel="preload" as="image"
      href="/local/templates/index_2026/assets/hero-bg-side-2.jpg"
      fetchpriority="high">
```

Сейчас это CSS `background-image` на 194 КБ, и браузер узнаёт о нём только после разбора `main.css` — то есть после FCP. Preload убирает эту задержку.

После конвертации в WebP/AVIF (см. `02_webp_and_compress.md`) добавьте `type`:

```html
<link rel="preload" as="image" type="image/webp"
      href="/local/templates/index_2026/assets/hero-bg-side-2.webp"
      fetchpriority="high">
```

Если позже сделаете адаптивный hero:

```html
<link rel="preload" as="image" type="image/webp"
      imagesrcset="/assets/hero-640.webp 640w, /assets/hero-1280.webp 1280w"
      imagesizes="100vw" fetchpriority="high">
```

### 2. Два кириллических шрифта

```html
<link rel="preload"
      href="/local/templates/index_2026/assets/fonts/raleway/1Ptug8zYS_SKggPNyCkIT5lu.woff2"
      as="font" type="font/woff2" crossorigin>
<link rel="preload"
      href="/local/templates/index_2026/assets/fonts/lora/0QIvMX1D_JOuMw77I-NP.woff2"
      as="font" type="font/woff2" crossorigin>
```

`crossorigin` обязателен даже для своего домена — иначе браузер скачает файл дважды.

Латиницу (47 + 37 КБ) не preload-ить: она нужна только для цифр и латинских имён.

## Что НЕ preload-ить

- `main.css`, `bitrix.css` — они уже блокирующие, preload ничего не ускорит.
- `core.min.js` — 177 КБ, выполняется не сразу; preload только отнимет приоритет у hero.
- Jivo — если внедрите отложенную загрузку (`07_defer_widgets.md`), preconnect к `jivosite.com` не нужен. Если оставляете чат сразу — тогда `preconnect` к `code-eu1.jivosite.com` имеет смысл.
- Картинки карточек — они должны быть `lazy`, а не preload.

## Resource Hints: что имеет смысл

```html
<!-- Если Jivo остаётся мгновенным -->
<link rel="preconnect" href="https://code-eu1.jivosite.com" crossorigin>
<link rel="dns-prefetch" href="https://code.jivosite.com">

<!-- Prefetch следующей вероятной страницы (по желанию, аккуратно с трафиком) -->
<link rel="prefetch" href="/content/events/" as="document">
```

Не добавляйте `prefetch`/`prerender` массово: на мобильном это лишний трафик.

## Lazy iframe

На главной iframe нет, но шаблон используется и на страницах с видео/картами. Правило:

```html
<iframe src="about:blank"
        data-src="https://www.youtube.com/embed/VIDEO_ID"
        loading="lazy"
        width="560" height="315"
        title="Название видео"
        frameborder="0"></iframe>
```

`loading="lazy"` поддерживается всеми актуальными браузерами; для старых — IntersectionObserver:

```javascript
document.querySelectorAll('iframe[data-src]').forEach(function (frame) {
    if (!('IntersectionObserver' in window)) {
        frame.src = frame.dataset.src;
        return;
    }
    var io = new IntersectionObserver(function (entries) {
        entries.forEach(function (entry) {
            if (!entry.isIntersecting) return;
            entry.target.src = entry.target.dataset.src;
            io.unobserve(entry.target);
        });
    }, { rootMargin: '200px' });
    io.observe(frame);
});
```

`title` у iframe обязателен для доступности (Lighthouse a11y это проверяет).

## Проверка

```bash
curl -s https://nlb.by/ | grep -c 'rel="preload"'      # ожидаем 3
curl -s https://nlb.by/ | grep -o 'hero-bg[^"]*'       # hero preload есть
```

DevTools → Network: hero и шрифты должны стартовать в первых строках, до `main.css`.
