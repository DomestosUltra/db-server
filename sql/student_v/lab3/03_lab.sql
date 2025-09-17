-- lab3_variant10_alternative.sql
-- Лабораторная работа №3: Использование агрегатных функций и массивов в среде PostgreSQL
-- Вариант 10: Туристическое агентство (альтернативная версия)

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
    ('Кавказские вершины', ARRAY[9,8,7,9,8], 'Горный туризм, комфорт, безопасность, экипировка, гид'),
    ('Камчатка дикая', ARRAY[10,9,6,10,9], 'Экстремальный туризм высшего класса'),
    ('Алтайские просторы', ARRAY[8,7,9,7,8], 'Эко-туризм среднего уровня'),
    ('Карельские озера', ARRAY[7,8,10,8,9], 'Водный туризм премиум'),
    ('Уральские тайны', ARRAY[NULL,9,8,6,7], 'Один критерий в разработке'),
    ('Дальневосточный экспресс', ARRAY[]::INTEGER[], 'Новое направление без рейтингов');

-- 4. Вставка данных в таблицу с многомерным массивом (минимум 6 записей)
INSERT INTO schedule_matrix (leader_name, monthly_schedule, notes) VALUES
    ('Белкин', ARRAY[['Пт','Сб','Вс','Пн','Вт'],['Ср','Чт','Пт','Сб','Вс']], 'Октябрь 1-2 недели'),
    ('Рогов', ARRAY[['Выходной','Выходной','Выходной','Выходной','Выходной'],['Пт','Сб','Вс','Пн','Вт']], 'Первая неделя отдых'),
    ('Зимин', ARRAY[['Ср','Чт','Пт','Сб','Вс'],['Ср','Чт','Пт','Сб','Вс']], 'Постоянный график'),
    ('Громов', ARRAY[['Ср',NULL,'Пт','Сб','Вс'],['Пн','Вт','Ср','Чт','Пт']], 'Четверг - обучение'),
    ('Сокол', ARRAY[['Ср','Чт','Пт','Сб','Вс'],['Пн','Вт',NULL,'Чт','Пт']], 'Среда 2 недели - семинар'),
    ('Орлов', ARRAY[['Чт','Пт','Сб','Вс','Пн'],['Ср','Чт','Пт','Сб','Вс']], 'Смещенный режим');

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

-- Выборка ВСЕХ записей (включая с NULL элементами)
SELECT 'Все туры (включая с неоцененными критериями):' AS info;
SELECT id, tour_name, features, description
FROM tour_features
ORDER BY id;

SELECT 'Все расписания (включая с пропусками):' AS info;
SELECT id, leader_name, monthly_schedule, notes
FROM schedule_matrix
ORDER BY id;

-- Выборка ТОЛЬКО записей с NULL элементами
SELECT 'Туры только с неоцененными критериями:' AS info;
SELECT id, tour_name, features, description
FROM tour_features
WHERE EXISTS (
    SELECT 1 FROM unnest(features) AS u(val) WHERE val IS NULL
) OR array_length(features, 1) IS NULL;

SELECT 'Расписания только с пропусками:' AS info;
SELECT id, leader_name, monthly_schedule, notes
FROM schedule_matrix s
WHERE EXISTS (
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
SET features[1:2] = ARRAY[10,9] 
WHERE tour_name = 'Кавказские вершины';

-- Обновление отдельного элемента массива
UPDATE schedule_matrix 
SET monthly_schedule[1][3] = 'Конференция' 
WHERE leader_name = 'Белкин';

-- Проверка обновлений
SELECT 'После обновлений:' AS info;
SELECT id, tour_name, features FROM tour_features WHERE tour_name = 'Кавказские вершины';
SELECT id, leader_name, monthly_schedule FROM schedule_matrix WHERE leader_name = 'Белкин';

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

-- Заполнение данными (другие города - регионы России)
INSERT INTO cities (name) VALUES
  ('Владикавказ'),('Петропавловск-Камчатский'),('Горно-Алтайск'),('Петрозаводск'),('Магадан'),
  ('Южно-Сахалинск'),('Элиста'),('Якутск'),('Анадырь'),('Салехард');

INSERT INTO leaders (last_name,birth_date) VALUES
  ('Белкин','1981-04-12'),
  ('Рогов','1994-07-28'),
  ('Зимин','1998-10-05'),
  ('Громов','1977-01-18'),
  ('Сокол','1989-05-22'),
  ('Орлов','1986-08-14'),
  ('Лисица','1997-03-09'),
  ('Волк','1972-12-03'),
  ('Медведь','1993-06-17'),
  ('Соболь','1987-09-26');

INSERT INTO tours (tour_type,price,start_date,city_id) VALUES
  ('автобусный',14500,'2025-10-05',1),
  ('железнодорожный',28000,'2025-11-08',2),
  ('авиа',42000,'2025-12-18',3),
  ('автобусный',16200,'2025-09-18',4),
  ('железнодорожный',31000,'2025-10-14',5),
  ('авиа',38000,'2025-11-22',6),
  ('автобусный',13800,'2025-12-02',7),
  ('железнодорожный',25500,'2025-09-24',8),
  ('авиа',45000,'2025-10-11',9),
  ('автобусный',15600,'2025-11-27',10);

INSERT INTO orders (order_date,order_number,tour_id,leader_id,participants) VALUES
  ('2025-08-28','EXP4001',1,1,16),
  ('2025-08-29','EXP4002',2,2,24),
  ('2025-08-30','EXP4003',3,3,12),
  ('2025-08-31','EXP4004',4,4,22),
  ('2025-09-01','EXP4005',5,5,19),
  ('2025-09-02','EXP4006',6,6,25),
  ('2025-09-03','EXP4007',7,7,11),
  ('2025-09-04','EXP4008',8,8,17),
  ('2025-09-05','EXP4009',9,9,23),
  ('2025-09-06','EXP4010',10,10,14);

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

-- 4. Найти среднюю стоимость туров в город Владикавказ
SELECT 'Средняя стоимость туров во Владикавказ:' AS query_name;
SELECT ROUND(AVG(t.price), 2) AS avg_vladikavkaz_price
FROM tours t
JOIN cities c ON t.city_id = c.id
WHERE c.name = 'Владикавказ';

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

-- Статистика по регионам
SELECT 'Статистика заказов по регионам:' AS query_name;
SELECT 
    c.name as region_name,
    COUNT(o.id) as orders_count,
    SUM(o.participants) as total_participants,
    SUM(t.price * o.participants) as total_revenue
FROM orders o
JOIN tours t ON o.tour_id = t.id
JOIN cities c ON t.city_id = c.id
GROUP BY c.name
ORDER BY total_revenue DESC;

-- Статистика по экспедиционным руководителям
SELECT 'Статистика по экспедиционным руководителям:' AS query_name;
SELECT 
    l.last_name,
    l.birth_date,
    DATE_PART('year', AGE(CURRENT_DATE, l.birth_date)) as age,
    COUNT(o.id) as expeditions_led,
    SUM(o.participants) as total_explorers
FROM leaders l
LEFT JOIN orders o ON l.id = o.leader_id
GROUP BY l.id, l.last_name, l.birth_date
ORDER BY expeditions_led DESC;

-- Анализ массивов: статистика рейтингов туров
SELECT 'Статистика рейтингов туров (из массивов):' AS query_name;
SELECT 
    tour_name,
    array_length(features, 1) as criteria_evaluated,
    (SELECT AVG(unnest_val::numeric) FROM unnest(features) AS unnest_val WHERE unnest_val IS NOT NULL) as avg_rating,
    (SELECT MAX(unnest_val::numeric) FROM unnest(features) AS unnest_val WHERE unnest_val IS NOT NULL) as max_rating
FROM tour_features
WHERE features IS NOT NULL AND array_length(features, 1) > 0;

-- Дополнительный анализ: сравнение периодов
SELECT 'Сравнение активности по месяцам:' AS query_name;
SELECT 
    EXTRACT(MONTH FROM order_date) as order_month,
    COUNT(*) as bookings,
    AVG(participants) as avg_group_size,
    SUM(participants) as total_tourists
FROM orders
GROUP BY EXTRACT(MONTH FROM order_date)
ORDER BY order_month;

-- Анализ расписаний: подсчет рабочих дней
SELECT 'Анализ рабочих графиков:' AS query_name;
SELECT 
    leader_name,
    array_length(monthly_schedule, 1) as weeks_planned,
    array_length(monthly_schedule, 2) as days_per_week,
    notes
FROM schedule_matrix
ORDER BY leader_name;