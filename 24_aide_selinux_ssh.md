# AIDE / SELinux / SSH hardening

## Мониторинг целостности файлов (AIDE)

Любое изменение файлов ядра Битрикс — тревога. Защита от бэкдоров.

### Установка

```bash
sudo apt install aide
```

### Настройка

```bash
# /etc/aide/aide.conf
/var/www/site/bitrix/modules/     ALL
/var/www/site/bitrix/templates/   ALL
/var/www/site/bitrix/php_interface/ ALL
!/var/www/site/upload/            # исключить пользовательский контент
!/var/www/site/bitrix/cache/      # исключить кэш
!/var/www/site/bitrix/managed_cache/
!/var/www/site/bitrix/stack_cache/
```

### Инициализация

```bash
sudo aideinit
sudo mv /var/lib/aide/aide.db.new /var/lib/aide/aide.db
```

### Ежедневная проверка (cron)

```bash
# /etc/cron.daily/aide-check
#!/bin/bash
aide --check | mail -s "AIDE report" admin@site.ru
```

## SELinux / AppArmor

Ограничивает, что может делать веб-сервер при компрометации.

### SELinux (CentOS/RHEL)

```bash
# Включить SELinux
setenforce 1
sestatus

# Разрешить HTTPD подключаться к сети
setsebool -P httpd_can_network_connect on

# Правильные контексты для Битрикс
semanage fcontext -a -t httpd_sys_content_t "/var/www/site(/.*)?"
restorecon -Rv /var/www/site

# Для upload — разрешить запись
semanage fcontext -a -t httpd_sys_rw_content_t "/var/www/site/upload(/.*)?"
restorecon -Rv /var/www/site/upload
```

### AppArmor (Ubuntu/Debian)

```bash
# Статус
sudo aa-status

# Профиль для nginx
sudo aa-genprof nginx
# → запустить несколько запросов к сайту
# → разрешить необходимые операции
```

### Проверка SELinux

```bash
# Поиск блокировок
ausearch -m avc -ts recent
grep "denied" /var/log/audit/audit.log
```

## SSH hardening

### Рекомендуемый конфиг

```ini
# /etc/ssh/sshd_config
Port 22022                     # не 22 (меньше сканирований)
PermitRootLogin no             # запретить root
PasswordAuthentication no      # только ключи
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys

MaxAuthTries 3                 # 3 попытки — disconnect
MaxSessions 5                  # не больше 5 сессий

ClientAliveInterval 300        # проверка каждые 5 минут
ClientAliveCountMax 2          # неответ — разрыв

AllowUsers admin deploy        # только эти пользователи
AuthenticationMethods publickey

LogLevel VERBOSE               # логировать ключи
```

### Применить

```bash
sudo sshd -t                    # проверить конфиг
sudo systemctl reload sshd
```

### Проверка

```bash
# Сканирование портов
nmap -p 22022 site.ru

# Попытка входа по паролю — должна быть отклонена
ssh root@site.ru
# → Permission denied (publickey).
```
