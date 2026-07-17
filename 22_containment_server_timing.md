# CSS containment + Server-Timing

## CSS containment

Ограничивает область перерисовки (reflow) для каждого компонента.

```css
/* Каждая карточка товара — изолированный контейнер */
.product-card {
    contain: layout style paint;
}

/* Сайдбар */
.sidebar {
    contain: layout paint;
}

/* Футер — не влияет на остальную страницу */
.footer {
    contain: layout style paint;
}
```

### Значения

| Значение | Что делает |
|----------|------------|
| `layout` | Внутренний layout не влияет на внешний |
| `style` | Счётчики/стили не выходят за контейнер |
| `paint` | Обрезает видимую область (как overflow:hidden) |
| `size` | Элемент занимает указанные width/height |
| `content` | `layout style paint` (без size) |
| `strict` | `layout style paint size` |

### Проверка

DevTools → Performance → запилить профиль загрузки — меньше перерисовок.

## Server-Timing

Позволяет увидеть узкие места через DevTools → Network → Timing.

### Через init.php

```php
AddEventHandler("main", "OnEpilog", function() {
    global $DB;
    $dbTime = $DB->GetQueryStatistics('TIME');
    $phpTime = (microtime(true) - $_SERVER["REQUEST_TIME_FLOAT"]) * 1000;
    $compositeHit = defined("BX_COMPOSITE_HIT") && BX_COMPOSITE_HIT ? "hit" : "miss";

    header("Server-Timing: " .
        "db;dur={$dbTime}, " .
        "php;dur={$phpTime}, " .
        "composite;desc={$compositeHit}"
    );
});
```

### Что можно измерять

| Метрика | Где брать |
|---------|-----------|
| db | `$DB->GetQueryStatistics('TIME')` |
| php | `microtime(true) - REQUEST_TIME_FLOAT` |
| composite | `BX_COMPOSITE_HIT` |
| mem | `memory_get_peak_usage()` |
| queries | `$DB->GetQueryStatistics('COUNT')` |

### Проверка

DevTools → Network → выберите запрос → Timing → ServerTiming.

Или:
```bash
curl -I -w '%{header_json}' https://site.ru | grep server-timing
```
