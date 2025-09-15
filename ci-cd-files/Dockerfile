# Используем официальный образ PostgreSQL 17
FROM postgres:17

# Устанавливаем дополнительные пакеты (по желанию)
RUN apt-get update \
 && apt-get install -y postgresql-contrib \
 && rm -rf /var/lib/apt/lists/*

# Создаем каталог для кастомных конфигов
RUN mkdir -p /docker-entrypoint-initdb.d/custom_conf

# Копируем ваши файлы конфигурации
COPY pg_config/postgresql.conf /docker-entrypoint-initdb.d/custom_conf/postgresql.conf
COPY pg_config/pg_hba.conf      /docker-entrypoint-initdb.d/custom_conf/pg_hba.conf

# Копируем SQL-скрипты инициализации
COPY ./sql/ /docker-entrypoint-initdb.d/

# Устанавливаем права на конфигурационные файлы
RUN chown -R postgres:postgres /docker-entrypoint-initdb.d/custom_conf \
 && chmod 600 /docker-entrypoint-initdb.d/custom_conf/*.conf

# Открываем порт PostgreSQL
EXPOSE 5432

# При старте указываем использовать ваши конфиги из custom_conf
CMD ["postgres", \
     "-c", "config_file=/docker-entrypoint-initdb.d/custom_conf/postgresql.conf", \
     "-c", "hba_file=/docker-entrypoint-initdb.d/custom_conf/pg_hba.conf"]
