USE Superstore;
GO

-- Data Overview
WITH agg AS	(	
	SELECT COUNT(*) AS total_rec,
			MIN(Order_Date) AS min_date,
			MAX(Order_Date) AS max_date,
			COUNT(DISTINCT Customer_ID) AS cnt_customers,
			COUNT(DISTINCT Product_ID) AS cnt_products,
			COUNT(DISTINCT Order_ID) AS cnt_orders
	FROM dbo.orders
)

SELECT 'Total Records' AS Metric,
		CAST(total_rec AS varchar(20)) AS Value
FROM agg
UNION ALL
SELECT 'Date Range' AS Metric,
		CONCAT(FORMAT(min_date,'MMM dd, yyyy'),
		' to ',
		FORMAT(max_date,'MMM dd, yyyy')
		) AS Value
FROM agg
UNION ALL
SELECT 'Unique Number of Customers',
		CAST(cnt_customers AS varchar(20))
FROM agg
UNION ALL
SELECT 'Unique Number of Products',
		CAST(cnt_products AS varchar(20))
FROM agg
UNION ALL
SELECT 'Unique Number of Orders',
		CAST(cnt_orders AS varchar(20))
FROM agg;

-- Data Null Value Check
SELECT 'Order ID' AS Column_Check, 
		SUM(CASE WHEN Order_ID IS NULL THEN 1 ELSE 0 END) AS Null_Count
FROM orders
UNION ALL
SELECT 'Order Date', SUM(CASE WHEN Order_Date IS NULL THEN 1 ELSE 0 END) FROM orders
UNION ALL
SELECT 'Ship Date', SUM(CASE WHEN Ship_Date IS NULL THEN 1 ELSE 0 END) FROM orders
UNION ALL
SELECT 'Customer ID', SUM(CASE WHEN Customer_ID IS NULL THEN 1 ELSE 0 END) FROM orders
UNION ALL
SELECT 'Product ID', SUM(CASE WHEN Product_ID IS NULL THEN 1 ELSE 0 END) FROM orders
UNION ALL
SELECT 'Sales', SUM(CASE WHEN Sales IS NULL THEN 1 ELSE 0 END) FROM orders
UNION ALL
SELECT 'Profit', SUM(CASE WHEN Profit IS NULL THEN 1 ELSE 0 END) FROM orders;

-- Data Quality Check
SELECT 'Negative Sales' AS Issue,
    COUNT(*) AS Count
FROM orders 
WHERE Sales < 0
UNION ALL
SELECT 'Zero Sales', COUNT(*) FROM orders WHERE Sales = 0
UNION ALL
SELECT 'Zero Quantities', COUNT(*) FROM orders WHERE Quantity <= 0
UNION ALL
SELECT 'Discount > 100%', COUNT(*) FROM orders WHERE Discount > 1;

-- Basic Statistical Summary
SELECT 
    'Sales' AS Metric,
    FORMAT(MIN(Sales), 'C') AS Minimum,
    FORMAT(MAX(Sales), 'C') AS Maximum,
    FORMAT(AVG(Sales), 'C') AS Average,
    FORMAT(SUM(Sales), 'C') AS Total
FROM orders
UNION ALL
SELECT 
    'Profit',
    FORMAT(MIN(Profit), 'C'),
    FORMAT(MAX(Profit), 'C'),
    FORMAT(AVG(Profit), 'C'),
    FORMAT(SUM(Profit), 'C')
FROM orders;

SELECT 
    'Quantity' AS Metric,
    MIN(Quantity) AS Minimum,
    MAX(Quantity) AS Maximum,
    AVG(Quantity) AS Average,
    SUM(Quantity) AS Total
FROM orders;

SELECT 
    'Discount' AS Metric,
    FORMAT(MIN(Discount), 'P') AS Minimum,
    FORMAT(MAX(Discount), 'P') AS Maximum,
    FORMAT(AVG(Discount), 'P') AS Average
FROM orders;

SELECT 
    'Segment Distribution' AS Category,
    Segment AS Value,
    COUNT(*) AS Count,
    FORMAT(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 'N2') + '%' AS Percentage
FROM orders
GROUP BY Segment
ORDER BY COUNT(*) DESC;

SELECT 
    'Category Distribution' AS Category,
    Category AS Value,
    COUNT(*) AS Count,
    FORMAT(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 'N2') + '%' AS Percentage
FROM orders
GROUP BY Category
ORDER BY COUNT(*) DESC;

SELECT 
    'Region Distribution' AS Category,
    Region AS Value,
    COUNT(*) AS Count,
    FORMAT(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 'N2') + '%' AS Percentage
FROM orders
GROUP BY Region
ORDER BY COUNT(*) DESC

SELECT 
       'Ship Mode Distribution' AS Category,
       Ship_Mode as Value,
       COUNT(*) AS Count,
       FORMAT(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 'N2') + '%' AS Percentage
FROM orders
GROUP BY Ship_Mode
ORDER BY COUNT(*) DESC;