--Считаем кол-во покупателей--
--
SELECT 
    COUNT(customer_id) AS customers_count
FROM customers;

-- выбираем десятку лучших продавцов--
--
SELECT
    e.first_name || ' ' || e.last_name AS seller,
    COUNT(s.sales_id) AS operations, --количество проведенных сделок--
    FLOOR(SUM(s.quantity*p.price)) AS income --суммарная выручка продавца за все время--
FROM sales AS s
INNER JOIN products AS p
    ON s.product_id = p.product_id
INNER JOIN employees AS e
    ON s.sales_person_id = e.employee_id
GROUP BY first_name, last_name
ORDER BY income DESC --выручка сортировка по убыванию--
LIMIT 10; --выбираем 10 лучших--

--отчет с продавцами, чья выручка ниже средней выручки всех продавцов--
--
WITH employees_count AS (
    --считаем кол-во сделок и сумарную выручку--
    SELECT
        e.first_name,
        e.last_name,
        COUNT(s.sales_id) AS operations, --количество проведенных сделок--
        FLOOR(SUM(s.quantity*p.price)) AS income --суммарная выручка продавца за все время--
    FROM sales AS s
    INNER JOIN products AS p
        ON s.product_id = p.product_id
    INNER JOIN employees AS e
        ON s.sales_person_id = e.employee_id
    GROUP BY first_name, last_name
),

average_income_calc AS (
    -- считаем среднюю выручку продавца за сделку с округлением до целого
    SELECT 
        first_name || ' ' || last_name AS seller,
        FLOOR(AVG(income / operations)) AS average_income
    FROM employees_count
    GROUP BY first_name, last_name
),

average_income_all AS (
    -- считаем среднюю выручку за сделку по всем продавцам--
    SELECT (SUM(average_income) / COUNT(seller)) AS average_income_all
    FROM average_income_calc
)

SELECT
    average_income_calc.seller,
    average_income_calc.average_income
FROM average_income_calc
CROSS JOIN average_income_all
WHERE average_income_calc.average_income < average_income_all.average_income_all
-- условие средняя выручка продавца меньше средней выручки по всем продавцам--
ORDER BY average_income;

-- подсчет информации о выручке по дням недели
--
WITH day_of_week_income as(
    SELECT
        first_name || ' ' || last_name AS seller,
        EXTRACT (ISODOW FROM s.sale_date) AS day_of_week_number, -- день недели цифра
        to_char(s.sale_date, 'day') AS day_of_week_text, -- день недели текстом
        SUM(s.quantity*p.price) AS day_of_week_income --суммарная выручка продавца за этот день--
    FROM sales AS s
    INNER JOIN products AS p
        ON s.product_id = p.product_id
    INNER JOIN employees AS e
        ON s.sales_person_id = e.employee_id
    GROUP BY first_name, last_name, s.sale_date
), -- считает выручку в конкретный день недели --

-- считаем сумарную выручку за конкретный день недели для каждого продавца --
sum_table as(
    SELECT
        seller,
        day_of_week_number,
        day_of_week_text,
        FLOOR(SUM(day_of_week_income) OVER(PARTITION BY seller, day_of_week_number)) AS income
    FROM day_of_week_income
)

--выводим финальную таблицу --
SELECT
    seller,
    day_of_week_text AS day_of_week,
    income
    FROM sum_table
GROUP BY seller, day_of_week, income, day_of_week_number
ORDER BY day_of_week_number, seller;

-- количество покупателей в разных возрастных группах: 16-25, 26-40 и 40+
--
WITH age_category_table AS (
    SELECT
        first_name || ' ' || last_name AS customer,
        CASE
    	    WHEN age >= 16 AND age < 26 THEN '16-25'
    	    WHEN age >= 26 AND age <=40 THEN '26-40'
    	    WHEN age > 40 THEN '40+'
    	    ELSE '16-'
        END AS age_category
    FROM customers
)

SELECT
    age_category,
    count(customer) AS age_count
FROM age_category_table
GROUP BY age_category
ORDER BY age_category;

--подсчет количества уникальных покупателей и их выручки
--
WITH customers_loss AS(
    SELECT
        c.first_name || ' ' || c.last_name AS customer,
        SUM(s.quantity*p.price) AS customer_loss,
        to_char(s.sale_date, 'YYYY - MM') AS selling_month
    FROM sales AS s
    INNER JOIN products AS p
        ON s.product_id = p.product_id
    INNER JOIN customers AS c
        ON s.customer_id  = c.customer_id
    GROUP BY c.first_name, c.last_name, s.sale_date
),

count_sum AS(
    SELECT
        selling_month,
        count(customer) OVER (PARTITION BY selling_month) AS total_customers,
        -- подсчет кол-ва покупателей --
        sum(customer_loss) OVER (PARTITION BY selling_month) AS income,
        -- подсчет выручки по каждому покупателю --
        ROW_NUMBER () OVER (PARTITION BY selling_month) AS rn
        -- для вывода только одной строчки --
    FROM customers_loss
    GROUP BY selling_month, customer, customer_loss
)

-- вывод финального результата --
SELECT
    selling_month,
    total_customers,
    income
FROM count_sum
WHERE rn = 1;

--покупатели, первая покупка которых была во время акции
--
WITH temp_table AS (
    SELECT
        c.first_name || ' ' || c.last_name AS customer,
        -- объединяет имя покупателя --
        s.sale_date,
        e.first_name || ' ' || e.last_name AS seller,
        -- объединяет имя продавца --
        p.price,
        ROW_NUMBER() OVER (PARTITION BY c.first_name || ' ' || c.last_name, p.price ) AS rn
    FROM sales AS s
    -- обьединяем все таблицы в одну --
    INNER JOIN products AS p
        ON s.product_id = p.product_id
    INNER JOIN customers AS c
        ON s.customer_id  = c.customer_id
    INNER JOIN employees AS e
        ON s.sales_person_id = e.employee_id
    GROUP BY c.first_name, c.last_name, s.sale_date, e.first_name, e.last_name, p.price
)

-- выводим результат где rn = 1(первая цена) и цена равна 0
SELECT
    customer,
    sale_date,
    seller
FROM temp_table
WHERE rn = 1 AND price = 0;





