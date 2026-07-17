# Session security / SRI / CSP strict-dynamic

## Session security

### Настройки PHP для сессий

```php
// init.php
ini_set('session.cookie_httponly', 1);       // JS не читает
ini_set('session.cookie_secure', 1);          // только HTTPS
ini_set('session.cookie_samesite', 'Lax');    // защита от CSRF
ini_set('session.gc_maxlifetime', 1800);      // 30 минут
ini_set('session.use_strict_mode', 1);        // не принимать неподписанные ID
ini_set('session.sid_length', 128);           // длина ID
ini_set('session.sid_bits_per_character', 6); // энтропия
ini_set('session.use_only_cookies', 1);       // только cookies
ini_set('session.cookie_path', '/');
ini_set('session.cookie_domain', '.site.ru');
```

### Битрикс — настройки сессий

Админка → Настройки → Главный модуль → Сессии:

```
Тип хранения: memcache / redis (не файлы!)
Время жизни: 1800
Защита от XSS: Да
```

### Проверка

DevTools → Application → Cookies → PHPSESSID:

| Флаг | Должен быть |
|------|-------------|
| HttpOnly | ✓ |
| Secure | ✓ |
| SameSite | Lax или Strict |
| Domain | .site.ru |
| Path | / |

## Subresource Integrity (SRI)

Защита от компрометации CDN: браузер не загрузит скрипт, если хеш не совпадает.

### Генерация хеша

```bash
# Для файла на CDN
curl -s https://cdn.site.ru/js/main.js | openssl dgst -sha384 -binary | openssl base64 -A

# Или через инструмент
npx sri-toolbox https://cdn.site.ru/js/main.js
```

### Добавление в HTML

```html
<script src="https://cdn.site.ru/js/main.js"
        integrity="sha384-ABC123..."
        crossorigin="anonymous"></script>
```

### SRI для Битрикс

Через `init.php`:

```php
AddEventHandler("main", "OnEndBufferContent", function(&$content) {
    $content = str_replace(
        'src="/bitrix/js/main/core/core.js"',
        'src="/bitrix/js/main/core/core.js" integrity="sha384-xyz..." crossorigin="anonymous"',
        $content
    );
});
```

### Проверка

DevTools → Console — ошибка SRI, если хеш не совпадает.

## CSP strict-dynamic

Отказ от белого списка доменов в пользу доверия по цепочке.

### Базовый CSP

```
Content-Security-Policy:
  default-src 'self';
  script-src 'strict-dynamic' 'sha256-abc...' 'sha256-def...';
  object-src 'none';
  base-uri 'none';
```

### Как работает

1. Браузер загружает только скрипты с явным хешем (`sha256-...`)
2. Эти скрипты могут динамически загружать другие скрипты (`strict-dynamic`)
3. Всё остальное — блокируется

**Важно:** `strict-dynamic` отключает белый список доменов для script-src. Все сторонние скрипты должны быть либо с хешем, либо загружаться через доверенный скрипт.

### Для Битрикс

```php
header("Content-Security-Policy: "
    . "default-src 'self'; "
    . "script-src 'strict-dynamic' 'sha256-...'; "
    . "object-src 'none'; "
    . "base-uri 'none'; "
    . "trusted-types default"
);
```

### Проверка

DevTools → Console → CSP violations.
