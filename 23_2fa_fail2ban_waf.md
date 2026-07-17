# 2FA + Fail2ban + WAF (ModSecurity)

## Двухфакторная аутентификация (2FA)

Битрикс поддерживает 2FA через модуль «Проактивная защита».

### Включение

Админка → Настройки → Проактивная защита → OTP:

```
Режим: Принудительно (для всех админов)
Тип OTP: Google Authenticator / Битрикс24 OTP
```

### Принудительно через API

```php
// В init.php
use Bitrix\Security\Mfa\Otp;

COption::SetOptionString("security", "otp_enabled", "Y");
COption::SetOptionString("security", "otp_mandatory", "Y");
COption::SetOptionString("security", "otp_mandatory_date", date("d.m.Y"));
```

### Проверка

```bash
# Зайти в админку с нового устройства — должен запросить код
```

## Fail2ban — защита от брутфорса

### Установка

```bash
sudo apt install fail2ban
```

### Конфиг для Битрикс

```ini
# /etc/fail2ban/jail.local
[bitrix-admin]
enabled  = true
port     = http,https
filter   = bitrix-admin
logpath  = /var/log/nginx/access.log
maxretry = 5
bantime  = 3600
findtime = 300

[bitrix-auth]
enabled  = true
port     = http,https
filter   = bitrix-auth
logpath  = /var/log/nginx/access.log
maxretry = 10
bantime  = 3600
findtime = 600
```

### Фильтр для Bitrix admin

```ini
# /etc/fail2ban/filter.d/bitrix-admin.conf
[Definition]
failregex = ^<HOST> - .* "POST /bitrix/admin/.* (HTTP/.*)" 200
ignoreregex =
```

### Проверка

```bash
sudo fail2ban-client status bitrix-admin
```

## ModSecurity (WAF)

Web Application Firewall на уровне веб-сервера. Блокирует SQLi, XSS, RFI, LFI до PHP.

### Установка (Nginx + ModSecurity)

```bash
# Compile nginx with ModSecurity or use libnginx-mod-http-modsecurity
sudo apt install libnginx-mod-http-modsecurity
```

### Конфиг

```nginx
server {
    modsecurity on;
    modsecurity_rules_file /etc/nginx/modsec/main.conf;
}
```

### OWASP CRS (Core Rule Set)

```apache
# /etc/nginx/modsec/main.conf
Include /etc/nginx/modsec/owasp-crs/crs-setup.conf
Include /etc/nginx/modsec/owasp-crs/rules/*.conf

SecRuleEngine On
SecRequestBodyAccess On
SecResponseBodyAccess Off
SecDefaultAction "phase:2,deny,log,status:403"
```

### Режимы работы

| Режим | Действие |
|-------|----------|
| `SecRuleEngine On` | Блокирует + логирует |
| `SecRuleEngine DetectionOnly` | Только лог (рекомендуется сначала) |
| `SecRuleEngine Off` | Отключён |

### Проверка

```bash
# Тест SQLi
curl "https://site.ru/?id=1' OR '1'='1"

# Тест XSS
curl -X POST "https://site.ru/search/" -d "q=<script>alert(1)</script>"
```

Должен вернуть 403.
