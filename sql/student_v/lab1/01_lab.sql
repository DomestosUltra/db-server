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

-- lab_variant10_variation.sql
-- Цель: Выполнение задания по варианту 10 с альтернативными данными
-- 1. Создание пользователя и проверка подключения
-- 2. Создание схемы базы туристического агентства
-- 3. Наложение ограничений
-- 4. Заполнение данными, тест ограничений
-- 5. Транзакционный блок и откат


-- 1. Создание нового пользователя
-- CREATE USER IF NOT EXISTS travel_user WITH PASSWORD 'travel123' NOCREATEROLE NOCREATEDB;
-- Проверка подключения: в psql выполните \c variant10 travel_user


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
 
 

-- Заполнение таблицы городов (другие города)
INSERT INTO cities (name) VALUES
  ('Владивосток'),('Хабаровск'),('Иркутск'),('Томск'),('Красноярск'),
  ('Пермь'),('Уфа'),('Челябинск'),('Тюмень'),('Омск');
 
 
 
-- Заполнение таблицы руководителей туров (другие фамилии и даты)
INSERT INTO leaders (last_name,birth_date) VALUES
  ('Смирнов','1982-03-15'),
  ('Кузьмин','1993-08-22'),
  ('Орлов','1997-11-18'),
  ('Волков','1978-05-12'),
  ('Лебедев','1991-07-03'),
  ('Козлов','1987-12-09'),
  ('Соколов','1996-04-27'),
  ('Богданов','1973-09-14'),
  ('Зайцев','1994-01-30'),
  ('Медведев','1986-10-06');
 
 
 
-- Заполнение таблицы туров (другие цены и даты)
INSERT INTO tours (tour_type,price,start_date,city_id) VALUES
  ('автобусный',8500,'2025-09-25',1),
  ('железнодорожный',22000,'2025-10-12',2),
  ('авиа',35000,'2025-11-08',3),
  ('автобусный',9200,'2025-12-03',4),
  ('железнодорожный',19500,'2025-09-30',5),
  ('авиа',28500,'2025-10-22',6),
  ('автобусный',7800,'2025-11-16',7),
  ('железнодорожный',21000,'2025-12-10',8),
  ('авиа',32000,'2025-09-28',9),
  ('автобусный',8900,'2025-10-18',10);
 
 
 
-- Заполнение таблицы заказов (другие номера заказов и количество участников)
INSERT INTO orders (order_date,order_number,tour_id,leader_id,participants) VALUES
  ('2025-08-15','TRV2001',1,1,12),
  ('2025-08-16','TRV2002',2,2,23),
  ('2025-08-17','TRV2003',3,3,11),
  ('2025-08-18','TRV2004',4,4,24),
  ('2025-08-19','TRV2005',5,5,17),
  ('2025-08-20','TRV2006',6,6,21),
  ('2025-08-21','TRV2007',7,7,13),
  ('2025-08-22','TRV2008',8,8,16),
  ('2025-08-23','TRV2009',9,9,20),
  ('2025-08-24','TRV2010',10,10,14);
 
 
 
-- 5. Транзакция и откат
BEGIN;
INSERT INTO orders (order_date,order_number,tour_id,leader_id,participants) VALUES
  ('2025-08-30','TEST1',1,1,18),
  ('2025-08-30','TEST2',2,2,35);  -- вызовет ошибку и откат (превышено макс. количество участников)
ROLLBACK;
 
 
 
-- Проверка, что данные не добавились
SELECT * FROM orders WHERE order_number IN ('TEST1','TEST2');
 
 
 
-- Просмотр данных
SELECT * FROM cities LIMIT 5;
SELECT * FROM orders WHERE participants > 18;
 
 
 
-- Изменение структуры (добавление столбца)
ALTER TABLE leaders ADD COLUMN email VARCHAR(50);
UPDATE leaders SET email = LOWER(last_name) || '@travel.ru' WHERE id <= 4;
 
 
 
-- Создание представления (таблица из задания)
CREATE VIEW travel_summary AS
SELECT 
    o.order_date,
    l.last_name,
    t.tour_type,
    c.name as destination,
    t.start_date,
    t.price,
    o.participants
FROM orders o
JOIN leaders l ON o.leader_id = l.id  
JOIN tours t ON o.tour_id = t.id
JOIN cities c ON t.city_id = c.id;
 
 
 
-- Просмотр представления
SELECT * FROM travel_summary;

-- Дополнительные запросы для анализа
SELECT 'Статистика по типам туров:' AS info;
SELECT 
    tour_type,
    COUNT(*) as count,
    AVG(price) as avg_price,
    MIN(price) as min_price,
    MAX(price) as max_price
FROM tours 
GROUP BY tour_type;

SELECT 'Топ-3 самых популярных направления:' AS info;
SELECT 
    c.name as city,
    COUNT(o.id) as bookings,
    SUM(o.participants) as total_tourists
FROM orders o
JOIN tours t ON o.tour_id = t.id
JOIN cities c ON t.city_id = c.id
GROUP BY c.name
ORDER BY bookings DESC
LIMIT 3;