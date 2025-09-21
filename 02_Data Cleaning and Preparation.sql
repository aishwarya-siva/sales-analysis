USE Superstore;
GO

-- Cleaned Data View

IF OBJECT_ID('vw_Superstore_Clean', 'V') IS NOT NULL
DROP VIEW vw_Superstore_Clean
GO

CREATE VIEW vw_Superstore_Clean AS
SELECT [Row_ID]
      ,[Order_ID]
      ,[Order_Date]
      ,[Ship_Date]
      ,[Ship_Mode]
      ,[Customer_ID]
      ,[Customer_Name]
      ,[Segment]
      ,[Country]
      ,[City]
      ,[State]
      ,[Postal_Code]
      ,[Region]
      ,[Product_ID]
      ,[Category]
      ,[Sub_Category]
      ,[Product_Name]
      ,[Sales]
      ,[Quantity]
      ,[Discount]
      ,[Profit]

      ,YEAR(Order_Date) as Order_Year
      ,MONTH(Order_Date) as Order_Month
      ,DATENAME(MONTH, Order_Date) AS Order_Month_Name
      ,DATEPART(QUARTER, Order_Date) AS Order_Quarter
      ,DATENAME(QUARTER, Order_Date) AS Order_Quarter_Name
      ,DATEPART(WEEKDAY, Order_Date) AS Order_Day_Of_Week
      ,DATENAME(WEEKDAY, Order_Date) AS Order_Day_Name
      ,DATEDIFF(DAY, Order_Date, Ship_Date) AS Shipping_Days

      ,ROUND(Sales * Quantity, 2) AS Total_Revenue
      ,ROUND(Profit/NULLIF(Sales,0) * 100, 2) AS Profit_Margin_Pct
      ,(Sales - Profit) AS Cost_of_Good
      ,ROUND((Sales - Profit)/NULLIF(Quantity,0), 2) AS Cost_Per_Unit
      ,ROUND(Sales/NULLIF(Quantity,0), 2) AS Price_Per_Unit

      ,CASE
            WHEN Discount = 0 THEN 'No Discount'
            WHEN Discount>0 AND Discount<=0.1 THEN 'Low (1-10%)'
            WHEN Discount>0.1 AND Discount<=0.3 THEN 'Medium (11-30%)'
            WHEN Discount>0.3 AND Discount<=0.5 THEN 'High (30-50%)'
            ELSE 'Very High (50%+)'
        END AS Discount_Category

        ,CASE
            WHEN Profit>0 THEN 'Profitable'
            WHEN Profit=0 THEN 'Break-Even'
            ELSE 'Loss'
        END AS Profit_Status

        ,CASE
            WHEN Sales<100 THEN 'Small (<$100)'
            WHEN Sales>=100 AND Sales<500 THEN 'Medium (<$100-$499)'
            WHEN Sales>=500 AND Sales<1000 THEN 'Medium (<$500-$999)'
            ELSE 'Very High ($1000+)'
        END AS Order_Size_Category

        ,CASE
            WHEN DATEDIFF(DAY, Order_Date, Ship_Date) = 0 THEN 'Same Day'
            WHEN DATEDIFF(DAY, Order_Date, Ship_Date) = 1 THEN 'Next Day'
            WHEN DATEDIFF(DAY, Order_Date, Ship_Date) <= 3 THEN 'Fast (2-3 days)'
            WHEN DATEDIFF(DAY, Order_Date, Ship_Date) <= 7 THEN 'Standard (4-7 days)'
            ELSE 'Slow (8+ days)'
        END AS Shipping_Speed_Category

FROM orders
WHERE Sales>0 AND Quantity>0
GO


-- Customer Master Table
IF OBJECT_ID('vw_Customer_Master','V') IS NOT NULL
DROP VIEW vw_Customer_Master
GO

CREATE VIEW vw_Customer_Master AS
SELECT  Customer_ID,
        Customer_Name,
        Segment,
        Country,
        City,
        State,
        Region
FROM vw_Superstore_Clean
GO


-- Product Master Table
IF OBJECT_ID('vw_Product_Master','V') IS NOT NULL
DROP VIEW vw_Product_Master
GO

CREATE VIEW vw_Product_Master AS
SELECT Product_ID,
        Product_Name,
        Sub_Category,
        Category
FROM vw_Superstore_Clean
GO

-- Data Validation
SELECT 'Original Table' as Source,
        COUNT(*) AS Record_Count
FROM orders
UNION ALL
SELECT 'Cleaned View' as Source,
        COUNT(*) AS Record_Count
FROM vw_Superstore_Clean;


SELECT 'Negative Shipping Days' AS Issue,
        COUNT(*)
FROM vw_Superstore_Clean
WHERE Shipping_Days < 0;


SELECT 'Shipping Days > 30' AS Issue,
        COUNT(*)
FROM vw_Superstore_Clean
WHERE Shipping_Days > 30; 


-- Cleaned Data Summary
SELECT 'Total Orders' AS Metric,
        FORMAT(COUNT(*), 'N0') as Value
FROM vw_Superstore_Clean
UNION ALL
SELECT 'Date Range',
        CONCAT(MIN(Order_Date), ' to ', MAX(Order_Date))
FROM vw_Superstore_Clean
UNION ALL
SELECT 'Total Sales',
    FORMAT(SUM(Sales), 'C0')
FROM vw_Superstore_Clean
UNION ALL
SELECT 'Total Profit',
    FORMAT(SUM(Profit), 'C0')
FROM vw_Superstore_Clean
SELECT 'Average Order Value' AS Metric,
    FORMAT(AVG(Sales), 'C') AS Value
FROM vw_Superstore_Clean
UNION ALL
SELECT 'Overall Profit Margin',
    FORMAT(SUM(Profit)/SUM(Sales), 'P2')
FROM vw_Superstore_Clean