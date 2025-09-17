-- Эхо команд
\set ECHO all
-- Вывод времени выполнения (по желанию)
\timing on

-- Границы для таблиц (рисует рамку вокруг вывода)
\pset border 2

-- Разделитель между столбцами
\pset fieldsep ' | '

-- Разделитель между записями
\pset recordsep '\n----\n'

-- lab_variant10_full.sql
-- Цель: Выполнение задания по варианту 10 полностью в одном SQL-файле.
-- 1. Создание пользователя и проверка подключения
-- 2. Создание схемы базы туристического агентства
-- 3. Наложение ограничений
-- 4. Заполнение данными, тест ограничений
-- 5. Транзакционный блок и откат


-- 1. Создание нового пользователя
-- CREATE USER IF NOT EXISTS lab_user WITH PASSWORD 'lab' NOCREATEROLE NOCREATEDB;
-- Проверка подключения: в psql выполните \c variant10 lab_user


-- 2. Создание таблиц
-- 2.1. Справочник городов
DROP TABLE IF EXISTS cities CASCADE;
CREATE TABLE cities (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL
);
 
 
 
-- 2.2. Справочник руководителей туров
DROP TABLE IF EXISTS leaders CASCADE;
CREATE TABLE leaders (
  id SERIAL PRIMARY KEY,
  last_name VARCHAR(50) NOT NULL,
  birth_date DATE NOT NULL
);
 
 
 
-- 2.3. Таблица туров
DROP TABLE IF EXISTS tours CASCADE;
CREATE TABLE tours (
  id SERIAL PRIMARY KEY,
  tour_type VARCHAR(20) NOT NULL,
  price NUMERIC(10,2) NOT NULL,
  start_date DATE NOT NULL,
  city_id INT NOT NULL REFERENCES cities(id)
);
 
 
 
-- 2.4. Таблица заказов
DROP TABLE IF EXISTS orders CASCADE;
CREATE TABLE orders (
  id SERIAL PRIMARY KEY,
  order_date DATE NOT NULL,
  order_number VARCHAR(20) NOT NULL,
  tour_id INT NOT NULL REFERENCES tours(id),
  leader_id INT NOT NULL REFERENCES leaders(id),
  participants INT NOT NULL
);
 
 
 
-- 3. Ограничения
-- Ограничение на тип тура
ALTER TABLE tours DROP CONSTRAINT IF EXISTS tours_type_check;
ALTER TABLE tours ADD CONSTRAINT tours_type_check
  CHECK (tour_type IN ('автобусный','железнодорожный','авиа'));
 
 
 
-- Ограничение на неотрицательную цену тура
ALTER TABLE tours DROP CONSTRAINT IF EXISTS tours_price_check;
ALTER TABLE tours ADD CONSTRAINT tours_price_check
  CHECK (price >= 0);
 
 
 
-- Ограничение на возраст руководителя (не моложе 25 лет)
ALTER TABLE leaders DROP CONSTRAINT IF EXISTS leaders_age_check;
ALTER TABLE leaders ADD CONSTRAINT leaders_age_check
  CHECK (DATE_PART('year', AGE(CURRENT_DATE, birth_date)) >= 25);
 
 
 
-- Ограничение на количество участников в заказе
ALTER TABLE orders DROP CONSTRAINT IF EXISTS orders_participants_check;
ALTER TABLE orders ADD CONSTRAINT orders_participants_check
  CHECK (participants BETWEEN 10 AND 25);
 

 
-- 4. Заполнение данными
TRUNCATE cities, leaders, tours, orders RESTART IDENTITY;
 
 

-- Заполнение таблицы городов
INSERT INTO cities (name) VALUES
  ('Москва'),('Питер'),('Казань'),('Новосибирск'),('Екатеринбург'),
  ('Самара'),('Ростов-на-Дону'),('Волгоград'),('Краснодар'),('Сочи');
 
 
 
-- Заполнение таблицы руководителей туров
INSERT INTO leaders (last_name,birth_date) VALUES
  ('Иванов','1980-01-01'),
  ('Петров','1995-06-15'),
  ('Сидоров','1999-12-30'),
  ('Кузнецов','1975-03-20'),
  ('Попов','1990-09-10'),
  ('Васильев','1985-11-25'),
  ('Михайлов','1998-07-07'),
  ('Новиков','1970-05-05'),
  ('Федоров','1992-02-14'),
  ('Морозов','1988-08-08');
 
 
 
-- Заполнение таблицы туров
INSERT INTO tours (tour_type,price,start_date,city_id) VALUES
  ('автобусный',10000,'2025-10-01',1),
  ('железнодорожный',15000,'2025-11-05',2),
  ('авиа',25000,'2025-12-20',3),
  ('автобусный',12000,'2025-09-15',4),
  ('железнодорожный',18000,'2025-10-10',5),
  ('авиа',30000,'2025-11-25',6),
  ('автобусный',11000,'2025-12-05',7),
  ('железнодорожный',16000,'2025-09-20',8),
  ('авиа',27000,'2025-10-15',9),
  ('автобусный',13000,'2025-11-30',10);
 
 
 
-- Заполнение таблицы заказов
INSERT INTO orders (order_date,order_number,tour_id,leader_id,participants) VALUES
  ('2025-09-01','ORD1001',1,1,15),
  ('2025-09-02','ORD1002',2,2,20),
  ('2025-09-03','ORD1003',3,3,10),
  ('2025-09-04','ORD1004',4,4,25),
  ('2025-09-05','ORD1005',5,5,18),
  ('2025-09-06','ORD1006',6,6,22),
  ('2025-09-07','ORD1007',7,7,12),
  ('2025-09-08','ORD1008',8,8,14),
  ('2025-09-09','ORD1009',9,9,19),
  ('2025-09-10','ORD1010',10,10,16);
 
 
 
-- 5. Транзакция и откат
BEGIN;
INSERT INTO orders (order_date,order_number,tour_id,leader_id,participants) VALUES
  ('2025-09-15','ORD1',1,1,15),
  ('2025-09-15','ORD2',2,2,30);  -- вызовет ошибку и откат
ROLLBACK;
 
 
 
-- Проверка, что данные не добавились
SELECT * FROM orders WHERE order_number IN ('ORD1','ORD2');
 

-- 6. Демонстрация параллельного подключения и блокировок
-- В одном терминале под lab_user выполнить:
--   BEGIN;
--   INSERT INTO orders (order_date,order_number,tour_id,leader_id,participants)
--     VALUES ('2025-09-16','PAR1',3,3,12);
--   -- не COMMIT
--
-- В другом терминале под lab_user выполнить:
--   INSERT INTO orders (order_date,order_number,tour_id,leader_id,participants)
--     VALUES ('2025-09-16','PAR2',3,3,14);
-- Результат: вторая вставка будет ждать снятия блокировки или завершения транзакции.

 
-- Просмотр данных
SELECT * FROM cities LIMIT 5;
SELECT * FROM orders WHERE participants > 15;
 
 
-- 7. Создание дополнительных производных таблиц
-- 7.1 Материализованное представление с количеством заказов и общей выручкой по городу
DROP MATERIALIZED VIEW IF EXISTS city_orders_summary;
CREATE MATERIALIZED VIEW city_orders_summary AS
SELECT
  c.name AS city_name,
  COUNT(o.id) AS total_orders,
  SUM(t.price * o.participants) AS total_revenue
FROM orders o
JOIN tours t ON o.tour_id = t.id
JOIN cities c ON t.city_id = c.id
GROUP BY c.name;

-- 7.2 Дочерняя таблица для архивных заказов (старше 30 дней)
DROP TABLE IF EXISTS orders_archive CASCADE;
CREATE TABLE orders_archive (
  CHECK (order_date < CURRENT_DATE - INTERVAL '30 days')
) INHERITS (orders);

-- Перенос старых заказов (пример)
INSERT INTO orders_archive SELECT * FROM orders WHERE order_date < '2025-08-01';
DELETE FROM orders WHERE order_date < '2025-08-01';

-- 8. Просмотр структуры изменённых таблиц
-- 8.1 Через метаданные
SELECT table_name, column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name IN ('cities','leaders','tours','orders','orders_archive');

 
 
-- 9. Создание представления итогов заказов
CREATE VIEW order_details AS
SELECT 
    o.order_date,
    l.last_name,
    t.tour_type,
    c.name AS city_name,
    t.start_date,
    t.price
FROM orders o
JOIN leaders l ON o.leader_id = l.id  
JOIN tours t ON o.tour_id = t.id
JOIN cities c ON t.city_id = c.id;
 
 
 
-- Просмотр представления
SELECT * FROM order_details;
