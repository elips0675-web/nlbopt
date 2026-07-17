# PHP OPcache + PHP-FPM tuning

## OPcache

Битрикс — тяжёлый фреймворк. Без OPcache каждый запрос компилирует PHP-файлы заново.

### Рекомендуемые настройки

```
opcache.enable=1
opcache.memory_consumption=256
opcache.max_accelerated_files=40000
opcache.revalidate_freq=60
opcache.validate_timestamps=1
opcache.interned_strings_buffer=16
opcache.fast_shutdown=1
```

Где проверить: `/bitrix/admin/site_checker.php` → OPcache.

### Сброс кэша после обновлений

```php
// В init.php или вручную
if (function_exists('opcache_reset')) {
    opcache_reset();
}
```

## PHP-FPM

Неверный `pm.max_children` — либо OOM (kill), либо простой ресурсов.

### Формула для max_children

```
max_children = (ОЗУ - 512MB) / avg_process_size
```

Пример для сервера 4GB RAM, средний процесс ~40MB:
```
max_children = (4096 - 512) / 40 ≈ 90
```

### Рекомендуемые настройки

```
pm = dynamic
pm.max_children = 50
pm.start_servers = 8
pm.min_spare_servers = 4
pm.max_spare_servers = 16
pm.max_requests = 500
```

### Проверка

```bash
# Сколько памяти жрёт PHP-FPM
ps aux | grep php-fpm | awk '{sum+=$6} END {print sum/1024 "MB"}'
# Количество процессов
ps aux | grep php-fpm | wc -l
```
