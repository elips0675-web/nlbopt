# 7. Отложенная загрузка сторонних виджетов (Jivo)

**Актуально на 26.10.2026.** megavenue.by с сайта убран — от старой версии инструкции осталась только часть про Jivo.

## Что грузится сейчас

```html
<script src="https://code-eu1.jivosite.com/widget/TnYiZsuEsx"
        async data-skip-moving="true"></script>
```

Скрипт стоит в `<head>` (атрибут `data-skip-moving` заставляет Битрикс не переносить его вниз). В результате на каждой странице открывается **8 запросов на 3 домена**: `code-eu1.jivosite.com`, `code.jivosite.com`, `node-sb1-az2-23.jivosite.com`.

Проблема не в весе (он умеренный), а в том, что виджет стартует одновременно с LCP-ресурсами и занимает main thread у 100% посетителей, из которых чат открывают единицы.

## Решение: грузить по взаимодействию или в idle

Замените тег в шаблоне (обычно `/local/templates/index_2026/header.php` или подключаемый файл виджета) на загрузчик в конце `<body>`:

```html
<script>
(function () {
    var WIDGET = 'https://code-eu1.jivosite.com/widget/TnYiZsuEsx';
    var loaded = false;

    function loadJivo() {
        if (loaded) return;
        loaded = true;
        var s = document.createElement('script');
        s.src = WIDGET;
        s.async = true;
        document.body.appendChild(s);
    }

    function schedule() {
        if ('requestIdleCallback' in window) {
            requestIdleCallback(loadJivo, { timeout: 6000 });
        } else {
            setTimeout(loadJivo, 4000);
        }
    }

    if (document.readyState === 'complete') {
        schedule();
    } else {
        window.addEventListener('load', schedule, { once: true });
    }

    // Если пользователь начал взаимодействовать раньше — грузим сразу
    ['scroll', 'click', 'touchstart', 'keydown'].forEach(function (evt) {
        window.addEventListener(evt, loadJivo, { once: true, passive: true });
    });
})();
</script>
```

Что это даёт:

- до первого скролла/клика или до `load` + idle сторонних запросов нет;
- если человек идёт в чат — виджет загрузится по первому же действию;
- LCP и TBT не конкурируют с чатом.

## Если чат должен быть виден сразу

Компромисс: оставить кнопку-заглушку (локальную), а сам Jivo грузить по клику на неё:

```html
<button type="button" class="chat-launcher" onclick="window.__loadJivo()">
    Написать в чат
</button>
<script>
window.__loadJivo = function () {
    if (window.__jivoLoaded) return;
    window.__jivoLoaded = true;
    var s = document.createElement('script');
    s.src = 'https://code-eu1.jivosite.com/widget/TnYiZsuEsx';
    s.async = true;
    document.body.appendChild(s);
    setTimeout(function () {
        if (window.jivo_api && window.jivo_api.open) window.jivo_api.open();
    }, 1500);
};
</script>
```

## Чего не делать

- Не оставляйте `data-skip-moving="true"` на новом загрузчике — он снова затащит код в `<head>`.
- Не используйте `defer`/`async` на самом теге Jivo: это не откладывает загрузку, а только не блокирует парсер.
- Не грузите виджет в `DOMContentLoaded` — это тот же момент, когда стартуют картинки первого экрана.

## Проверка

1. DevTools → Network, фильтр `jivosite`: при первой загрузке — **0 запросов**.
2. Проскроллить/кликнуть → появляются запросы, чат открывается.
3. Lighthouse TBT до/после — должен упасть.
4. Проверить, что кнопка чата доступна с клавиатуры (a11y): у Jivo она появляется после загрузки.

## Ожидаемый эффект

- −8 сторонних запросов на старте;
- −3 DNS/TLS-соединения;
- меньше конкуренции за main thread — особенно заметно на мобиле;
- Jivo держит WebSocket, который мешает bfcache. Отложенная загрузка снимает вторую причину отказа bfcache (первая — `no-store` на HTML, см. `05_composite_and_cache.md`).
