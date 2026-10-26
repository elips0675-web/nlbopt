# 4. Отключить лишние модули (pull, protobuf, dexie, rest.client)

**Актуально на 26.10.2026.** В новом шаблоне эти скрипты остались и по-прежнему грузятся на каждой публичной странице.

## Что грузится

| Файл | Вес (decoded) | Зачем |
|---|---|---|
| `/bitrix/js/pull/protobuf/protobuf.js` | **268 КБ** (8 712 строк, не минифицирован) | сериализация для Push & Pull |
| `/bitrix/js/ui/dexie/dist/dexie.bundle.min.js` | 100 КБ | IndexedDB для Pull |
| `/bitrix/js/pull/client/pull.client.min.js` | 49 КБ | чат/уведомления в реальном времени |
| `/bitrix/js/rest/client/rest.client.min.js` | 9 КБ | REST-клиент |
| **Итого** | **426 КБ decoded / ~100 КБ gzip** | на публичке не нужны |

Важно: `core.min.js` (177 КБ) и `baseline.bundle.min.js` (4 КБ) — **не трогать**, это ядро.

Lighthouse 13.3 подтверждает цифрами: **Reduce unused JavaScript — 190 КиБ**, **Minify JavaScript — 75 КиБ**, main-thread work — **3,0 с**, 4 long task. Это ровно этот стек: 426 КБ decoded, из них `protobuf.js` 268 КБ вообще не минифицирован. Отсюда же TBT 390 мс.

Проверка, что они всё ещё подключены:

```bash
curl -s https://nlb.by/ | grep -o 'src="[^"]*\(pull\|protobuf\|dexie\|rest\.client\)[^"]*"'
```

## Способ 1: убрать из HTML (быстро, обратимо)

Скрипты подключены в `<head>` шаблона `index_2026` с параметрами версии (`?17865184254439`), поэтому старую регулярку из первой версии инструкции использовать нельзя — она не учитывает query-строку и атрибуты после `src`.

```php
// /local/php_interface/init.php
AddEventHandler("main", "OnEndBufferContent", function (&$content) {
    if (defined("ADMIN_SECTION") || defined("BX_AJAX")) {
        return;
    }

    $patterns = [
        '#<script[^>]*\bsrc="[^"]*/pull/protobuf/(protobuf|model)[^"]*"[^>]*>\s*</script>#i',
        '#<script[^>]*\bsrc="[^"]*/pull/client/pull\.client[^"]*"[^>]*>\s*</script>#i',
        '#<script[^>]*\bsrc="[^"]*/ui/dexie/dist/dexie\.bundle[^"]*"[^>]*>\s*</script>#i',
        '#<script[^>]*\bsrc="[^"]*/rest/client/rest\.client[^"]*"[^>]*>\s*</script>#i',
    ];

    $content = preg_replace($patterns, '', $content);
});
```

Это убирает теги из выдачи, но модуль Pull продолжает инициализироваться на сервере и может добавлять inline-код. Если после этого в консоли появляются ошибки `BX.PULL is not defined` — переходите к способу 2.

## Способ 2: отключить модуль Pull (надёжно)

**Настройки → Настройки продукта → Модули → Push & Pull** → деактивировать, если на сайте нет:

- онлайн-чата на базе Битрикса (Jivo — это отдельный виджет, от Pull не зависит);
- живых уведомлений;
- «живого» поиска/комментариев, завязанных на Pull.

Затем очистить кэш. После деактивации `protobuf`, `dexie` и `pull.client` исчезают из выдачи сами.

## Способ 3: точечно в шаблоне

В `/local/templates/index_2026/header.php` найдите `\Bitrix\Main\Page\Asset::getInstance()` / `SetAdditionalJS` и не подключайте эти файлы на публичных страницах. Минус: при обновлении шаблона правку легко потерять.

## Проверка после удаления

1. `curl -s https://nlb.by/ | grep -c protobuf` → `0`.
2. Открыть сайт, DevTools → Console: не должно быть ошибок `BX.PULL`, `Dexie`, `protobuf`.
3. Проверить: форма входа, поиск, cookie-баннер, меню, слайдер, переключатель «Слабовидящим».
4. `/bitrix/admin/` — должен открываться (403/логин), админка не должна зависеть от публичного Pull.
5. Замерить: JS было 683 КБ decoded → должно стать ~256 КБ.

## Ожидаемый эффект

- −426 КБ decoded, −100 КБ transfer;
- Lighthouse: **−190 КиБ unused JS**, ещё **−75 КиБ** после минификации `protobuf.js`;
- main-thread work 3,0 с → заметно меньше, TBT 390 → ~200 мс;
- минус 4 запроса.

Если Pull нужен для чата — оставляйте, но тогда хотя бы минифицируйте `protobuf.js` и грузите его лениво после взаимодействия.
