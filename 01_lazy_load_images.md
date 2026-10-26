# 1. `loading="lazy"` для изображений

**Актуально на 26.10.2026** (шаблон `/local/templates/index_2026/`).

Зачем это, если Lighthouse Performance уже 89: `lazy` не поднимает балл (он считается по LCP/TBT/CLS), но снимает с первого экрана 5–6 МБ из 8. Это трафик посетителя, мобильный интернет и полевые Core Web Vitals. Балл баллом, а 8 МБ на главной остаются.

## Что сейчас

| Страница | `<img>` | С `loading="lazy"` | Ниже первого экрана |
|---|---|---|---|
| Главная | 37 | **0** | 11 |
| `/content/news/` | 22 | **0** | 17 |

Ни одного `srcset`, ни одного `width`/`height`. CLS при этом **0** — шаблон резервирует место через CSS, так что это не срочно. Но размеры стоит добавить как страховку: при смене шаблона или добавлении баннеров сдвиги вернутся. Первые две картинки в DOM — герб и флаг в шапке (`/gerb_big.jpg`, `/flag_big.jpg`), они выше сгиба и трогать их не нужно.

## Правило

- Первый экран (шапка, hero, первая карточка) — **без** `lazy`, при необходимости `fetchpriority="high"`.
- Всё, что ниже, — `loading="lazy" decoding="async"`.
- Всем — `width` и `height` (или CSS `aspect-ratio`): сейчас CLS 0, но это защита от сдвигов при изменении шаблона.

## Вариант A: правка шаблонов компонентов (правильный)

Картинки на главной выводятся компонентами в `/local/templates/index_2026/components/`. Найдите места вывода:

```bash
grep -rn "<img" /local/templates/index_2026/components/ | grep -v ".bak"
```

И добавьте атрибуты:

```php
<img src="<?= $arItem["PREVIEW_PICTURE"]["SRC"] ?>"
     alt="<?= htmlspecialchars($arItem["NAME"]) ?>"
     width="<?= $arItem["PREVIEW_PICTURE"]["WIDTH"] ?>"
     height="<?= $arItem["PREVIEW_PICTURE"]["HEIGHT"] ?>"
     loading="lazy"
     decoding="async">
```

Для карточки, которая может оказаться на первом экране (первая в списке), `lazy` не ставить:

```php
<? $isFirst = ($arResult["NAV_RESULT"]->NavNum && $arItem["__FIRST"]); ?>
<img ... <?= $isFirst ? 'fetchpriority="high"' : 'loading="lazy" decoding="async"' ?>>
```

## Вариант B: хук `OnEndBufferContent` (быстро, без правки компонентов)

Работает для всего сайта сразу. Пропускает первые 2 картинки (герб/флаг), не трогает уже размеченные и админку.

```php
// /local/php_interface/init.php
AddEventHandler("main", "OnEndBufferContent", function (&$content) {
    if (defined("ADMIN_SECTION") || defined("BX_AJAX")) {
        return;
    }
    if (stripos($content, "</body>") === false) {
        return;
    }

    $count = 0;
    $content = preg_replace_callback(
        '/<img\b[^>]*>/i',
        function ($m) use (&$count) {
            $count++;
            $tag = $m[0];

            // Первые 2 изображения — шапка (герб, флаг), они выше сгиба
            if ($count <= 2) {
                return $tag;
            }
            // Уже размечено — не дублируем
            if (stripos($tag, 'loading=') !== false) {
                return $tag;
            }

            $tag = preg_replace('/\s*\/?>$/', '', $tag);
            return $tag . ' loading="lazy" decoding="async">';
        },
        $content
    );
});
```

Проверка после применения:

```bash
curl -s https://nlb.by/ | grep -c 'loading="lazy"'   # ожидаем ~35
```

## Чего не делать

- **Не ставить `lazy` на LCP-картинку.** На главной LCP — hero-блок (фон `hero-bg-side-2.jpg` + заголовок). Если сделать фон ленивым, LCP ухудшится.
- **Не ставить `lazy` на логотип в шапке.**
- **Не заменять `width`/`height` на `lazy`.** Это разные задачи: lazy экономит трафик, размеры — устойчивость вёрстки (сейчас CLS 0, но так надёжнее).

## Фоновые изображения

`hero-bg-side-2.jpg` (194 КБ) задан через CSS `background-image`. Лениво такие не грузятся, но их нужно:

1. сжать и перевести в WebP/AVIF (~40–60 КБ);
2. добавить `<link rel="preload" as="image" href="...webp" type="image/webp">` в `<head>` — см. `19_preload_and_iframe.md`.

## Проверка

```bash
# сколько картинок и сколько ленивых
curl -s https://nlb.by/ | grep -o '<img' | wc -l
curl -s https://nlb.by/ | grep -c 'loading="lazy"'

# размеры
curl -s https://nlb.by/ | grep -c 'width=' 
```

DevTools → Network: при первой загрузке картинки ниже сгиба не должны появляться, пока не проскроллите.
