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

