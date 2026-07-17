# Security Audit & Headers for 1C-Bitrix

## Критически важные файлы

1. `/bitrix/.settings.php` — главный конфиг с подключением к БД, кешем, логами, почтой. Содержит пароли и ключи шифрования.
2. `/bitrix/php_interface/after_connect.php` или `/bitrix/php_interface/after_connect_d7.php` — дополнительные настройки подключения к БД, часто содержат учётные данные.
3. `/bitrix/php_interface/dbconn.php` (для старых версий) — классический файл с логином/паролем к MySQL.
4. `/bitrix/.access.php` — права доступа к разделам и файлам в админке.
5. `/bitrix/modules/main/admin/define.php` или аналоги — проверка лицензии, иногда содержат ключи.

## Важные файлы

6. `.htaccess` в корне и в `/bitrix/` — правила редиректов, запретов доступа, включение модулей Apache. Показывает, закрыт ли доступ к служебным папкам.
7. `/bitrix/modules/main/classes/general/version.php` — точная версия ядра Битрикс (чтобы проверить уязвимости).
8. `/bitrix/modules/security/` — если установлен модуль «Проактивная защита», его конфиги покажут, включены ли фильтры, капча, двухфакторка.
9. `/bitrix/.settings_extra.php` — дополнительные настройки, иногда кастомные.
10. Логи: `/bitrix/modules/main/logs/` или настроенные логи ошибок PHP.

## Дополнительно полезные

11. `/bitrix/php_interface/init.php` — стартовый скрипт, часто содержит кастомную логику, переопределения, иногда бэкдоры.
12. `/bitrix/templates/` — шаблоны сайта, особенно `header.php` и `footer.php` — проверка на внедрённый вредоносный JS/PHP.
13. `/bitrix/backup/` — если есть доступ, покажет, настроены ли регулярные бэкапы.
14. `/bitrix/.htaccess.php` или аналоги — защита от выполнения PHP в загрузках.

---

## HTTP Security Headers для Битрикс

### CSP (Content Security Policy) — защита от XSS

Настройка в `/bitrix/php_interface/init.php`:

```php
AddEventHandler("main", "OnProlog", function() {
    $csp = "default-src 'self'; "
         . "script-src 'self' 'unsafe-inline' 'unsafe-eval' *.bitrix.info; "
         . "style-src 'self' 'unsafe-inline'; "
         . "img-src 'self' data: *.bitrix.info; "
         . "font-src 'self'; "
         . "connect-src 'self'; "
         . "frame-ancestors 'none'; "
         . "base-uri 'self'; "
         . "form-action 'self';";

    header("Content-Security-Policy: " . $csp);
});
```

**Проблемы Битрикс + CSP:**
- `'unsafe-inline'` для скриптов и стилей — Битрикс активно использует inline-JS/CSS
- `'unsafe-eval'` — нужен для некоторых компонентов
- Встроенный редактор и визуальные компоненты могут ломаться

**Рекомендация:** Начните с `Content-Security-Policy-Report-Only`, чтобы собрать нарушения, прежде чем включать блокировку.

### HSTS (HTTP Strict Transport Security)

**Apache (.htaccess):**
```apache
Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
```

**PHP (init.php):**
```php
header("Strict-Transport-Security: max-age=31536000; includeSubDomains; preload");
```

**Nginx:**
```nginx
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
```

### COOP (Cross-Origin Opener Policy)

```php
header("Cross-Origin-Opener-Policy: same-origin");
```

- `same-origin` — строгая изоляция
- `same-origin-allow-popups` — разрешает всплывающие окна (если нужны платёжные системы)

Дополнительно:
```php
header("Cross-Origin-Embedder-Policy: require-corp"); // COEP
header("Cross-Origin-Resource-Policy: same-origin");   // CORP
```

### Trusted Types — защита от DOM-XSS

```php
header("Content-Security-Policy: require-trusted-types-for 'script'; trusted-types default");
```

JavaScript:
```javascript
if (window.trustedTypes && window.trustedTypes.createPolicy) {
    const policy = window.trustedTypes.createPolicy('default', {
        createHTML: (input) => input,
        createScriptURL: (input) => input,
        createScript: (input) => input
    });
}
```

**Проблема:** Битрикс ядро и многие стандартные компоненты используют `innerHTML` напрямую. Trusted Types может сломать стандартную функциональность.

---

## Итоговый код для `/bitrix/php_interface/init.php`

```php
<?php
AddEventHandler("main", "OnProlog", function() {
    if ($_SERVER['HTTPS'] === 'on' || $_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https') {
        // HSTS
        header("Strict-Transport-Security: max-age=31536000; includeSubDomains; preload");
    }

    // COOP + COEP + CORP
    header("Cross-Origin-Opener-Policy: same-origin");
    header("Cross-Origin-Embedder-Policy: require-corp");
    header("Cross-Origin-Resource-Policy: same-origin");

    // CSP (Report-Only для начала!)
    header("Content-Security-Policy-Report-Only: "
        . "default-src 'self'; "
        . "script-src 'self' 'unsafe-inline' 'unsafe-eval' *.bitrix.info; "
        . "style-src 'self' 'unsafe-inline'; "
        . "img-src 'self' data: blob: *.bitrix.info; "
        . "font-src 'self'; "
        . "connect-src 'self'; "
        . "frame-ancestors 'none'; "
        . "base-uri 'self'; "
        . "form-action 'self'; "
        . "upgrade-insecure-requests; "
        . "report-uri /bitrix/tools/csp_report.php"
    );

    // Дополнительные защитные заголовки
    header("X-Content-Type-Options: nosniff");
    header("X-Frame-Options: DENY");
    header("Referrer-Policy: strict-origin-when-cross-origin");
    header("Permissions-Policy: geolocation=(), microphone=(), camera=()");
});
```

## Проверка заголовков

```bash
curl -I https://ваш-сайт.ru
```

Или используйте [securityheaders.com](https://securityheaders.com).

---

## Что можно определить при аудите

| Аспект | Что проверяется |
|--------|----------------|
| Утечка учётных данных | Пароли в открытом виде, слабые ключи |
| Права доступа | Открыты ли служебные разделы (/bitrix/admin/, /upload/) |
| Устаревшая версия | Известные CVE для версии ядра |
| Модуль безопасности | Включён ли proactive, какие фильтры работают |
| Защита от XSS/SQLi | Настроены ли экранирование, WAF-правила |
| Конфигурация сессий | Безопасность cookies, httponly, secure-флаги |
