-- Optimized query - eliminates repeated subqueries and improves performance
WITH recent_customers AS (
    SELECT DISTINCT customer_name 
    FROM manufacturing.analytics 
    WHERE invoice_date >= (
        SELECT MAX(invoice_date) - INTERVAL 3 MONTH 
        FROM manufacturing.analytics 
        WHERE invoice_date >= '2015-01-01'
    )
),
max_year AS (
    SELECT MAX(toYear(invoice_date)) as latest_year
    FROM manufacturing.analytics 
    WHERE invoice_date >= '2015-01-01'
)
SELECT 
    customer_name AS customer,
    formatDateTime(MIN(invoice_date), '%Y-%m-%d') AS first_invoice_date,
    formatDateTime(MAX(invoice_date), '%Y-%m-%d') AS latest_invoice_date,
    any(document_currency) AS currency,
    
    -- YTD calculations using the pre-calculated latest year
    countIf(DISTINCT invoice_number, toYear(invoice_date) = my.latest_year) AS invoice_ytd,
    sumIf(invoice_quantity, toYear(invoice_date) = my.latest_year) AS sku_quantity_ytd,
    sumIf(total_amount, toYear(invoice_date) = my.latest_year) AS revenue_ytd,
    
    -- Total calculations
    COUNT(DISTINCT invoice_number) AS total_invoices,
    SUM(invoice_quantity) AS total_invoice_quantity,
    SUM(total_amount) AS total_revenue,
    
    '/pricing/details/' || customer_name AS detail_link
    
FROM manufacturing.analytics ma
CROSS JOIN max_year my
WHERE ma.invoice_date >= '2015-01-01'
    AND ma.invoice_quantity > 0
    AND ma.customer_name IN (SELECT customer_name FROM recent_customers)
GROUP BY customer_name, my.latest_year
ORDER BY revenue_ytd DESC;