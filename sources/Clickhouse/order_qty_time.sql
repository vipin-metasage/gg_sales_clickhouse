SELECT
    customer_name,
    DATE_TRUNC('month', CAST(invoice_date AS TIMESTAMP)) AS month,
    SUM(invoice_quantity) * 1.0 / COUNT(DISTINCT invoice_number) AS avg_qty_per_order,
    AVG(invoice_quantity) AS average_quantity
FROM manufacturing.analytics
WHERE invoice_date >= '2015-01-01'
GROUP BY customer_name, DATE_TRUNC('month', CAST(invoice_date AS TIMESTAMP))
ORDER BY month;
