-- Fixed query - resolved naming conflicts and syntax issues
SELECT 
    customer_name AS customer,
    formatDateTime(MIN(invoice_date), '%Y-%m-%d') AS first_invoice_date,
    formatDateTime(MAX(invoice_date), '%Y-%m-%d') AS latest_invoice_date,
    any(document_currency) AS currency,
    
    -- YTD calculations for the latest year in the dataset
    countIf(DISTINCT invoice_number, toYear(invoice_date) = (SELECT MAX(toYear(invoice_date)) FROM manufacturing.analytics WHERE invoice_date >= '2015-01-01')) AS invoice_ytd,
    
    sumIf(invoice_quantity, toYear(invoice_date) = (SELECT MAX(toYear(invoice_date)) FROM manufacturing.analytics WHERE invoice_date >= '2015-01-01')) AS sku_quantity_ytd,
    
    sumIf(total_amount, toYear(invoice_date) = (SELECT MAX(toYear(invoice_date)) FROM manufacturing.analytics WHERE invoice_date >= '2015-01-01')) AS revenue_ytd,
    
    -- Total calculations
    COUNT(DISTINCT invoice_number) AS total_invoices,
    SUM(invoice_quantity) AS total_invoice_quantity,
    SUM(total_amount) AS total_revenue,
    
    '/pricing/details/' || customer_name AS detail_link
    
FROM manufacturing.analytics
WHERE invoice_date >= '2015-01-01'
    AND invoice_quantity > 0
    AND customer_name IN (
        SELECT DISTINCT customer_name 
        FROM manufacturing.analytics 
        WHERE invoice_date >= (
            SELECT MAX(invoice_date) - INTERVAL 3 MONTH 
            FROM manufacturing.analytics 
            WHERE invoice_date >= '2015-01-01'
        )
    )
GROUP BY customer_name
ORDER BY revenue_ytd DESC;