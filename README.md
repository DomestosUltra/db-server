# db-server

Проект для выполнения лабораторных работ по базам данных PostgreSQL.

## 📁 Структура проекта

```text
db-server/
├── sql/                    # SQL скрипты лабораторных работ
│   ├── student_d/         # Работы студента D
│   │   ├── lab1/          # Лабораторная работа №1
│   │   ├── lab2/          # Лабораторная работа №2
│   │   ├── lab3/          # Лабораторная работа №3
│   │   └── lab4/          # Лабораторная работа №4
│   └── student_v/         # Работы студента V
├── ci-cd-files/           # Docker конфигурация
│   ├── docker-compose.yml
│   ├── Dockerfile
│   └── pg_config/         # Конфигурационные файлы PostgreSQL
├── scripts/               # Вспомогательные скрипты
├── docs/                  # Документация к лабораторным работам
└── .env                   # Переменные окружения
```

## 🚀 Быстрый старт

### Вариант 1: Локальная база данных (Docker)

1. **Клонируйте репозиторий:**

   ```bash
   git clone https://github.com/DomestosUltra/db-server.git
   cd db-server
   ```

2. **Настройте переменные окружения:**

   ```bash
   cp .env.example .env
   # Отредактируйте .env при необходимости
   ```

3. **Запустите PostgreSQL в Docker:**

   ```bash
   cd ci-cd-files
   docker-compose up -d postgres
   ```

4. **Проверьте подключение:**

   ```bash
   docker exec -it postgres17_lab psql -U dbuser -d variant10
   ```

### Вариант 2: Удаленная база данных

Если у вас есть доступ к удаленной базе данных (как в примерах):

```bash
psql -h labs-work.ru -p 5434 -U dima -d variant10
```

## 📝 Выполнение лабораторных работ

### Метод 1: Выполнение целого файла

```bash
# Лабораторная работа №1
psql -h labs-work.ru -p 5434 -U dima -d variant10 -f sql/student_d/lab1/01_lab.sql

# Лабораторная работа №2
psql -h labs-work.ru -p 5434 -U dima -d variant10 -f sql/student_d/lab2/02_lab.sql

# Лабораторная работа №3
psql -h labs-work.ru -p 5434 -U dima -d variant10 -f sql/student_d/lab3/03_lab.sql

# Лабораторная работа №4
psql -h labs-work.ru -p 5434 -U dima -d variant10 -f sql/student_d/lab4/04_lab_corrected.sql
```

### Метод 2: Интерактивное выполнение

```bash
# Подключение к базе данных
psql -h labs-work.ru -p 5434 -U dima -d variant10

# Внутри psql выполните:
\i sql/student_d/lab1/01_lab.sql
```

### Метод 3: Выполнение с выводом (включая команды)

```bash
# Флаг -e показывает выполняемые команды
psql -h labs-work.ru -p 5434 -U dima -d variant10 -e -f sql/student_d/lab1/01_lab.sql
```

## 🔧 Параметры подключения

### Локальная база (Docker)

- **Host:** localhost
- **Port:** 5434
- **Database:** variant10
- **Username:** dbuser
- **Password:** dbpassword

### Удаленная база (лабораторная)

- **Host:** labs-work.ru
- **Port:** 5434
- **Database:** variant10
- **Username:** [создать самому]
- **Password:** [запрашивается при подключении]

## 📚 Описание лабораторных работ

### Лабораторная работа №1

- **Тема:** Создание схемы базы данных туристического агентства
- **Файл:** `sql/student_d/lab1/01_lab.sql`
- **Содержание:** Создание таблиц, ограничений, заполнение данными

### Лабораторная работа №2

- **Тема:** Изменение структуры базы данных
- **Файл:** `sql/student_d/lab2/02_lab.sql`
- **Содержание:** Модификация таблиц, создание представлений

### Лабораторная работа №3

- **Тема:** Агрегатные функции и массивы в PostgreSQL
- **Файл:** `sql/student_d/lab3/03_lab.sql`
- **Содержание:** Работа с массивами, агрегатными функциями

### Лабораторная работа №4

- **Тема:** Многотабличные запросы и подзапросы
- **Файл:** `sql/student_d/lab4/04_lab_corrected.sql`
- **Содержание:** JOIN, подзапросы, CTE

## 🐳 Docker команды

```bash
# Запуск контейнера
docker-compose up -d postgres

# Остановка контейнера
docker-compose down

# Просмотр логов
docker-compose logs postgres

# Подключение к контейнеру
docker exec -it postgres17_lab bash

# Подключение к базе внутри контейнера
docker exec -it postgres17_lab psql -U dbuser -d variant10

# Перезапуск с пересборкой
docker-compose up -d --build
```

## 🔍 Полезные psql команды

```sql
-- Список баз данных
\l

-- Список таблиц
\dt

-- Описание таблицы
\d table_name

-- Выход из psql
\q

-- Справка по командам
\?

-- Включение вывода времени выполнения
\timing on

-- Изменение формата вывода
\pset border 2
```

## 🛠 Разработка

### Создание новой лабораторной работы

1. Создайте новую директорию:

   ```bash
   mkdir sql/student_d/lab5
   ```

2. Создайте SQL файл:

   ```bash
   touch sql/student_d/lab5/05_lab.sql
   ```

3. Добавьте стандартные настройки в начало файла:

   ```sql
   -- Настройки psql
   \set ECHO all
   \timing on
   \pset border 2
   \pset fieldsep ' | '
   \pset recordsep '\n----\n'
   ```

### Тестирование

```bash
# Проверка синтаксиса без выполнения
psql -h labs-work.ru -p 5434 -U dima -d variant10 --dry-run -f your_script.sql

# Выполнение в транзакции с откатом
psql -h labs-work.ru -p 5434 -U dima -d variant10 -c "BEGIN; \i your_script.sql; ROLLBACK;"
```

## 📝 Советы по работе

1. **Всегда делайте бэкап данных** перед выполнением изменяющих запросов
2. **Используйте транзакции** для безопасного тестирования
3. **Проверяйте результаты** каждого этапа лабораторной работы
4. **Изучайте план выполнения** сложных запросов с помощью `EXPLAIN`
5. **Используйте версионирование** для отслеживания изменений

## 🤝 Вклад в проект

1. Создайте форк репозитория
2. Создайте ветку для новой функции: `git checkout -b feature/new-lab`
3. Зафиксируйте изменения: `git commit -am 'Add new lab'`
4. Отправьте в ветку: `git push origin feature/new-lab`
5. Создайте Pull Request

## 📄 Лицензия

Этот проект лицензирован под MIT License - смотрите файл [LICENSE](LICENSE) для подробностей.
