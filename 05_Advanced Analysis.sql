USE Superstore;
GO

-- Customer Churn Analysis
PRINT('CUSTOMER CHURN ANALYSIS');
WITH DataEndDate AS (
	SELECT
		MAX(Order_Date) AS Analysis_Date
	FROM vw_Superstore_Clean
),
CustomerChurn AS (
	SELECT 
		c.Customer_ID,
		c.Customer_Name,
		c.Segment,
		c.Region,
		c.Last_Order_Date,
		d.Analysis_Date,
		DATEDIFF(DAY, c.Last_Order_Date, d.Analysis_Date) as Days_Since_Last_Order,
		c.Total_Orders,
		c.Total_Sales,
		c.Customer_Value_Segment
	FROM vw_Customer_Analysis c
	CROSS JOIN DataEndDate d
)
SELECT
	Segment,
	Region,
	COUNT(*) AS Total_Customers,
	SUM(CASE WHEN Days_Since_Last_Order > 365 THEN 1 ELSE 0 END) AS Churned_Customers,
	ROUND(SUM(CASE WHEN Days_Since_Last_Order > 365 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS Churn_Rate_Pct,
	FORMAT(AVG(CASE WHEN Days_Since_Last_Order > 365 THEN Total_Sales END), 'C0') AS Avg_Churned_Customer_Value,
	FORMAT(AVG(CASE WHEN Days_Since_Last_Order <= 365 THEN Total_Sales END), 'C0') AS Avg_Active_Customer_Value
FROM CustomerChurn
GROUP BY Segment, Region
ORDER BY Churn_Rate_Pct DESC;


-- Business Insights Summary
PRINT('BUSINESS INSIGHTS SUMMARY');

WITH DataPeriod AS (
	SELECT
		MIN(Order_Date) AS First_Year,
		MAX(Order_Date) AS Last_Year
	FROM vw_Superstore_Clean
)
SELECT
	'Business Summary' AS Report_Section,
	CONCAT('Data Period: ', dp.First_Year, ' to ', dp.Last_Year) AS Time_Period,
	FORMAT((SELECT SUM(Sales) FROM vw_Superstore_Clean), 'C0') AS Total_Revenue,
	FORMAT((SELECT SUM(Profit) FROM vw_Superstore_Clean), 'C0') AS Total_Profit,
	FORMAT((SELECT COUNT(DISTINCT Customer_ID) FROM vw_Superstore_Clean), 'N0') AS Total_Customers,
	FORMAT((SELECT AVG(Sales) FROM vw_Superstore_Clean), 'C0') AS Avg_Order_Value,
	FORMAT((SELECT SUM(Profit) / SUM(Sales) FROM vw_Superstore_Clean), 'P2') AS Overall_Profit_Margin
FROM DataPeriod dp

UNION ALL

SELECT
	'Top Perfomers',
	'Best Categories and Regions',
	(SELECT TOP 1 Category FROM vw_Product_Performance ORDER BY Total_Sales DESC) AS Top_Category,
	(SELECT TOP 1 Region FROM vw_Regional_Analysis ORDER BY Total_Sales DESC) AS Top_Region,
	(SELECT TOP 1 Customer_Value_Segment FROM vw_Customer_Analysis GROUP BY Customer_Value_Segment ORDER BY SUM(Total_Sales) DESC) AS Top_Customer_Segment,
	'N/A',
	'N/A'

UNION ALL

SELECT
	'Growth Story',
	'Revenue Growth Over Time',
	FORMAT((SELECT SUM(Sales) FROM vw_Superstore_Clean WHERE Order_Year = (SELECT MIN(Order_Year) FROM vw_Superstore_Clean)), 'C0') AS First_Year_Sales,
	FORMAT((SELECT SUM(Sales) FROM vw_Superstore_Clean WHERE Order_Year = (SELECT MAX(Order_Year) FROM vw_Superstore_Clean)), 'C0') AS Last_Year_Sales,
	FORMAT(
		((SELECT SUM(Sales) FROM vw_Superstore_Clean WHERE Order_Year = (SELECT MAX(Order_Year) FROM vw_Superstore_Clean)) - 
			 (SELECT SUM(Sales) FROM vw_Superstore_Clean WHERE Order_Year = (SELECT MIN(Order_Year) FROM vw_Superstore_Clean))) * 100.0 / 
			 (SELECT SUM(Sales) FROM vw_Superstore_Clean WHERE Order_Year = (SELECT MIN(Order_Year) FROM vw_Superstore_Clean)), 'P1'
	) AS Total_Growth_Rate,
	'Multi-Year Growth',
	'Positive Trend';


-- Profit Optimization Oppurtunities
PRINT('PROFIT OPTIMIZATION OPPURTUNITIES');

SELECT
	'High Sales Low Margin Products' AS Oppurtunity_Type,
	Category,
	Sub_Category,
	FORMAT(Total_Sales, 'C0') AS Sales_Volume,
	FORMAT(Total_Profit, 'C0') AS Current_Profit,
	FORMAT(Profit_Margin_Pct, 'P2') AS Current_Margin,
	FORMAT((SELECT AVG(Profit_Margin_Pct) FROM vw_Product_Performance), 'P2') AS Avg_Margin,
	'Focus on cost reduction or pricing stratergy' AS Recommendation
FROM vw_Product_Performance
WHERE Total_Sales > (SELECT PERCENTILE_CONT(0.7) WITHIN GROUP(ORDER BY Total_Sales) OVER() FROM vw_Product_Performance ORDER BY Total_Sales OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY)
	AND Profit_Margin_Pct < (SELECT AVG(Profit_Margin_Pct) FROM vw_Product_Performance)
ORDER BY Total_Sales DESC;


-- Customer Value Distribution
PRINT('CUSTOMER VALUE DISTRIBUTION');

SELECT
	Customer_Value_Segment,
	COUNT(*) AS Customer_Count,
	FORMAT(AVG(Total_Sales), 'C0') AS Avg_Customer_Value,
	FORMAT(SUM(Total_Sales), 'C0') AS Segment_Revenue,
	ROUND(SUM(Total_Sales) * 100.0 / (SELECT SUM(Total_Sales) FROM vw_Customer_Analysis), 1) AS Revenue_Share_Pct,
	ROUND(AVG(Total_Orders), 1) AS Avg_Orders_per_Customer,
	CASE
		WHEN Customer_Value_Segment = 'Very High Value' THEN 'VIP treatment, exclusive offers'
		WHEN Customer_Value_Segment = 'High Value' THEN 'Loyalty programs, premium service'
		WHEN Customer_Value_Segment = 'Medium Value' THEN 'Upsell campaigns, engagement programs'
		ELSE 'Acquisition campaigns, basic service'
	END AS Marketing_Strategy
FROM vw_Customer_Analysis
GROUP BY Customer_Value_Segment
ORDER BY SUM(Total_Sales) DESC;

