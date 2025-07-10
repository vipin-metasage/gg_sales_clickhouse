SELECT
  result.customer,
  formatDateTime(result.first_invoice_date, '%F') AS first_invoice_date,
  formatDateTime(result.latest_invoice_date, '%F') AS latest_invoice_date,
  result.currency,
  result.invoice_ytd,
  result.sku_quantity_ytd,
  result.revenue_ytd,
  result.total_invoices,
  result.invoice_quantity,
  result.total_revenue,
  '/pricing/details/' || result.customer AS detail_link

FROM (
  SELECT
    b.customer,
    MIN(b.invoice_date) AS first_invoice_date,
    MAX(b.invoice_date) AS latest_invoice_date,
    MAX(b.currency) AS currency,

    COUNT(DISTINCT multiIf(toYear(b.invoice_date) = year_ref.latest_year AND b.invoice_date <= year_ref.latest_date, b.invoice_number, NULL)) AS invoice_ytd,
    SUM(multiIf(toYear(b.invoice_date) = year_ref.latest_year AND b.invoice_date <= year_ref.latest_date, b.invoice_quantity, 0)) AS sku_quantity_ytd,
    SUM(multiIf(toYear(b.invoice_date) = year_ref.latest_year AND b.invoice_date <= year_ref.latest_date, b.total_amount, 0)) AS revenue_ytd,

    COUNT(DISTINCT b.invoice_number) AS total_invoices,
    SUM(b.invoice_quantity) AS invoice_quantity,
    SUM(b.total_amount) AS total_revenue

  FROM (
    SELECT
      customer_name AS customer,
      invoice_date,
      invoice_number,
      total_amount,
      invoice_quantity,
      document_currency AS currency
    FROM manufacturing.analytics
    WHERE
      invoice_date >= toDate('2015-01-01')  
      AND invoice_quantity > 0
      AND customer_name IN (
        SELECT DISTINCT customer_name
        FROM manufacturing.analytics
        WHERE invoice_date >= (
          SELECT MAX(invoice_date) - toIntervalMonth(3)
          FROM manufacturing.analytics
          WHERE invoice_date >= toDate('2015-01-01')
        )
      )
  ) AS b

  CROSS JOIN (
    SELECT
      MAX(invoice_date) AS latest_date,
      MAX(toYear(invoice_date)) AS latest_year
    FROM manufacturing.analytics
    WHERE invoice_date >= toDate('2015-01-01')
  ) AS year_ref

  GROUP BY b.customer
) AS result

ORDER BY result.revenue_ytd DESC