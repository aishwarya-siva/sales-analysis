USE Superstore;
GO

-- Executive Dashboard Data

IF OBJECT_ID('vw_Executive_Dashboard', 'V') IS NOT NULL
DROP VIEW vw_Executive_Dashboard
GO

CREATE VIEW vw_Executive_Dashboard AS 
WITH DataYears AS (
	SELECT
		MIN(Order_Year) as First_Year,
        MAX(Order_Year) as Last_Year,
        MAX(Order_Year) - 1 as Previous_Year
	FROM vw_Superstore_Clean
),
KPIMetrics AS (
	SELECT

		SUM(CASE WHEN s.Order_Year = dy.Last_Year THEN s.Sales ELSE 0 END) as Latest_Year_Sales,
        SUM(CASE WHEN s.Order_Year = dy.Last_Year THEN s.Profit ELSE 0 END) as Latest_Year_Profit,
        COUNT(CASE WHEN s.Order_Year = dy.Last_Year THEN 1 END) as Latest_Year_Orders,
        COUNT(DISTINCT CASE WHEN s.Order_Year = dy.Last_Year THEN s.Customer_ID END) as Latest_Year_Customers,

		SUM(CASE WHEN s.Order_Year = dy.Previous_Year THEN s.Sales ELSE 0 END) as Previous_Year_Sales,
        SUM(CASE WHEN s.Order_Year = dy.Previous_Year THEN s.Profit ELSE 0 END) as Previous_Year_Profit,
        COUNT(CASE WHEN s.Order_Year = dy.Previous_Year THEN 1 END) as Previous_Year_Orders,
        COUNT(DISTINCT CASE WHEN s.Order_Year = dy.Previous_Year THEN s.Customer_ID END) as Previous_Year_Customers,

		SUM(s.Sales) as Total_Sales,
        SUM(s.Profit) as Total_Profit,
        COUNT(*) as Total_Orders,
        COUNT(DISTINCT s.Customer_ID) as Total_Customers,
        AVG(s.Sales) as Avg_Order_Value,
        AVG(s.Shipping_Days) as Avg_Shipping_Days,

        MAX(dy.Last_Year) as Current_Year,
        MAX(dy.Previous_Year) as Previous_Year_Value,
        MAX(dy.First_Year) as First_Year

	FROM vw_Superstore_Clean s
	CROSS JOIN DataYears dy
)
SELECT
    Current_Year,
    Previous_Year_Value as Previou_Year,
    First_Year,

    Latest_Year_Sales,
    Latest_Year_Profit,
    Latest_Year_Orders,
    Latest_Year_Customers,

    Previous_Year_Sales,
    Previous_Year_Profit,
    Previous_Year_Orders,
    Previous_Year_Customers,

    CASE
        WHEN Previous_Year_Sales > 0 THEN (Latest_Year_Sales - Previous_Year_Sales) / Previous_Year_Sales
        ELSE NULL
    END as Sales_Growth_Rate,

    CASE 
        WHEN Previous_Year_Profit > 0 THEN (Latest_Year_Profit - Previous_Year_Profit) / Previous_Year_Profit
        ELSE NULL 
    END as Profit_Growth_Rate,

    CASE 
        WHEN Previous_Year_Orders > 0 THEN (Latest_Year_Orders - Previous_Year_Orders) * 1.0 / Previous_Year_Orders
        ELSE NULL 
    END as Orders_Growth_Rate,

    Total_Sales,
    Total_Profit,
    Total_Orders,
    Total_Customers,
    Avg_Order_Value,
    Avg_Shipping_Days,

    CASE WHEN Latest_Year_Sales > 0 THEN Latest_Year_Profit / Latest_Year_Sales ELSE 0 END as Latest_Profit_Margin,
    CASE WHEN Total_Sales > 0 THEN Total_Profit / Total_Sales ELSE 0 END as Overall_Profit_Margin

FROM KPIMetrics;

-- Monthly Sales Trend for Charts

IF OBJECT_ID('vw_Monthly_Sales_Trend', 'V') IS NOT NULL
DROP VIEW vw_Monthly_Sales_Trend
GO

CREATE VIEW vw_Monthly_Sales_Trend AS
SELECT 
    Order_Year,
    Order_Month,
    Order_Month_Name,
    CONCAT(Order_Year, '-', FORMAT(Order_Month, '00')) as Year_Month,
    DATEFROMPARTS(Order_Year, Order_Month, 1) as Date_Key,
    Total_Sales,
    Total_Profit,
    Total_Orders,
    Unique_Customers,
    Avg_Order_Value,
    Profit_Margin_Pct,

    AVG(Total_Sales) OVER (ORDER BY Order_Year, Order_Month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) as Sales_3Month_MA,
    AVG(Total_Profit) OVER (ORDER BY Order_Year, Order_Month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) as Profit_3Month_MA,

    LAG(Total_Sales, 12) OVER (ORDER BY Order_Year, Order_Month) as Sales_Same_Month_PY,
    LAG(Total_Profit, 12) OVER (ORDER BY Order_Year, Order_Month) as Profit_Same_Month_PY
    
FROM vw_Monthly_Trends;


-- Category Performance Excel
IF OBJECT_ID('vw_Category_Performance_Excel', 'V') IS NOT NULL
DROP VIEW vw_Category_Performance_Excel
GO

CREATE VIEW vw_Category_Performance_Excel AS
SELECT 
    Order_Year,
    Order_Quarter_Name as Quarter,
    Order_Month_Name as Month,
    Region,
    Category,
    Sub_Category,
    Segment,
    
    -- Metrics
    COUNT(*) as Order_Count,
    SUM(Sales) as Total_Sales,
    SUM(Profit) as Total_Profit,
    AVG(Sales) as Avg_Order_Value,
    SUM(Quantity) as Total_Quantity,
    COUNT(DISTINCT Customer_ID) as Unique_Customers,
    
    -- Calculated metrics
    CASE WHEN SUM(Sales) > 0 THEN SUM(Profit) / SUM(Sales) ELSE 0 END as Profit_Margin,
    AVG(Discount) as Avg_Discount,
    AVG(Shipping_Days) as Avg_Shipping_Days,
    
    -- Categorizations for filtering
    Profit_Status,
    Discount_Category,
    Order_Size_Category
    
FROM vw_Superstore_Clean
GROUP BY 
    Order_Year, Order_Quarter_Name, Order_Month_Name,
    Region, Category, Sub_Category, Segment,
    Profit_Status, Discount_Category, Order_Size_Category;


-- Customer Analysis
IF OBJECT_ID('vw_Customer_Excel', 'V') IS NOT NULL
DROP VIEW vw_Customer_Excel
GO

CREATE VIEW vw_Customer_Excel AS
WITH DataEndDate AS (
    SELECT MAX(Order_Date) as Analysis_Date FROM vw_Superstore_Clean
)
SELECT 
    c.Customer_ID,
    c.Customer_Name,
    c.Segment,
    c.State,
    c.Region,
    c.Total_Orders,
    c.Total_Sales,
    c.Total_Profit,
    c.Avg_Order_Value,
    c.Customer_Type,
    c.Customer_Value_Segment,
    c.First_Order_Date,
    c.Last_Order_Date,
    c.Customer_Lifespan_Days,
    
    CASE WHEN c.Customer_Lifespan_Days > 0 THEN c.Total_Sales / c.Customer_Lifespan_Days * 365 ELSE c.Total_Sales END as Estimated_Annual_Value,
    DATEDIFF(day, c.Last_Order_Date, d.Analysis_Date) as Days_Since_Last_Order,
    c.Categories_Purchased,
    
    CASE 
        WHEN DATEDIFF(day, c.Last_Order_Date, d.Analysis_Date) <= 90 THEN 'Active'
        WHEN DATEDIFF(day, c.Last_Order_Date, d.Analysis_Date) <= 365 THEN 'At Risk'
        ELSE 'Inactive'
    END as Customer_Status,
    
    NTILE(5) OVER (ORDER BY DATEDIFF(day, c.Last_Order_Date, d.Analysis_Date) ASC) as Recency_Score,
    NTILE(5) OVER (ORDER BY c.Total_Orders DESC) as Frequency_Score,
    NTILE(5) OVER (ORDER BY c.Total_Sales DESC) as Monetary_Score
    
FROM vw_Customer_Analysis c
CROSS JOIN DataEndDate d;


-- Geographic Analysis
IF OBJECT_ID('vw_Geographic_Excel', 'V') IS NOT NULL
DROP VIEW vw_Geographic_Excel
GO

CREATE VIEW vw_Geographic_Excel AS
SELECT 
    Country,
    Region,
    State,
    COUNT(*) as Total_Orders,
    COUNT(DISTINCT Customer_ID) as Unique_Customers,
    SUM(Sales) as Total_Sales,
    SUM(Profit) as Total_Profit,
    AVG(Sales) as Avg_Order_Value,
    SUM(Quantity) as Total_Quantity,
    
    CASE WHEN SUM(Sales) > 0 THEN SUM(Profit) / SUM(Sales) ELSE 0 END as Profit_Margin,
    SUM(Sales) / COUNT(DISTINCT Customer_ID) as Sales_per_Customer,
    COUNT(*) / COUNT(DISTINCT Customer_ID) as Orders_per_Customer,
    AVG(Shipping_Days) as Avg_Shipping_Days,
    AVG(Discount) as Avg_Discount,
    
    RANK() OVER (PARTITION BY Region ORDER BY SUM(Sales) DESC) as Sales_Rank_in_Region,
    RANK() OVER (PARTITION BY Region ORDER BY SUM(Profit) DESC) as Profit_Rank_in_Region,
    
    SUM(Sales) / SUM(SUM(Sales)) OVER (PARTITION BY Region) as Share_of_Region_Sales
    
FROM vw_Superstore_Clean
GROUP BY Country, Region, State;


-- Pivot Table Data
IF OBJECT_ID('vw_Pivot_Ready_Data', 'V') IS NOT NULL
DROP VIEW vw_Pivot_Ready_Data
GO

CREATE VIEW vw_Pivot_Ready_Data AS
SELECT 
    -- Date dimensions
    Order_Date,
    Order_Year,
    Order_Month,
    Order_Month_Name,
    Order_Quarter,
    Order_Quarter_Name,
    Order_Day_Name,
    
    -- Geographic dimensions
    Country,
    Region,
    State,
    City,
    
    -- Customer dimensions
    Customer_ID,
    Customer_Name,
    Segment,
    
    -- Product dimensions
    Category,
    Sub_Category,
    Product_ID,
    Product_Name,
    
    -- Order dimensions
    Order_ID,
    Ship_Mode,
    Shipping_Days,
    Shipping_Speed_Category,
    
    -- Metrics
    Sales,
    Profit,
    Quantity,
    Discount,
    
    -- Calculated metrics
    Profit_Margin_Pct,
    Price_Per_Unit,
    Cost_Per_Unit,
    
    -- Categorical classifications
    Discount_Category,
    Profit_Status,
    Order_Size_Category
    
FROM vw_Superstore_Clean;


-- Dashboard Summary
IF OBJECT_ID('vw_Dashboard_Summary', 'V') IS NOT NULL
DROP VIEW vw_Dashboard_Summary
GO

CREATE VIEW vw_Dashboard_Summary AS
WITH DataPeriod AS (
    SELECT 
        MIN(Order_Date) as Start_Date,
        MAX(Order_Date) as End_Date,
        MIN(Order_Year) as Start_Year,
        MAX(Order_Year) as End_Year
    FROM vw_Superstore_Clean
)
SELECT 
    -- Time dimensions
    dp.Start_Date as Earliest_Order_Date,
    dp.End_Date as Latest_Order_Date,
    CONCAT(dp.Start_Year, ' - ', dp.End_Year) as Analysis_Period,
    
    -- Key metrics
    (SELECT COUNT(*) FROM vw_Superstore_Clean) as Total_Orders,
    (SELECT COUNT(DISTINCT Customer_ID) FROM vw_Superstore_Clean) as Total_Customers,
    (SELECT COUNT(DISTINCT Product_ID) FROM vw_Superstore_Clean) as Total_Products,
    (SELECT SUM(Sales) FROM vw_Superstore_Clean) as Total_Sales,
    (SELECT SUM(Profit) FROM vw_Superstore_Clean) as Total_Profit,
    (SELECT AVG(Sales) FROM vw_Superstore_Clean) as Avg_Order_Value,
    (SELECT SUM(Profit) / SUM(Sales) FROM vw_Superstore_Clean) as Overall_Profit_Margin,
    
    -- Top performers
    (SELECT TOP 1 Category FROM vw_Product_Performance ORDER BY Total_Sales DESC) as Top_Category,
    (SELECT TOP 1 Sub_Category FROM vw_Product_Performance ORDER BY Total_Sales DESC) as Top_Sub_Category,
    (SELECT TOP 1 Region FROM vw_Regional_Analysis ORDER BY Total_Sales DESC) as Top_Region,
    (SELECT TOP 1 State FROM vw_Regional_Analysis ORDER BY Total_Sales DESC) as Top_State,
    (SELECT TOP 1 Customer_Name FROM vw_Customer_Analysis ORDER BY Total_Sales DESC) as Top_Customer,
    (SELECT TOP 1 Segment FROM vw_Customer_Analysis GROUP BY Segment ORDER BY SUM(Total_Sales) DESC) as Top_Segment

FROM DataPeriod dp;

SELECT 
    ROW_NUMBER() OVER (ORDER BY View_Name) as Priority,
    View_Name,
    Purpose,
    Excel_Usage
FROM (
    VALUES 
    ('vw_Executive_Dashboard', 'Key performance indicators', 'KPI Cards, Summary metrics'),
    ('vw_Monthly_Sales_Trend', 'Time series analysis', 'Line charts, Trend analysis'),
    ('vw_Category_Performance_Excel', 'Product analysis', 'Pivot tables, Bar charts'),
    ('vw_Customer_Excel', 'Customer segmentation', 'Scatter plots, Customer analysis'),
    ('vw_Geographic_Excel', 'Regional performance', 'Map charts, Geographic analysis'),
    ('vw_Pivot_Ready_Data', 'Flexible analysis', 'Pivot tables, Slicers, Filters')
) as Guide(View_Name, Purpose, Excel_Usage)
ORDER BY Priority;
