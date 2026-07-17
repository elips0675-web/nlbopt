# 7. Отложенная загрузка Jivosite и megavenue.by

## Вставьте этот код вместо обычного подключения виджетов

```html
<script>
// Отложенная загрузка сторонних виджетов
(function() {
    function loadScript(url, callback) {
        var script = document.createElement('script');
        script.src = url;
        script.async = true;
        script.onload = callback || function(){};
        document.body.appendChild(script);
    }

    // Загружаем после загрузки страницы + 3 сек или по первому взаимодействию
    function loadWidgets() {
        // Jivosite
        loadScript('//code.jivosite.com/script/widget/ВАШ_ИД');
        
        // Megavenue
        loadScript('//megavenue.by/путь/к/скрипту');
    }

    // Загрузка по первому взаимодействию или через 5 секунд
    var loaded = false;
    function initOnInteraction() {
        if (loaded) return;
        loaded = true;
        loadWidgets();
        document.removeEventListener('scroll', initOnInteraction);
        document.removeEventListener('click', initOnInteraction);
        document.removeEventListener('touchstart', initOnInteraction);
    }

    // Таймаут — если пользователь бездействует
    setTimeout(initOnInteraction, 5000);

    // По первому взаимодействию
    document.addEventListener('scroll', initOnInteraction, { once: true });
    document.addEventListener('click', initOnInteraction, { once: true });
    document.addEventListener('touchstart', initOnInteraction, { once: true });
})();
</script>
```

**ВАЖНО:** Замените `ВАШ_ИД` на реальный ID Jivosite и URL для megavenue.by.

## Или через requestIdleCallback (современный подход)

```html
<script>
(function() {
    function loadJivosite() {
        var s = document.createElement('script');
        s.src = '//code.jivosite.com/script/widget/ВАШ_ИД';
        s.async = true;
        document.body.appendChild(s);
    }

    function loadMegavenue() {
        var s = document.createElement('script');
        s.src = '//megavenue.by/путь/к/скрипту';
        s.async = true;
        document.body.appendChild(s);
    }

    if ('requestIdleCallback' in window) {
        requestIdleCallback(function() {
            loadJivosite();
            loadMegavenue();
        }, { timeout: 5000 });
    } else {
        // Fallback для старых браузеров
        setTimeout(function() {
            loadJivosite();
            loadMegavenue();
        }, 3000);
    }
})();
</script>
```

## Проверка

1. Откройте DevTools → Network
2. Обновите страницу — Jivosite и megavenue не должны грузиться сразу
3. Через 5 сек или после клика/скролла — должны появиться в списке запросов
4. Проверьте, что виджеты работают (чат открывается)
