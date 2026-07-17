# Email security (SPF/DKIM/DMARC) + DNS (DNSSEC/CAA)

## Email security

### SPF — кто может отправлять почту с домена

```dns
site.ru.  TXT  "v=spf1 mx a include:_spf.google.com include:spf.mail.ru ~all"
```

| Механизм | Значение |
|----------|----------|
| `mx` | Серверы из MX записи |
| `a` | IP из A записи домена |
| `include:_spf.google.com` | Google Workspace |
| `~all` | Мягкий отказ (softfail) — рекомендуется |
| `-all` | Жёсткий отказ — только когда всё настроено |

### DKIM — подпись писем

Генерируется почтовой системой:

```dns
default._domainkey.site.ru.  TXT  "v=DKIM1; h=sha256; k=rsa; p=MIGfMA0GCSqGSIb4DQEBAQUAA4GNADCBiQKBgQC..."
```

| Сервис | Где взять |
|--------|-----------|
| Google Workspace | Admin → Apps → Gmail → DKIM |
| Yandex 360 | Почта → DNS-записи |
| Mail.ru для бизнеса | Панель управления → DKIM |

### DMARC — политика обработки писем

```dns
_dmarc.site.ru.  TXT  "v=DMARC1; p=quarantine; rua=mailto:dmarc@site.ru; ruf=mailto:dmarc@site.ru; pct=100"
```

| Параметр | Значение |
|----------|----------|
| `p=none` | Только отчёты (начало) |
| `p=quarantine` | Спам (рекомендуется) |
| `p=reject` | Отклонять |
| `rua` | Куда слать агрегированные отчёты |
| `pct=100` | Процент писем под политикой |

### Проверка

```bash
# SPF
nslookup -type=TXT site.ru

# DKIM
nslookup -type=TXT default._domainkey.site.ru

# DMARC
nslookup -type=TXT _dmarc.site.ru
```

Или онлайн: [mxtoolbox.com](https://mxtoolbox.com).

## DNS security

### DNSSEC — защита от подмены DNS

Подмена DNS = злоумышленник направляет пользователей на свой сервер.

**Включение:**

| Регистратор | Где |
|-------------|-----|
| Cloudflare | Dash → DNS → DNSSEC |
| GoDaddy | Domain → DNSSEC |
| REG.RU | Домены → DNSSEC |
| NIC.RU | Панель управления → DNSSEC |

**Проверка:**

```bash
# Через dig
dig site.ru +dnssec +multiline

# Флаг ad (authentic data) должен быть в ответе
dig site.ru +adflag

# Или через https://dnssec-analyzer.verisignlabs.com
```

### CAA — какие CA могут выпускать SSL

```dns
site.ru.  CAA  0 issue "letsencrypt.org"
site.ru.  CAA  0 issue "comodoca.com"
site.ru.  CAA  0 iodef "mailto:caa@site.ru"
```

| Параметр | Значение |
|----------|----------|
| `issue` | CA, который может выпускать сертификаты |
| `iodef` | Куда сообщать о нарушениях |

### Проверка

```bash
dig site.ru CAA
```

### Итоговая таблица DNS-записей безопасности

| Тип | Запись | Назначение |
|-----|--------|------------|
| TXT | `v=spf1 ...` | SPF — кто шлёт почту |
| TXT | `default._domainkey` | DKIM — подпись писем |
| TXT | `_dmarc` | DMARC — политика |
| CAA | `site.ru CAA` | Разрешённые CA |
| DS | `site.ru DS` | DNSSEC (автоматически) |
