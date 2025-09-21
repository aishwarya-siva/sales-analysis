USE Superstore
GO

-- Monthly Sales Trend View
IF OBJECT_ID('vw_Monthly_Trends', 'V') IS NOT NULL
DROP VIEW vw_Monthly_Trends
GO

CREATE VIEW vw_Monthly_Trends AS
SELECT
		Order_Year,
		Order_Month,
		Order_Month_Name,
		Order_Quarter,
		COUNT(*) AS Total_Orders,
		COUNT(DISTINCT Customer_ID) AS Unique_Customers,
		COUNT(DISTINCT Product_ID) AS Unique_Products,
		ROUND(SUM(Sales),2) AS Total_Sales,
		ROUND(SUM(Profit),2) AS Total_Profit,
		ROUND(AVG(Sales),2) AS Avg_Order_Value,
		ROUND(SUM(Profit)/NULLIF(SUM(Sales),0) * 100, 2) AS Profit_Margin_Pct,
		SUM(Quantity) AS Total_Quantity,
		ROUND(AVG(Discount), 4) AS Avg_Discount,
		ROUND(AVG(Shipping_Days), 1) AS Avg_Shipping_Days
FROM vw_Superstore_Clean
GROUP BY Order_Year, Order_Month, Order_Month_Name, Order_Quarter
GO


-- Customer Analysis
IF OBJECT_ID('vw_Customer_Analysis', 'V') IS NOT NULL
DROP VIEW vw_Customer_Analysis
GO

CREATE VIEW vw_Customer_Analysis AS
SELECT
	Customer_ID,
	Customer_Name,
	Segment,
	State,
	Region,
	COUNT(*) AS Total_Orders,
	ROUND(SUM(Sales),2) AS Total_Sales,
	ROUND(AVG(Sales),2) AS Avg_Order_Value,
	ROUND(SUM(Profit),2) AS Total_Profit,
	ROUND(SUM(Profit)/NULLIF(SUM(Sales),0) * 100, 2) AS Profit_Margin_Pct,
	SUM(Quantity) AS Total_Quantity,
	COUNT(DISTINCT Category) AS Categories_Purchased,
	COUNT(DISTINCT Product_ID) AS Unique_Products,
	MIN(Order_Date) AS First_Order_Date,
	MAX(Order_Date) AS Last_Order_Date,
	DATEDIFF(DAY, MIN(Order_Date), MAX(Order_Date)) AS Customer_Lifespan_Days,
	ROUND(AVG(Discount),4) AS Avg_Discount,

	CASE
		WHEN COUNT(*) = 1 THEN 'One-time'
		WHEN COUNT(*) >= 2 AND COUNT(*) <= 5 THEN 'Occasional'
		WHEN COUNT(*) >= 6 AND COUNT(*) <= 15 THEN 'Regular'
		ELSE 'Frequent'
	END AS 'Customer_Type',

	CASE
		WHEN SUM(Sales) < 500 THEN 'Low Value'
		WHEN SUM(Sales) >= 500 AND SUM(Sales) < 2000 THEN 'Medium Value'
		WHEN SUM(Sales) >= 2000 AND SUM(Sales) < 5000 THEN 'High Value'
		ELSE 'Very High Value'
	END AS 'Customer_Value_Segment'
FROM vw_Superstore_Clean
GROUP BY Customer_ID,Customer_Name,Segment,State,Region
GO


-- Product Performance View
IF OBJECT_ID('vw_Product_Performance', 'V') IS NOT NULL
DROP VIEW vw_Product_Performance
GO

CREATE VIEW vw_Product_Performance AS
SELECT
	Category,
	Sub_Category,
	COUNT(*) AS Total_Orders,
	COUNT(DISTINCT Customer_ID) AS Unique_Customers,
	COUNT(DISTINCT Product_ID) AS Unique_Products,
	ROUND(SUM(Sales),2) AS Total_Sales,
	ROUND(SUM(Profit),2) AS Total_Profit,
	ROUND(AVG(Sales),2) AS Avg_Order_Value,
	ROUND(SUM(Profit)/NULLIF(SUM(Sales),0) * 100, 2) AS Profit_Margin_Pct,
	SUM(Quantity) AS Total_Quantity_Sold,
	ROUND(AVG(Discount),4) AS Avg_Discount,

	ROW_NUMBER() OVER (PARTITION BY Category ORDER BY SUM(Sales) DESC) AS Sales_Rank_in_Category,
	ROW_NUMBER() OVER (PARTITION BY Category ORDER BY SUM(Profit) DESC) AS Profit_Rank_in_Category
FROM vw_Superstore_Clean
GROUP BY Category, Sub_Category
GO


-- Regional Analysis View
IF OBJECT_ID('vw_Regional_Analysis', 'V') IS NOT NULL
DROP VIEW vw_Regional_Analysis
GO

CREATE VIEW vw_Regional_Analysis AS
SELECT
	Region,
	State,
	COUNT(*) AS Total_Orders,
	COUNT(DISTINCT Customer_ID) AS Unique_Customers,
	COUNT(DISTINCT Product_ID) AS Unique_Products,
	ROUND(SUM(Sales),2) AS Total_Sales,
	ROUND(SUM(Profit),2) AS Total_Profit,
	ROUND(AVG(Sales),2) AS Avg_Order_Value,
	ROUND(SUM(Profit)/NULLIF(SUM(Sales),0) * 100, 2) AS Profit_Margin_Pct,
	SUM(Quantity) AS Total_Quantity,
	ROUND(AVG(Discount), 4) AS Avg_Discount,
	ROUND(AVG(Shipping_Days), 1) AS Avg_Shipping_Days,
	ROUND(SUM(Sales) * 100.0 / SUM(SUM(Sales)) OVER (PARTITION BY Region), 2) as State_Share_of_Region_Sales
FROM vw_Superstore_Clean
GROUP BY Region, State
GO


-- Shipping Analysis View
IF OBJECT_ID('vw_Shipping_Analysis', 'V') IS NOT NULL
DROP VIEW vw_Shipping_Analysis
GO

CREATE VIEW vw_Shipping_Analysis AS
SELECT
	Ship_Mode,
	Shipping_Speed_Category,
	COUNT(*) AS Total_Orders,
	ROUND(SUM(Sales),2) AS Total_Sales,
	ROUND(SUM(Profit),2) AS Total_Profit,
	ROUND(AVG(Sales),2) AS Avg_Order_Value,
	ROUND(AVG(Shipping_Days), 1) AS Avg_Shipping_Days,
	MIN(Shipping_Days) AS Min_Shipping_Days,
	MAX(Shipping_Days) AS Max_Shipping_Day,

	ROUND(SUM(Sales) * 100.0 / SUM(SUM(Sales)) OVER(), 2) AS Sales_Share_Pct,
	ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS Order_Share_Pct
FROM vw_Superstore_Clean
GROUP BY Ship_Mode, Shipping_Speed_Category
GO


-- Discount Impact Analysis View
IF OBJECT_ID('vw_Discount_Impact', 'V') IS NOT NULL
DROP VIEW vw_Discount_Impact
GO

CREATE VIEW vw_Discount_Impact AS
SELECT
	Discount_Category,
	Category,
	COUNT(*) AS Total_Orders,
	ROUND(AVG(Sales),2) AS Avg_Sales,
	ROUND(AVG(Profit),2) AS Avg_Profit,
	ROUND(AVG(Profit_Margin_Pct),2) AS Avg_Profit_Margin_Pct,
	ROUND(SUM(Sales),2) AS Total_Sales,
	ROUND(SUM(Profit),2) AS Total_Profit,
	AVG(Quantity) AS Avg_Quantity,
	ROUND(AVG(Discount), 4) AS Avg_Discount_Rate
FROM vw_Superstore_Clean
GROUP BY Discount_Category, Category
GO


-- Executive Summary View
IF OBJECT_ID('vw_Executive_Summary', 'V') IS NOT NULL
DROP VIEW vw_Executive_Summary
GO

CREATE VIEW vw_Executive_Summary AS
WITH DataYears AS (
	SELECT	
		MIN(Order_Year) as First_Year,
		MAX(Order_Year) as Last_Year,
		MAX(Order_Year)-1 as Previous_Year
	FROM vw_Superstore_Clean
)
SELECT 
	dy.First_Year,
	dy.Last_Year,
	dy.Previous_Year,
	CONCAT(dy.First_Year, ' - ', dy.Last_Year) AS Date_Period,

	(SELECT COUNT(*) FROM vw_Superstore_Clean) as Total_Orders,
    (SELECT COUNT(DISTINCT Customer_ID) FROM vw_Superstore_Clean) as Total_Customers,
    (SELECT COUNT(DISTINCT Product_ID) FROM vw_Superstore_Clean) as Total_Products,
    (SELECT ROUND(SUM(Sales), 0) FROM vw_Superstore_Clean) as Total_Sales,
    (SELECT ROUND(SUM(Profit), 0) FROM vw_Superstore_Clean) as Total_Profit,
    (SELECT ROUND(AVG(Sales), 2) FROM vw_Superstore_Clean) as Avg_Order_Value,
    (SELECT ROUND(SUM(Profit)/SUM(Sales) * 100, 2) FROM vw_Superstore_Clean) as Overall_Profit_Margin,

	(SELECT ROUND(SUM(Sales), 0) FROM vw_Superstore_Clean WHERE Order_Year = dy.Last_Year) as Latest_Year_Sales,
    (SELECT ROUND(SUM(Profit), 0) FROM vw_Superstore_Clean WHERE Order_Year = dy.Last_Year) as Latest_Year_Profit,
    (SELECT COUNT(*) FROM vw_Superstore_Clean WHERE Order_Year = dy.Last_Year) as Latest_Year_Orders,
    
	(SELECT ROUND(SUM(Sales), 0) FROM vw_Superstore_Clean WHERE Order_Year = dy.Previous_Year) as Previous_Year_Sales,
    (SELECT ROUND(SUM(Profit), 0) FROM vw_Superstore_Clean WHERE Order_Year = dy.Previous_Year) as Previous_Year_Profit,
    (SELECT COUNT(*) FROM vw_Superstore_Clean WHERE Order_Year = dy.Previous_Year) as Previous_Year_Orders,

	CASE
		WHEN (SELECT SUM(Sales) FROM vw_Superstore_Clean WHERE Order_Year = dy.Previous_Year) > 0 THEN
			ROUND(
				((SELECT SUM(Sales) FROM vw_Superstore_Clean WHERE Order_Year = dy.Last_Year) - 
				(SELECT SUM(Sales) FROM vw_Superstore_Clean WHERE Order_Year = dy.Previous_Year)) * 100.0 / 
				(SELECT SUM(Sales) FROM vw_Superstore_Clean WHERE Order_Year = dy.Previous_Year), 2
			)	
		ELSE NULL
	END AS Sales_Growth_Rate_Pct,

	(SELECT TOP 1 Category FROM vw_Product_Performance ORDER BY Total_Sales DESC) AS Top_Category_by_Sales,
	(SELECT TOP 1 Region FROM vw_Regional_Analysis ORDER BY Total_Sales DESC) AS Top_Region_by_Sales,
	(SELECT TOP 1 Customer_Name FROM vw_Customer_Analysis ORDER BY Total_Sales DESC) AS Top_Customer_by_Sales,
	(SELECT TOP 1 Segment FROM vw_Customer_Analysis GROUP BY Segment ORDER BY SUM(Total_Sales) DESC) AS Top_Segment
FROM DataYears dy
GO