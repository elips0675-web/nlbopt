# Preload / Resource Hints / Lazy iframe

## Preload критических ресурсов

Загружает ресурсы с самым высоким приоритетом, до того как парсер HTML до них дойдёт.

```html
<!-- Шрифты (обязательно crossorigin!) -->
<link rel="preload" href="/fonts/OpenSans-Regular.woff2" as="font" type="font/woff2" crossorigin>

<!-- Hero-изображение первого экрана -->
<link rel="preload" href="/upload/hero.webp" as="image">

<!-- Critical CSS (если не inline) -->
<link rel="preload" href="/bitrix/templates/.default/critical.css" as="style">

<!-- JS, который нужен сразу (редко) -->
<link rel="preload" href="/bitrix/js/main/core/core.js" as="script">
```

## Resource Hints

```html
<!-- Предварительное подключение к CDN/API -->
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link rel="preconnect" href="https://api.jivosite.com">

<!-- DNS-prefetch для старых браузеров (fallback) -->
<link rel="dns-prefetch" href="https://cdn.cloudflare.net">

<!-- Prefetch — следующая страница, которую пользователь вероятно откроет -->
<link rel="prefetch" href="/catalog/" as="document">

<!-- Prerender — полная предзагрузка страницы -->
<link rel="prerender" href="/catalog/popular/">
```

### Когда использовать

| Hint | Когда |
|------|-------|
| `preload` | Ресурс нужен на текущей странице и критичен |
| `preconnect` | Будет запрос на внешний домен |
| `dns-prefetch` | Fallback для preconnect |
| `prefetch` | Ресурс может понадобиться на следующей странице |
| `prerender` | Пользователь почти наверняка перейдёт на эту страницу |

## Lazy load для iframe

### YouTube, карты, виджеты

```html
<iframe src="about:blank"
        data-src="https://www.youtube.com/embed/VIDEO_ID"
        loading="lazy"
        width="560" height="315"
        frameborder="0"
        class="lazy-iframe"></iframe>
```

### Через IntersectionObserver

```javascript
document.addEventListener('DOMContentLoaded', function() {
    var lazyIframes = document.querySelectorAll('iframe.lazy-iframe');
    if ('IntersectionObserver' in window) {
        var observer = new IntersectionObserver(function(entries) {
            entries.forEach(function(entry) {
                if (entry.isIntersecting) {
                    var iframe = entry.target;
                    iframe.src = iframe.dataset.src;
                    observer.unobserve(iframe);
                }
            });
        });
        lazyIframes.forEach(function(iframe) {
            observer.observe(iframe);
        });
    }
});
```

### Проверка

DevTools → Network — iframe загружается только при скролле к нему.
