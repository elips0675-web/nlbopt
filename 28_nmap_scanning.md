# Nmap — сетевое сканирование безопасности

## Установка

```bash
# Windows
https://nmap.org/download.html

# Linux
sudo apt install nmap

# macOS
brew install nmap
```

## Базовые сканы

### Быстрая проверка открытых портов

```bash
nmap -sS -p 22,80,443,3306,8080,8443 site.ru
```

- `-sS` — SYN-scan (стелс, не логируется приложениями)
- `-p` — список портов

### Определение сервисов и версий

```bash
nmap -sV -p 80,443 site.ru
```

Показывает: nginx 1.24, Apache 2.4.57, OpenSSH 8.9p1 и т.д.

### Определение ОС

```bash
nmap -O site.ru
```

Требует root-права. Показывает Linux 5.x / Windows Server 2022.

### Полный скан (все порты)

```bash
nmap -sS -sV -p- site.ru
```

Долгий (может идти 10-30 минут). Все 65535 портов.

## NSE-скрипты (Nmap Scripting Engine)

### HTTP/Security скрипты

```bash
# HTTP-заголовки безопасности
nmap --script http-security-headers -p 443 site.ru

# Проверка на HTTP методы (TRACE, PUT и т.д.)
nmap --script http-methods --script-args http-methods.url-path=/ -p 443 site.ru

# SQL injection (базовая)
nmap --script http-sql-injection -p 443 site.ru

# XSS (базовая)
nmap --script http-xssed -p 443 site.ru

# Проверка CSRF
nmap --script http-csrf -p 443 site.ru

# Определение CMS
nmap --script http-cms -p 443 site.ru

# WebDAV
nmap --script http-webdav-scan -p 443 site.ru

# Directory brute force
nmap --script http-enum -p 443 site.ru
```

### SSL/TLS скрипты

```bash
# Проверка SSL-сертификата
nmap --script ssl-cert -p 443 site.ru

# Проверка уязвимостей SSL/TLS
nmap --script ssl-enum-ciphers -p 443 site.ru

# Heartbleed (CVE-2014-0160)
nmap --script ssl-heartbleed -p 443 site.ru

# POODLE (CVE-2014-3566)
nmap --script ssl-poodle -p 443 site.ru

# Проверка на слабые шифры
nmap --script ssl-dh-params -p 443 site.ru
```

### Брутфорс скрипты

```bash
# Брутфорс SSH
nmap --script ssh-brute --script-args userdb=users.txt,passdb=pass.txt -p 22 site.ru

# Брутфорс HTTP Basic Auth
nmap --script http-brute -p 80 site.ru

# Брутфорс FTP
nmap --script ftp-brute -p 21 site.ru
```

## Специфичные сканы для Битрикс

### Стандартные порты веб-сервера

```bash
nmap -sV -sC -p 80,443,8080,8443 site.ru
```

`-sC` — стандартные NSE-скрипты (безопасность, заголовки, SSL).

### Поиск админки

```bash
nmap --script http-enum --script-args http-enum.fingerprintfile=./bitrix-paths.txt -p 443 site.ru
```

### Проверка открытых портов БД

```bash
# MySQL (3306), PostgreSQL (5432), Redis (6379)
nmap -sS -p 3306,5432,6379,11211 site.ru

# Если открыты — БД доступна извне (критическая уязвимость!)
```

### Полный security-скан

```bash
nmap -sS -sV -sC -O --script http-security-headers,ssl-enum-ciphers,http-enum -p 80,443 site.ru
```

## Сохранение результатов

```bash
# Нормальный вывод
nmap -sV -p 80,443 site.ru -oN scan.txt

# XML (для парсинга)
nmap -sV -p 80,443 site.ru -oX scan.xml

# Все форматы сразу
nmap -sV -p 80,443 site.ru -oA scan
```

## Анализ результатов

### Критичные находки для веб-сервера

| Порт | Сервис | Статус |
|------|--------|--------|
| 22/tcp | SSH | Должен быть закрыт по IP или на нестандартном порту |
| 3306/tcp | MySQL | Должен быть закрыт (bind 127.0.0.1) |
| 6379/tcp | Redis | Должен быть закрыт |
| 11211/tcp | Memcached | Должен быть закрыт |
| 80/tcp | HTTP | Только редирект на 443 |
| 443/tcp | HTTPS | Открыт |
| 8080/tcp | HTTP-alt | Если не используется — закрыть |
| 8443/tcp | HTTPS-alt | Если не используется — закрыть |

### Пример отчёта

```bash
$ nmap -sV -sC -p 22,80,443,3306 site.ru

PORT     STATE    SERVICE    VERSION
22/tcp   filtered ssh        (заблокирован firewall)
80/tcp   open     http       nginx 1.24.0
|_http-title: Site.ru
443/tcp  open     http       nginx 1.24.0
|_http-title: Site.ru
| ssl-cert: Subject: commonName=site.ru
| ssl-enum-ciphers: TLSv1.2 TLSv1.3 — нет слабых шифров
3306/tcp filtered mysql      (заблокирован, bind 127.0.0.1)
```

## Типичные проблемы на проектах

- **3306/open** — MySQL доступен извне → сменить bind-address
- **22/open** — SSH на дефолтном порту → перенести на 22022 + ключи
- **8080/open** — забытый тестовый стенд или панель управления
- **21/open** — FTP вместо SFTP/SCP
- **443/TLSv1.0** — старый TLS → отключить, оставить только 1.2+1.3
- **http-methods: PUT** — можно загрузить shell на сервер

## Регулярность

```bash
# Еженедельный скрипт
#!/bin/bash
nmap -sS -sV -sC -p 22,80,443,3306 site.ru -oN /var/log/nmap/weekly-$(date +%Y%m%d).txt
```
