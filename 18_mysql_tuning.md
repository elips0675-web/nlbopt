# MySQL tuning + медленные запросы

## Проблема

Дефолтный `my.cnf` рассчитан на 128MB ОЗУ — для Битрикс этого катастрофически мало.

## Рекомендуемые настройки

### Для сервера с 4GB RAM

```ini
[mysqld]
innodb_buffer_pool_size = 2G          # 50-70% от ОЗУ
innodb_log_file_size = 512M
innodb_flush_log_at_trx_commit = 2    # 0 = скорость, 2 = баланс
innodb_flush_method = O_DIRECT
innodb_file_per_table = 1

query_cache_type = 0                   # InnoDB не использует QC
query_cache_size = 0

tmp_table_size = 256M
max_heap_table_size = 256M

max_connections = 150
thread_cache_size = 16

max_execution_time = 5000              # убивать запросы > 5s
```

### Для сервера с 8GB RAM

```ini
innodb_buffer_pool_size = 5G
innodb_log_file_size = 1G
```

## Slow query log

Включить логирование медленных запросов:

```ini
slow_query_log = 1
slow_query_log_file = /var/log/mysql/slow.log
long_query_time = 1
log_queries_not_using_indexes = 1
```

### Анализ

```bash
# Топ-10 медленных запросов
mysqldumpslow -s t -t 10 /var/log/mysql/slow.log
```

## Проверка индексов

Для каждого запроса каталога, поиска и фильтрации:

```sql
EXPLAIN SELECT * FROM b_iblock_element WHERE ...
```

Искать в выводе: `Using filesort`, `Using temporary`, `type = ALL`.

### Типичные проблемы в Битрикс

- `b_iblock_element` — нет индекса по `IBLOCK_ID`, `ACTIVE`, `DATE_ACTIVE_FROM`
- `b_sale_order` — нет индекса по `USER_ID`, `DATE_INSERT`
- `b_user` — нет индекса по `LAST_LOGIN`, `ACTIVE`
