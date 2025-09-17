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

-- lab2_variant10_alternative.sql
-- Цель: Выполнение задания лаб.работы №2 с альтернативными данными
-- 1. Создание пользователя и проверка подключения
-- 2. Создание схемы базы туристического агентства
-- 3. Наложение ограничений
-- 4. Заполнение данными, тест ограничений
-- 5. Транзакционный блок и откат
-- 6. Дополнительные структуры данных


-- 1. Создание нового пользователя
-- CREATE USER IF NOT EXISTS tour_manager WITH PASSWORD 'manager2025' NOCREATEROLE NOCREATEDB;
-- Проверка подключения: в psql выполните \c variant10 tour_manager


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
 
 

-- Заполнение таблицы городов (европейские и южные города России)
INSERT INTO cities (name) VALUES
  ('Калининград'),('Псков'),('Великий Новгород'),('Мурманск'),('Архангельск'),
  ('Астрахань'),('Махачкала'),('Грозный'),('Нальчик'),('Майкоп');
 
 
 
-- Заполнение таблицы руководителей туров (другие фамилии и возраста)
INSERT INTO leaders (last_name,birth_date) VALUES
  ('Белов','1984-02-28'),
  ('Рыбаков','1992-09-11'),
  ('Панин','1996-05-07'),
  ('Гришин','1979-08-19'),
  ('Фролов','1989-12-23'),
  ('Титов','1983-06-30'),
  ('Крылов','1995-03-14'),
  ('Носов','1976-11-02'),
  ('Голубев','1993-07-25'),
  ('Макаров','1985-04-18');
 
 
 
-- Заполнение таблицы туров (другие цены и даты)
INSERT INTO tours (tour_type,price,start_date,city_id) VALUES
  ('автобусный',9500,'2025-10-08',1),
  ('железнодорожный',17500,'2025-11-12',2),
  ('авиа',29000,'2025-12-15',3),
  ('автобусный',11500,'2025-09-22',4),
  ('железнодорожный',20000,'2025-10-17',5),
  ('авиа',33000,'2025-11-28',6),
  ('автобусный',10200,'2025-12-08',7),
  ('железнодорожный',18500,'2025-09-26',8),
  ('авиа',31500,'2025-10-19',9),
  ('автобусный',12800,'2025-11-14',10);
 
 
 
-- Заполнение таблицы заказов (другая нумерация и участники)
INSERT INTO orders (order_date,order_number,tour_id,leader_id,participants) VALUES
  ('2025-08-25','REQ3001',1,1,14),
  ('2025-08-26','REQ3002',2,2,22),
  ('2025-08-27','REQ3003',3,3,11),
  ('2025-08-28','REQ3004',4,4,23),
  ('2025-08-29','REQ3005',5,5,19),
  ('2025-08-30','REQ3006',6,6,25),
  ('2025-08-31','REQ3007',7,7,15),
  ('2025-09-01','REQ3008',8,8,17),
  ('2025-09-02','REQ3009',9,9,21),
  ('2025-09-03','REQ3010',10,10,13);
 
 
 
-- 5. Транзакция и откат
BEGIN;
INSERT INTO orders (order_date,order_number,tour_id,leader_id,participants) VALUES
  ('2025-09-10','FAIL1',1,1,16),
  ('2025-09-10','FAIL2',2,2,28);  -- вызовет ошибку и откат
ROLLBACK;
 
 
 
-- Проверка, что данные не добавились
SELECT * FROM orders WHERE order_number IN ('FAIL1','FAIL2');
 

-- 6. Демонстрация параллельного подключения и блокировок
-- В одном терминале под tour_manager выполнить:
--   BEGIN;
--   INSERT INTO orders (order_date,order_number,tour_id,leader_id,participants)
--     VALUES ('2025-09-20','LOCK1',4,4,15);
--   -- не COMMIT
--
-- В другом терминале под tour_manager выполнить:
--   INSERT INTO orders (order_date,order_number,tour_id,leader_id,participants)
--     VALUES ('2025-09-20','LOCK2',4,4,18);
-- Результат: вторая вставка будет ждать снятия блокировки или завершения транзакции.

 
-- Просмотр данных
SELECT * FROM cities LIMIT 5;
SELECT * FROM orders WHERE participants > 18;
 
 
-- 7. Создание дополнительных производных таблиц
-- 7.1 Материализованное представление с количеством заказов и общей выручкой по городу
DROP MATERIALIZED VIEW IF EXISTS region_statistics;
CREATE MATERIALIZED VIEW region_statistics AS
SELECT
  c.name AS region_name,
  COUNT(o.id) AS bookings_count,
  SUM(t.price * o.participants) AS gross_revenue,
  AVG(t.price) AS avg_tour_price
FROM orders o
JOIN tours t ON o.tour_id = t.id
JOIN cities c ON t.city_id = c.id
GROUP BY c.name;

-- 7.2 Дочерняя таблица для архивных заказов (старше 45 дней)
DROP TABLE IF EXISTS historical_orders CASCADE;
CREATE TABLE historical_orders (
  CHECK (order_date < CURRENT_DATE - INTERVAL '45 days')
) INHERITS (orders);

-- Перенос старых заказов (пример для августовских заказов)
INSERT INTO historical_orders SELECT * FROM orders WHERE order_date < '2025-08-15';
DELETE FROM orders WHERE order_date < '2025-08-15';

-- 8. Просмотр структуры изменённых таблиц
-- 8.1 Через метаданные
SELECT table_name, column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name IN ('cities','leaders','tours','orders','historical_orders')
ORDER BY table_name, ordinal_position;

 
 
-- 9. Создание представления детализации бронирований
CREATE VIEW booking_analytics AS
SELECT 
    o.order_date,
    o.order_number,
    l.last_name AS guide_name,
    t.tour_type,
    c.name AS destination,
    t.start_date,
    t.price,
    o.participants,
    (t.price * o.participants) AS total_cost
FROM orders o
JOIN leaders l ON o.leader_id = l.id  
JOIN tours t ON o.tour_id = t.id
JOIN cities c ON t.city_id = c.id;
 
 
 
-- Просмотр представления
SELECT * FROM booking_analytics ORDER BY total_cost DESC;

-- 10. Дополнительные аналитические запросы
SELECT 'Анализ загруженности гидов:' AS analysis_type;
SELECT 
    l.last_name,
    COUNT(o.id) AS tours_led,
    SUM(o.participants) AS total_tourists,
    AVG(o.participants) AS avg_group_size
FROM leaders l
LEFT JOIN orders o ON l.id = o.leader_id
GROUP BY l.id, l.last_name
ORDER BY tours_led DESC;

SELECT 'Сезонный анализ туров:' AS analysis_type;
SELECT 
    EXTRACT(MONTH FROM t.start_date) AS tour_month,
    COUNT(*) AS tours_scheduled,
    SUM(CASE WHEN o.id IS NOT NULL THEN 1 ELSE 0 END) AS tours_booked
FROM tours t
LEFT JOIN orders o ON t.id = o.tour_id
GROUP BY EXTRACT(MONTH FROM t.start_date)
ORDER BY tour_month;

-- Просмотр материализованного представления
SELECT * FROM region_statistics ORDER BY gross_revenue DESC;