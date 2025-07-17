WITH 
    (SELECT MAX(toYear(invoice_date)) 
     FROM manufacturing.analytics 
     WHERE invoice_date >= '2015-01-01') AS latest_year

SELECT
    a.customer_name AS customer,
    formatDateTime(MIN(a.invoice_date), '%Y-%m-%d') AS first_invoice_date,
    formatDateTime(MAX(a.invoice_date), '%Y-%m-%d') AS latest_invoice_date,
    max(a.document_currency) AS currency,

    countIf(DISTINCT a.invoice_number, toYear(a.invoice_date) = latest_year) AS invoice_ytd,
    sumIf(a.invoice_quantity, toYear(a.invoice_date) = latest_year) AS sku_quantity_ytd,
    sumIf(a.total_amount, toYear(a.invoice_date) = latest_year) AS revenue_ytd,

    COUNT(DISTINCT a.invoice_number) AS total_invoices,
    SUM(a.invoice_quantity) AS total_invoice_quantity,
    SUM(a.total_amount) AS total_revenue,

    concat('/pricing/details/', a.customer_name) AS detail_link

FROM manufacturing.analytics AS a
INNER JOIN (
    SELECT DISTINCT customer_name
    FROM manufacturing.analytics
    WHERE invoice_date >= (
        SELECT MAX(invoice_date) - INTERVAL 3 MONTH
        FROM manufacturing.analytics
        WHERE invoice_date >= '2015-01-01'
    )
) AS rc
ON a.customer_name = rc.customer_name
WHERE 
    a.invoice_date >= '2015-01-01'
    AND a.invoice_quantity > 0
GROUP BY a.customer_name
ORDER BY revenue_ytd DESC;
