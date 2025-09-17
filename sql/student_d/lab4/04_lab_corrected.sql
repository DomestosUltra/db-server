-- lab4_variant10_corrected.sql
-- Лабораторная работа №4: Многотабличные запросы и подзапросы в среде PostgreSQL
-- Вариант 10: Туристическое агентство

-- Настройки psql
\set ECHO all
\timing on
\pset border 2
\pset fieldsep ' | '
\pset recordsep '\n----\n'

-- =============================================================================
-- ЧАСТЬ 1: ПОДГОТОВКА РАСШИРЕННОЙ СХЕМЫ БАЗЫ ДАННЫХ
-- =============================================================================

-- Очистка таблиц перед созданием
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS tours CASCADE;
DROP TABLE IF EXISTS leaders CASCADE;
DROP TABLE IF EXISTS cities CASCADE;

-- 1. Создание таблицы городов с добавлением страны
CREATE TABLE cities (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    country VARCHAR(100) NOT NULL
);

-- 2. Создание таблицы руководителей туров
CREATE TABLE leaders (
    id SERIAL PRIMARY KEY,
    last_name VARCHAR(50) NOT NULL,
    birth_date DATE NOT NULL
);

-- 3. Создание таблицы туров с добавлением категории
CREATE TABLE tours (
    id SERIAL PRIMARY KEY,
    tour_type VARCHAR(20) NOT NULL,
    price NUMERIC(10,2) NOT NULL,
    start_date DATE NOT NULL,
    city_id INT NOT NULL REFERENCES cities(id),
    tour_category VARCHAR(50) NOT NULL DEFAULT 'обычный'
);

-- 4. Создание таблицы заказов
CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    order_date DATE NOT NULL,
    order_number VARCHAR(20) NOT NULL,
    tour_id INT NOT NULL REFERENCES tours(id),
    leader_id INT NOT NULL REFERENCES leaders(id),
    participants INT NOT NULL
);

-- Добавление ограничений
ALTER TABLE tours ADD CONSTRAINT tours_type_check
    CHECK (tour_type IN ('автобусный','железнодорожный','авиа'));

ALTER TABLE tours ADD CONSTRAINT tours_price_check
    CHECK (price >= 0);

ALTER TABLE tours ADD CONSTRAINT tours_category_check
    CHECK (tour_category IN ('семейный','шопинг','деловой','экскурсионный','обычный'));

ALTER TABLE orders ADD CONSTRAINT orders_participants_check
    CHECK (participants BETWEEN 1 AND 50);

-- =============================================================================
-- ЧАСТЬ 2: ЗАПОЛНЕНИЕ ДАННЫМИ ДЛЯ ДЕМОНСТРАЦИИ ВСЕХ ЗАПРОСОВ
-- =============================================================================

-- Заполнение таблицы городов (включая Турцию и Египет для 3-го запроса)
INSERT INTO cities (name, country) VALUES
    ('Москва', 'Россия'),          -- id=1
    ('Санкт-Петербург', 'Россия'), -- id=2
    ('Казань', 'Россия'),          -- id=3
    ('Новосибирск', 'Россия'),     -- id=4
    ('Екатеринбург', 'Россия'),    -- id=5
    ('Стамбул', 'Турция'),         -- id=6
    ('Анталья', 'Турция'),         -- id=7
    ('Каир', 'Египет'),            -- id=8
    ('Хургада', 'Египет'),         -- id=9
    ('Шарм-эль-Шейх', 'Египет'),   -- id=10
    ('Париж', 'Франция'),          -- id=11
    ('Милан', 'Италия');           -- id=12

-- Заполнение таблицы руководителей туров
INSERT INTO leaders (last_name, birth_date) VALUES
    ('Иванов', '1980-01-01'),    -- id=1 будет обслуживать только автобусные туры
    ('Петров', '1995-06-15'),    -- id=2 смешанные туры
    ('Сидоров', '1999-12-30'),   -- id=3 только автобусные туры
    ('Кузнецов', '1975-03-20'),  -- id=4 железнодорожные и авиа
    ('Попов', '1990-09-10'),     -- id=5 только автобусные туры
    ('Васильев', '1985-11-25'),  -- id=6 смешанные туры
    ('Михайлов', '1998-07-07'),  -- id=7 только авиа туры
    ('Новиков', '1970-05-05'),   -- id=8 железнодорожные туры
    ('Федоров', '1992-02-14'),   -- id=9 автобусные туры
    ('Морозов', '1988-08-08');   -- id=10 смешанные туры

-- Заполнение таблицы туров
INSERT INTO tours (tour_type, price, start_date, city_id, tour_category) VALUES
    -- Автобусные туры (для демонстрации 1-го запроса) - ids 1-5
    ('автобусный', 15000, '2025-10-01', 1, 'экскурсионный'),
    ('автобусный', 18000, '2025-09-15', 2, 'семейный'),
    ('автобусный', 12000, '2025-11-05', 3, 'обычный'),
    ('автобусный', 22000, '2025-09-20', 4, 'деловой'),
    ('автобусный', 16000, '2025-10-15', 5, 'семейный'),
    
    -- Железнодорожные туры (для демонстрации 2-го запроса) - ids 6-9
    ('железнодорожный', 25000, '2025-09-10', 1, 'экскурсионный'),
    ('железнодорожный', 30000, '2025-09-12', 2, 'семейный'),
    ('железнодорожный', 28000, '2025-09-14', 11, 'шопинг'),
    ('железнодорожный', 32000, '2025-09-16', 12, 'деловой'),
    
    -- Авиатуры в Турцию и Египет (для демонстрации 3-го запроса) - ids 10-14
    ('авиа', 45000, '2025-10-01', 6, 'семейный'),      -- Стамбул, семейный
    ('авиа', 50000, '2025-09-25', 7, 'семейный'),      -- Анталья, семейный
    ('авиа', 48000, '2025-10-10', 8, 'семейный'),      -- Каир, семейный
    ('авиа', 52000, '2025-09-30', 9, 'семейный'),      -- Хургада, семейный
    ('авиа', 55000, '2025-10-05', 10, 'семейный'),     -- Шарм-эль-Шейх, семейный
    
    -- Туры-шопинги (для расчета средней стоимости в 3-м запросе) - ids 15-17
    ('авиа', 35000, '2025-10-01', 11, 'шопинг'),       -- Париж, шопинг
    ('железнодорожный', 20000, '2025-09-25', 12, 'шопинг'), -- Милан, шопинг
    ('авиа', 40000, '2025-10-15', 6, 'шопинг'),        -- Стамбул, шопинг
    
    -- Дополнительные туры для разнообразия - ids 18-20
    ('авиа', 60000, '2025-11-01', 11, 'деловой'),
    ('железнодорожный', 35000, '2025-10-20', 1, 'обычный'),
    ('автобусный', 14000, '2025-11-15', 2, 'экскурсионный');

-- Заполнение таблицы заказов с правильными ссылками
INSERT INTO orders (order_date, order_number, tour_id, leader_id, participants) VALUES
    -- Автобусные туры для руководителей, обслуживающих ТОЛЬКО автобусные туры
    ('2025-09-01', 'ORD001', 1, 1, 15),   -- Иванов - автобусный тур 1
    ('2025-09-05', 'ORD002', 2, 1, 20),   -- Иванов - автобусный тур 2
    ('2025-08-15', 'ORD003', 3, 3, 12),   -- Сидоров - автобусный тур 3
    ('2025-09-10', 'ORD004', 4, 3, 25),   -- Сидоров - автобусный тур 4 (высокая стоимость)
    ('2025-08-20', 'ORD005', 5, 5, 18),   -- Попов - автобусный тур 5
    ('2025-09-12', 'ORD006', 20, 9, 16),  -- Федоров - автобусный тур 20
    
    -- Смешанные туры для других руководителей (исключают их из 1-го запроса)
    ('2025-09-02', 'ORD007', 6, 2, 20),   -- Петров - железнодорожный
    ('2025-08-25', 'ORD008', 1, 2, 15),   -- Петров - также автобусный (смешанный тип)
    ('2025-09-03', 'ORD009', 10, 4, 22),  -- Кузнецов - авиа
    ('2025-09-08', 'ORD010', 7, 6, 14),   -- Васильев - железнодорожный
    ('2025-09-04', 'ORD011', 11, 7, 18),  -- Михайлов - авиа (только авиа)
    
    -- Заказы за последний месяц (сентябрь 2025) для 2-го запроса
    ('2025-09-15', 'ORD012', 2, 1, 20),   -- автобусный тур, сентябрь
    ('2025-09-16', 'ORD013', 6, 8, 25),   -- железнодорожный, сентябрь
    ('2025-09-17', 'ORD014', 11, 7, 15),  -- авиа тур, сентябрь
    
    -- Железнодорожные туры за последние 2 недели (для расчета средней во 2-м запросе)
    ('2025-09-05', 'ORD015', 6, 8, 20),   -- железнодорожный, 2 недели назад
    ('2025-09-10', 'ORD016', 7, 8, 18),   -- железнодорожный, 1 неделя назад
    ('2025-09-12', 'ORD017', 8, 8, 22),   -- железнодорожный, менее недели назад
    ('2025-09-14', 'ORD018', 9, 8, 16),   -- железнодорожный, 3 дня назад
    
    -- Заказы на туры-шопинги (для расчета средней в 3-м запросе)
    ('2025-09-01', 'ORD019', 15, 6, 12),  -- шопинг тур (авиа в Париж)
    ('2025-09-08', 'ORD020', 16, 2, 15),  -- шопинг тур (железнодорожный в Милан)
    ('2025-09-14', 'ORD021', 17, 10, 10); -- шопинг тур (авиа в Стамбул)

-- =============================================================================
-- ЧАСТЬ 3: ВСПОМОГАТЕЛЬНЫЕ ЗАПРОСЫ ДЛЯ АНАЛИЗА ДАННЫХ
-- =============================================================================

-- Просмотр текущих данных для понимания
SELECT 'Обзор данных - Города по странам:' AS info;
SELECT country, COUNT(*) as cities_count, string_agg(name, ', ') as cities
FROM cities 
GROUP BY country 
ORDER BY country;

SELECT 'Обзор данных - Туры по типам и категориям:' AS info;
SELECT tour_type, tour_category, COUNT(*) as count, 
       MIN(price) as min_price, MAX(price) as max_price, ROUND(AVG(price), 2) as avg_price
FROM tours 
GROUP BY tour_type, tour_category 
ORDER BY tour_type, tour_category;

SELECT 'Обзор данных - Заказы по руководителям:' AS info;
SELECT l.last_name, 
       COUNT(o.id) as orders_count,
       string_agg(DISTINCT t.tour_type, ', ') as tour_types_handled
FROM leaders l
LEFT JOIN orders o ON l.id = o.leader_id
LEFT JOIN tours t ON o.tour_id = t.id
GROUP BY l.id, l.last_name
ORDER BY l.last_name;

-- =============================================================================
-- ЧАСТЬ 4: ОСНОВНЫЕ ЗАПРОСЫ СОГЛАСНО ВАРИАНТУ 10
-- =============================================================================

-- ЗАПРОС 1: Найти всех руководителей туров, которые обслуживают только автобусные туры 
-- и выполнившие заказы на туры со стоимостью больше, чем средняя стоимость заказов 
-- на все туры, выполненные за последние три месяца

SELECT 'ЗАПРОС 1: Руководители только автобусных туров с высокими заказами' AS query_name;

WITH avg_order_cost_3m AS (
    -- Подзапрос: средняя стоимость заказов за последние 3 месяца
    SELECT AVG(t.price * o.participants) as avg_cost
    FROM orders o
    JOIN tours t ON o.tour_id = t.id
    WHERE o.order_date >= CURRENT_DATE - INTERVAL '3 months'
),
bus_only_leaders AS (
    -- Подзапрос: руководители, обслуживающие ТОЛЬКО автобусные туры
    SELECT DISTINCT l.id, l.last_name
    FROM leaders l
    JOIN orders o ON l.id = o.leader_id
    JOIN tours t ON o.tour_id = t.id
    WHERE t.tour_type = 'автобусный'
    AND NOT EXISTS (
        -- Исключаем тех, кто обслуживал НЕ автобусные туры
        SELECT 1 
        FROM orders o2 
        JOIN tours t2 ON o2.tour_id = t2.id 
        WHERE o2.leader_id = l.id 
        AND t2.tour_type != 'автобусный'
    )
)
SELECT DISTINCT 
    bol.last_name as leader_name,
    STRING_AGG(DISTINCT o.order_number, ', ') as order_numbers,
    ROUND(AVG(t.price * o.participants), 2) as avg_order_cost,
    (SELECT ROUND(avg_cost, 2) FROM avg_order_cost_3m) as threshold_avg_cost
FROM bus_only_leaders bol
JOIN orders o ON bol.id = o.leader_id
JOIN tours t ON o.tour_id = t.id
WHERE o.order_date >= CURRENT_DATE - INTERVAL '3 months'
AND (t.price * o.participants) > (SELECT avg_cost FROM avg_order_cost_3m)
GROUP BY bol.id, bol.last_name
ORDER BY bol.last_name;

-- ЗАПРОС 2: Найти все туры, выполненные за последний месяц, и со стоимостью больше, 
-- чем средняя стоимость железнодорожных туров, выполненных за последние две недели

SELECT 'ЗАПРОС 2: Туры за месяц дороже средней стоимости ж/д туров за 2 недели' AS query_name;

WITH avg_train_cost_2w AS (
    -- Подзапрос: средняя стоимость железнодорожных туров за последние 2 недели
    SELECT AVG(t.price) as avg_train_price
    FROM orders o
    JOIN tours t ON o.tour_id = t.id
    WHERE t.tour_type = 'железнодорожный'
    AND o.order_date >= CURRENT_DATE - INTERVAL '2 weeks'
)
SELECT 
    t.id as tour_id,
    t.tour_type,
    t.price,
    t.tour_category,
    c.name as city_name,
    c.country,
    o.order_date,
    o.order_number,
    l.last_name as leader_name,
    (SELECT ROUND(avg_train_price, 2) FROM avg_train_cost_2w) as threshold_price
FROM orders o
JOIN tours t ON o.tour_id = t.id
JOIN cities c ON t.city_id = c.id
JOIN leaders l ON o.leader_id = l.id
WHERE o.order_date >= CURRENT_DATE - INTERVAL '1 month'
AND t.price > (SELECT avg_train_price FROM avg_train_cost_2w)
ORDER BY o.order_date DESC, t.price DESC;

-- ЗАПРОС 3: Найти все авиатуры в страны Турция и Египет, предлагаемые для семейного отдыха 
-- и чья стоимость больше, чем средняя стоимость туров, позиционируемых как туры-шопинги

SELECT 'ЗАПРОС 3: Семейные авиатуры в Турцию и Египет дороже средней стоимости шопинг-туров' AS query_name;

WITH avg_shopping_cost AS (
    -- Подзапрос: средняя стоимость туров-шопингов
    SELECT AVG(price) as avg_shopping_price
    FROM tours
    WHERE tour_category = 'шопинг'
)
SELECT 
    t.id as tour_id,
    t.tour_type,
    t.price,
    t.tour_category,
    c.name as city_name,
    c.country,
    t.start_date,
    (SELECT ROUND(avg_shopping_price, 2) FROM avg_shopping_cost) as threshold_price,
    ROUND(t.price - (SELECT avg_shopping_price FROM avg_shopping_cost), 2) as price_difference
FROM tours t
JOIN cities c ON t.city_id = c.id
WHERE t.tour_type = 'авиа'
AND c.country IN ('Турция', 'Египет')
AND t.tour_category = 'семейный'
AND t.price > (SELECT avg_shopping_price FROM avg_shopping_cost)
ORDER BY t.price DESC;

-- =============================================================================
-- ЧАСТЬ 5: ДОПОЛНИТЕЛЬНЫЕ АНАЛИТИЧЕСКИЕ ЗАПРОСЫ
-- =============================================================================

-- Статистика по выполненным запросам
SELECT 'Дополнительная статистика - Средние стоимости по категориям:' AS info;
SELECT 
    tour_category,
    tour_type,
    COUNT(*) as tours_count,
    ROUND(MIN(price), 2) as min_price,
    ROUND(MAX(price), 2) as max_price,
    ROUND(AVG(price), 2) as avg_price
FROM tours
GROUP BY tour_category, tour_type
ORDER BY tour_category, tour_type;

-- Анализ временных рамок
SELECT 'Анализ временных рамок для запросов:' AS info;
SELECT 
    'Последние 3 месяца' as period,
    COUNT(*) as orders_count,
    ROUND(AVG(t.price * o.participants), 2) as avg_order_cost
FROM orders o
JOIN tours t ON o.tour_id = t.id
WHERE o.order_date >= CURRENT_DATE - INTERVAL '3 months'

UNION ALL

SELECT 
    'Последний месяц' as period,
    COUNT(*) as orders_count,
    ROUND(AVG(t.price * o.participants), 2) as avg_order_cost
FROM orders o
JOIN tours t ON o.tour_id = t.id
WHERE o.order_date >= CURRENT_DATE - INTERVAL '1 month'

UNION ALL

SELECT 
    'Последние 2 недели (ж/д туры)' as period,
    COUNT(*) as orders_count,
    ROUND(AVG(t.price), 2) as avg_tour_price
FROM orders o
JOIN tours t ON o.tour_id = t.id
WHERE o.order_date >= CURRENT_DATE - INTERVAL '2 weeks'
AND t.tour_type = 'железнодорожный';

-- Проверка корректности первого запроса - показать всех руководителей и их типы туров
SELECT 'Проверка: Все руководители и типы их туров' AS info;
SELECT 
    l.last_name,
    STRING_AGG(DISTINCT t.tour_type, ', ') as tour_types,
    COUNT(*) as total_orders,
    CASE 
        WHEN STRING_AGG(DISTINCT t.tour_type, ', ') = 'автобусный' THEN 'ТОЛЬКО автобусные'
        ELSE 'Смешанные типы'
    END as classification
FROM leaders l
JOIN orders o ON l.id = o.leader_id
JOIN tours t ON o.tour_id = t.id
GROUP BY l.id, l.last_name
ORDER BY l.last_name;