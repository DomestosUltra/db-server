-- lab3_variant10.sql
-- Лабораторная работа №3: Использование агрегатных функций и массивов в среде PostgreSQL
-- Вариант 10: Туристическое агентство

-- Настройки psql
\set ECHO all
\timing on
\pset border 2
\pset fieldsep ' | '
\pset recordsep '\n----\n'

-- =============================================================================
-- ЧАСТЬ 1: РАБОТА С МАССИВАМИ
-- =============================================================================

-- 1. Создание таблицы с одномерным массивом
DROP TABLE IF EXISTS tour_features CASCADE;
CREATE TABLE tour_features (
    id SERIAL PRIMARY KEY,
    tour_name VARCHAR(100) NOT NULL,
    features INTEGER[],  -- одномерный массив (рейтинги по критериям 1-10)
    description TEXT
);

-- 2. Создание таблицы с многомерным массивом
DROP TABLE IF EXISTS schedule_matrix CASCADE;
CREATE TABLE schedule_matrix (
    id SERIAL PRIMARY KEY,
    leader_name VARCHAR(50) NOT NULL,
    monthly_schedule TEXT[][],  -- многомерный массив [неделя][день]
    notes TEXT
);

-- 3. Вставка данных в таблицу с одномерным массивом (минимум 6 записей)
INSERT INTO tour_features (tour_name, features, description) VALUES
    ('Золотое кольцо', ARRAY[8,7,9,6,8], 'Комфорт, питание, экскурсии, транспорт, гид'),
    ('Байкал экспресс', ARRAY[9,8,10,7,9], 'Высокий уровень сервиса'),
    ('Крымский тур', ARRAY[7,6,8,8,7], 'Стандартный пакет услуг'),
    ('Сочи релакс', ARRAY[10,9,8,9,10], 'Премиум класс'),
    ('Питерские белые ночи', ARRAY[NULL,8,9,7,8], 'Один критерий не оценен'),
    ('Казанский уикенд', ARRAY[]::INTEGER[], 'Новый тур без оценок');

-- 4. Вставка данных в таблицу с многомерным массивом (минимум 6 записей)
INSERT INTO schedule_matrix (leader_name, monthly_schedule, notes) VALUES
    ('Иванов', ARRAY[['Пн','Вт','Ср','Чт','Пт'],['Сб','Вс','Пн','Вт','Ср']], 'Сентябрь 1-2 недели'),
    ('Петров', ARRAY[['Отпуск','Отпуск','Отпуск','Отпуск','Отпуск'],['Пн','Вт','Ср','Чт','Пт']], 'Первая неделя отпуск'),
    ('Сидоров', ARRAY[['Пн','Вт','Ср','Чт','Пт'],['Пн','Вт','Ср','Чт','Пт']], 'Стандартный график'),
    ('Кузнецов', ARRAY[['Пн',NULL,'Ср','Чт','Пт'],['Сб','Вс','Пн','Вт','Ср']], 'Вторник - больничный'),
    ('Попов', ARRAY[['Пн','Вт','Ср','Чт','Пт'],['Сб','Вс',NULL,'Вт','Ср']], 'Понедельник 2 недели - выходной'),
    ('Васильев', ARRAY[['Ср','Чт','Пт','Сб','Вс'],['Пн','Вт','Ср','Чт','Пт']], 'Сдвинутый график');

-- 5. Выборка без NULL элементов в массивах
SELECT 'Туры без неоцененных критериев:' AS info;
SELECT id, tour_name, features
FROM tour_features
WHERE NOT EXISTS (
    SELECT 1 FROM unnest(features) AS u(val) WHERE val IS NULL
);

SELECT 'Расписания без пропусков:' AS info;
SELECT id, leader_name, monthly_schedule
FROM schedule_matrix s
WHERE NOT EXISTS (
    SELECT 1 
    FROM generate_subscripts(s.monthly_schedule, 1) AS week_idx,
         generate_subscripts(s.monthly_schedule, 2) AS day_idx
    WHERE s.monthly_schedule[week_idx][day_idx] IS NULL
);

-- 6. Выборка с использованием срезов массива
SELECT 'Срезы одномерных массивов (критерии 2-4):' AS info;
SELECT id, tour_name, features[2:4] AS middle_features
FROM tour_features
WHERE array_length(features, 1) >= 4;

SELECT 'Срезы многомерных массивов (вторая неделя, дни 1-3):' AS info;
SELECT id, leader_name, monthly_schedule[2:2][1:3] AS second_week_start
FROM schedule_matrix;

-- 7. Демонстрация функции array_dims()
SELECT 'Размеры массивов:' AS info;
SELECT 
    tf.id,
    tf.tour_name,
    array_dims(tf.features) AS features_dims,
    sm.id,
    sm.leader_name,
    array_dims(sm.monthly_schedule) AS schedule_dims
FROM tour_features tf
CROSS JOIN schedule_matrix sm
WHERE tf.id = 1 AND sm.id = 1;

-- Размеры всех массивов
SELECT id, tour_name, array_dims(features) AS dims FROM tour_features;
SELECT id, leader_name, array_dims(monthly_schedule) AS dims FROM schedule_matrix;

-- 8. Обновление данных - модификация среза массива
UPDATE tour_features 
SET features[1:2] = ARRAY[10,10] 
WHERE tour_name = 'Золотое кольцо';

-- Обновление отдельного элемента массива
UPDATE schedule_matrix 
SET monthly_schedule[1][2] = 'Больничный' 
WHERE leader_name = 'Иванов';

-- Проверка обновлений
SELECT 'После обновлений:' AS info;
SELECT id, tour_name, features FROM tour_features WHERE tour_name = 'Золотое кольцо';
SELECT id, leader_name, monthly_schedule FROM schedule_matrix WHERE leader_name = 'Иванов';

-- =============================================================================
-- ЧАСТЬ 2: ПОДГОТОВКА БАЗЫ ТУРИСТИЧЕСКОГО АГЕНТСТВА
-- =============================================================================

-- Очистка таблиц перед созданием
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS tours CASCADE;
DROP TABLE IF EXISTS leaders CASCADE;
DROP TABLE IF EXISTS cities CASCADE;

-- Создание основных таблиц
CREATE TABLE cities (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL
);

CREATE TABLE leaders (
  id SERIAL PRIMARY KEY,
  last_name VARCHAR(50) NOT NULL,
  birth_date DATE NOT NULL
);

CREATE TABLE tours (
  id SERIAL PRIMARY KEY,
  tour_type VARCHAR(20) NOT NULL,
  price NUMERIC(10,2) NOT NULL,
  start_date DATE NOT NULL,
  city_id INT NOT NULL REFERENCES cities(id)
);

CREATE TABLE orders (
  id SERIAL PRIMARY KEY,
  order_date DATE NOT NULL,
  order_number VARCHAR(20) NOT NULL,
  tour_id INT NOT NULL REFERENCES tours(id),
  leader_id INT NOT NULL REFERENCES leaders(id),
  participants INT NOT NULL
);

-- Заполнение данными
INSERT INTO cities (name) VALUES
  ('Москва'),('Питер'),('Казань'),('Новосибирск'),('Екатеринбург'),
  ('Самара'),('Ростов-на-Дону'),('Волгоград'),('Краснодар'),('Сочи');

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

-- =============================================================================
-- ЧАСТЬ 3: АГРЕГАТНЫЕ ФУНКЦИИ (ВАРИАНТ 10)
-- =============================================================================

-- 1. Найти авиатуры с минимальной стоимостью
SELECT 'Авиатуры с минимальной стоимостью:' AS query_name;
SELECT t.id, t.tour_type, t.price, t.start_date, c.name as city_name
FROM tours t
JOIN cities c ON t.city_id = c.id
WHERE t.tour_type = 'авиа' 
  AND t.price = (SELECT MIN(price) FROM tours WHERE tour_type = 'авиа');

-- 2. Найти железнодорожные туры с максимальной стоимостью
SELECT 'Железнодорожные туры с максимальной стоимостью:' AS query_name;
SELECT t.id, t.tour_type, t.price, t.start_date, c.name as city_name
FROM tours t
JOIN cities c ON t.city_id = c.id
WHERE t.tour_type = 'железнодорожный' 
  AND t.price = (SELECT MAX(price) FROM tours WHERE tour_type = 'железнодорожный');

-- 3. Найти количество автобусных туров
SELECT 'Количество автобусных туров:' AS query_name;
SELECT COUNT(*) AS bus_tours_count
FROM tours 
WHERE tour_type = 'автобусный';

-- 4. Найти среднюю стоимость туров в город Москву
SELECT 'Средняя стоимость туров в Москву:' AS query_name;
SELECT ROUND(AVG(t.price), 2) AS avg_moscow_price
FROM tours t
JOIN cities c ON t.city_id = c.id
WHERE c.name = 'Москва';

-- 5. Найти общую стоимость туров, выполненных руководителями со стажем работы более 10 лет
-- (предполагаем, что стаж = возраст - 25 лет минимального возраста начала работы)
SELECT 'Общая стоимость туров руководителей со стажем >10 лет:' AS query_name;
SELECT SUM(t.price * o.participants) AS total_revenue_experienced
FROM orders o
JOIN tours t ON o.tour_id = t.id
JOIN leaders l ON o.leader_id = l.id
WHERE (DATE_PART('year', AGE(CURRENT_DATE, l.birth_date)) - 25) > 10;

-- =============================================================================
-- ДОПОЛНИТЕЛЬНЫЕ АГРЕГАТНЫЕ ЗАПРОСЫ ДЛЯ АНАЛИЗА
-- =============================================================================

-- Статистика по типам туров
SELECT 'Статистика по типам туров:' AS query_name;
SELECT 
    tour_type,
    COUNT(*) as tours_count,
    MIN(price) as min_price,
    MAX(price) as max_price,
    ROUND(AVG(price), 2) as avg_price,
    SUM(price) as total_price
FROM tours
GROUP BY tour_type
ORDER BY avg_price DESC;

-- Статистика по городам
SELECT 'Статистика заказов по городам:' AS query_name;
SELECT 
    c.name as city_name,
    COUNT(o.id) as orders_count,
    SUM(o.participants) as total_participants,
    SUM(t.price * o.participants) as total_revenue
FROM orders o
JOIN tours t ON o.tour_id = t.id
JOIN cities c ON t.city_id = c.id
GROUP BY c.name
ORDER BY total_revenue DESC;

-- Статистика по руководителям
SELECT 'Статистика по руководителям:' AS query_name;
SELECT 
    l.last_name,
    l.birth_date,
    DATE_PART('year', AGE(CURRENT_DATE, l.birth_date)) as age,
    COUNT(o.id) as orders_count,
    SUM(o.participants) as total_participants
FROM leaders l
LEFT JOIN orders o ON l.id = o.leader_id
GROUP BY l.id, l.last_name, l.birth_date
ORDER BY orders_count DESC;

-- Анализ массивов: статистика оценок туров
SELECT 'Статистика оценок туров (из массивов):' AS query_name;
SELECT 
    tour_name,
    array_length(features, 1) as criteria_count,
    (SELECT AVG(unnest_val::numeric) FROM unnest(features) AS unnest_val WHERE unnest_val IS NOT NULL) as avg_rating
FROM tour_features
WHERE features IS NOT NULL AND array_length(features, 1) > 0;