USE Superstore
GO

PRINT ('=== INTERMEDIATE ANALYSIS ===');

PRINT('YEAR-OVER-YEAR GROWTH ANALYSIS');
-- Yearly Analysis
WITH YearlyGrowth AS (
	SELECT
		Order_Year,
		SUM(Sales) AS Annual_Sales,
		SUM(Profit) AS Annual_Profit,
		COUNT(*) AS Annual_Orders,
		COUNT(DISTINCT Customer_ID) AS Annual_Customers,
		LAG(SUM(Sales)) OVER (ORDER BY Order_Year) AS Previous_Year_Sales,
		LAG(SUM(Profit)) OVER (ORDER BY Order_Year) AS Previous_Year_Profit
	FROM vw_Superstore_Clean
	GROUP BY Order_Year
)
SELECT
	Order_Year,
	FORMAT(Annual_Sales, 'C0') AS Annual_Sales,
	FORMAT(Annual_Profit, 'C0') AS Annual_Profit,
	Annual_Orders,
	Annual_Customers,

	CASE
		WHEN Previous_Year_Sales IS NOT NULL THEN
			FORMAT((Annual_Sales - Previous_Year_Sales) / Previous_Year_Sales, 'P1')
		ELSE 'N/A'
	END AS Sales_Growth_Rate,

	CASE
		WHEN Previous_Year_Profit IS NOT NULL THEN
			FORMAT((Annual_Profit - Previous_Year_Profit) / Previous_Year_Profit, 'P1')
		ELSE 'N/A'
	END AS Profit_Growth_Rate
FROM YearlyGrowth
ORDER BY Order_Year;


-- Monthly Analysis
WITH MonthlyGrowth AS (
	SELECT 
		Order_Year,
		Order_Month,
		Order_Month_Name,
		SUM(Sales) AS Monthly_Sales,
		LAG(SUM(Sales)) OVER (ORDER BY Order_Year, Order_Month) AS Previous_Month_Sales
	FROM vw_Superstore_Clean
	GROUP BY Order_Year,Order_Month,Order_Month_Name
)
SELECT 
	Order_Year,
	Order_Month_Name,
	FORMAT(Monthly_Sales, 'C0') AS Monthly_Sales,
	CASE
		WHEN Previous_Month_Sales IS NOT NULL THEN
			FORMAT((Monthly_Sales - Previous_Month_Sales) / Previous_Month_Sales, 'P1')
		ELSE 'N/A'
	END AS Month_over_Month_Growth
FROM MonthlyGrowth
ORDER BY Order_Year DESC, Order_Month DESC;


-- Customer Segment Analysis - RFM
PRINT('CUSTOMER SEGMENTATION ANALYSIS');

WITH DataEndDate AS (
	SELECT MAX(Order_Date) AS Analysis_Date
	FROM vw_Superstore_Clean
),
CustomerRFM AS (
	SELECT 
		Customer_ID,
		Customer_Name,
		Segment,
		Region,

		DATEDIFF(DAY, MAX(Order_Date), (SELECT Analysis_Date FROM DataEndDate)) AS Recency_Days,
		COUNT(*) AS Frequency,
		SUM(Sales) AS Monetary_Value,
		AVG(Sales) AS Avg_Order_Value,
		MAX(Order_Date) AS Last_Order_Date,
		(SELECT Analysis_Date FROM DataEndDate) AS Analysis_Date
	FROM vw_Superstore_Clean
	GROUP BY Customer_ID, Customer_Name, Segment, Region
),
RFMScores AS (
	SELECT *,
			NTILE(5) OVER (ORDER BY Recency_Days ASC) AS R_Score,
			NTILE(5) OVER (ORDER BY Frequency ASC) AS F_Score,
			NTILE(5) OVER (ORDER BY Monetary_Value ASC) AS M_Score
	FROM CustomerRFM
),
CustomerSegments AS (
	SELECT 
		Customer_Name,
		Segment,
		Region,
		Last_Order_Date,
		Analysis_Date,
		Recency_Days,
		Frequency,
		FORMAT(Monetary_Value, 'C0') AS Monetary_Value,
		FORMAT(Avg_Order_Value, 'C0') AS Avg_Order_Value,
		R_Score,
		F_Score,
		M_Score,

		CASE
			WHEN R_Score >= 4 AND F_Score >= 4 AND M_Score >= 4 THEN 'Champions'
            WHEN R_Score >= 3 AND F_Score >= 4 AND M_Score >= 3 THEN 'Loyal Customers'
            WHEN R_Score >= 4 AND F_Score <= 2 AND M_Score >= 4 THEN 'Big Spenders'
            WHEN R_Score >= 3 AND F_Score >= 3 AND M_Score >= 3 THEN 'Potential Loyalists'
            WHEN R_Score >= 4 AND F_Score <= 2 AND M_Score <= 3 THEN 'New Customers'
            WHEN R_Score <= 2 AND F_Score >= 3 AND M_Score >= 3 THEN 'At Risk'
            WHEN R_Score <= 2 AND F_Score <= 2 AND M_Score >= 4 THEN 'Cannot Lose Them'
            WHEN R_Score <= 2 AND F_Score >= 3 AND M_Score <= 3 THEN 'Hibernating'
            WHEN R_Score >= 3 AND M_Score <= 2 THEN 'Price Sensitive'
            WHEN R_Score >= 3 AND F_Score <= 2 AND M_Score <= 2 THEN 'Promising'
            WHEN R_Score <= 2 AND F_Score <= 2 AND M_Score <= 2 THEN 'Lost Customers'
            WHEN R_Score = 3 AND F_Score <= 2 AND M_Score <= 2 THEN 'Need Attention'
            WHEN R_Score <= 3 AND F_Score <= 3 AND M_Score <= 3 AND (R_Score + F_Score + M_Score) >= 6 THEN 'About to Sleep'
			ELSE 'Others'
		END AS Customer_Segment
	FROM RFMScores
)
SELECT 
	Customer_Segment, 
	COUNT(*) AS Customer_Count,
	ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(),2) AS Pct_of_Total,
	FORMAT(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 'N2') + '%' AS Pct_Display
FROM CustomerSegments
GROUP BY Customer_Segment
ORDER BY Customer_Count DESC;

SELECT 
    Segment,
    COUNT(*) as Customer_Count,
    FORMAT(AVG(Total_Sales), 'C') as Avg_Customer_Value,
    FORMAT(AVG(Total_Orders), 'N1') as Avg_Orders_per_Customer,
    FORMAT(AVG(Avg_Order_Value), 'C') as Avg_Order_Value,
    AVG(Customer_Lifespan_Days) as Avg_Customer_Lifespan_Days,
    FORMAT(AVG(Total_Sales) / NULLIF(AVG(Customer_Lifespan_Days), 0) * 365, 'C') as Estimated_Annual_Value
FROM vw_Customer_Analysis
GROUP BY Segment
ORDER BY AVG(Total_Sales) DESC;


-- Product Performance 
PRINT('PRODUCT PERFORMANCE ANALYSIS');

-- Product Portfolio Analysis
WITH Thresholds AS (
	SELECT 
		PERCENTILE_CONT(0.8) WITHIN GROUP (ORDER BY Total_Sales) OVER() AS Sales_Threshold,
		AVG(Profit_Margin_Pct) OVER() AS Margin_Threshold
	FROM vw_Product_Performance	
)
SELECT 
	p.Category,
	p.Sub_Category,
	p.Total_Sales,
	p.Total_Profit,
	p.Profit_Margin_Pct,
	p.Total_Orders,
	CASE
		WHEN p.Total_Sales >= MAX(t.Sales_Threshold) 
             AND p.Profit_Margin_Pct >= MAX(t.Margin_Threshold)
        THEN 'Star Products'
		WHEN p.Total_Sales >= MAX(t.Sales_Threshold) 
             AND p.Profit_Margin_Pct < MAX(t.Margin_Threshold)
		THEN 'Question Mark Products'
		WHEN p.Total_Sales < MAX(t.Sales_Threshold) 
             AND p.Profit_Margin_Pct >= MAX(t.Margin_Threshold)
		THEN 'Cash Cow Products'
		ELSE 'Dog Products'
	END AS Product_Classification
FROM vw_Product_Performance p
CROSS JOIN Thresholds t
GROUP BY p.Category, p.Sub_Category, p.Total_Sales, p.Total_Profit, p.Profit_Margin_Pct, p.Total_Orders
ORDER BY p.Total_Sales DESC;

-- Seasonal Product Performance
SELECT 
	Category,
	Order_Quarter_Name,
	COUNT(*) AS Orders,
	FORMAT(SUM(Sales), 'C0') AS Quarterly_Sales,
	FORMAT(AVG(Sales), 'C') AS Avg_Order_Value,
	RANK() OVER (PARTITION BY Category ORDER BY SUM(Sales) DESC) AS Quarter_Rank
FROM vw_Superstore_Clean
GROUP BY Category, Order_Quarter_Name
ORDER BY Category, Quarter_Rank;

-- Product Cross-Sell Analysis (Market Basket Analysis)
WITH ProductPairs AS (
	SELECT
		o1.Customer_ID,
		o1.Order_ID,
		o1.Category as Category1,
		o2.Category as Category2
	FROM vw_Superstore_Clean o1
	JOIN vw_Superstore_Clean o2 ON o1.Order_ID = o2.Order_ID AND o1.Category < o2.Category
)
SELECT
	Category1,
	Category2,
	COUNT(*) AS Times_Bought_Together,
	COUNT(DISTINCT Customer_ID) AS Unique_Customers,
	ROUND(COUNT(DISTINCT pp.Order_ID)*100.0 / (
			SELECT COUNT(DISTINCT Order_ID)
			FROM vw_Superstore_Clean
			WHERE Category IN (pp.Category1, pp.Category2)
			),2) AS Cross_Sell_Rate_Pct
FROM ProductPairs pp
GROUP BY Category1, Category2
HAVING COUNT(*) > 10
ORDER BY Times_Bought_Together;


-- Geographic Analysis
PRINT('GEOGRAPHIC PERFORMANCE ANALYSIS');

WITH RegionalStats AS (
	SELECT
		Region,
		SUM(Sales) AS Region_Sales,
		SUM(Profit) AS Region_Profit,
		COUNT(*) AS Region_Orders,
		COUNT(DISTINCT Customer_ID) AS Region_Customers
	FROM vw_Superstore_Clean
	GROUP BY Region
),
TotalStats AS (
	SELECT 
		SUM(Sales) AS Total_Sales,
		SUM(Profit) AS Total_Profit,
		COUNT(*) AS Total_Orders,
		COUNT(DISTINCT Customer_ID) AS Total_Customers	
	FROM vw_Superstore_Clean
)
SELECT
	r.Region,
	FORMAT(r.Region_Sales, 'C0') AS Region_Sales,
	FORMAT(r.Region_Profit, 'C0') AS Region_Profit,
	r.Region_Orders,
	r.Region_Customers,
	FORMAT(r.Region_Sales / t.Total_Sales, 'P1') AS Sales_Market_Share,
	FORMAT(r.Region_Profit / t.Total_Profit, 'P1') AS Profit_Market_Share,
	FORMAT(r.Region_Profit / r.Region_Sales, 'P1') AS Regional_Profit_Margin,
	FORMAT(r.Region_Sales / r.Region_Customers, 'C') AS Sales_per_Customer,
	FORMAT(r.Region_Sales / r.Region_Orders, 'P1') AS Sales_per_Order
FROM RegionalStats r
CROSS JOIN TotalStats t
ORDER BY r.Region_Sales DESC;


-- State Performance within Regions
SELECT
	Region,
	State,
	FORMAT(Total_Sales, 'C0') AS State_Sales,
	FORMAT(Total_Profit, 'C0') AS State_Profit,
	FORMAT(Profit_Margin_Pct, 'P1') AS Profit_Margin,
	Total_Orders,
	Unique_Customers,
	FORMAT(State_Share_of_Region_Sales, 'P1') AS Share_of_Region,
	RANK() OVER(PARTITION BY Region ORDER BY Total_Sales DESC) AS Rank_in_Region
FROM vw_Regional_Analysis
ORDER BY Region, Rank_in_Region;


-- Time-Based Patterns
PRINT('TIME-BASED PATTERN ANALYSIS');

-- Day of Week Analysis
SELECT	
	Order_Day_Name,
	Order_Day_Of_Week,
	COUNT(*) AS Orders,
	FORMAT(SUM(Sales),'C0') AS Total_Sales,
	FORMAT(AVG(Sales),'C') AS Avg_Order_Value,
	ROUND(COUNT(*)*100.0 / SUM(COUNT(*)) OVER(), 1) AS Pct_of_Orders
FROM vw_Superstore_Clean
GROUP BY Order_Day_Of_Week,Order_Day_Name
ORDER BY Order_Day_Of_Week;

-- Monthly Analysis
SELECT
	Order_Month,
	Order_Month_Name,
	COUNT(*) AS Total_Orders,
	FORMAT(SUM(Sales),'C0') AS Total_Sales,
	FORMAT(AVG(Sales),'C') AS Avg_Order_Value,
	ROUND(SUM(Sales) / (SELECT SUM(Sales) FROM vw_Superstore_Clean) * 100, 1) AS Pct_of_Annual_Sales,
	RANK() OVER(ORDER BY SUM(Sales) DESC) AS Sales_Rank
FROM vw_Superstore_Clean
GROUP BY Order_Month, Order_Month_Name
ORDER BY Order_Month;

-- Holiday(Peak) Season Analysis
SELECT
	CASE 
		WHEN Order_Month IN (11,12) THEN 'Holiday Season (Nov-Dec)'
		WHEN Order_Month IN (6,7,8) THEN 'Summer Season (Jun-Aug)'
		WHEN Order_Month IN (3,4,5) THEN 'Spring Season (Mar-May)'
		ELSE 'Other Months'
	END AS Season,
	COUNT(*) AS Orders,
	FORMAT(SUM(Sales),'C0') AS Sales,
	FORMAT(AVG(Sales),'C') AS Avg_Order_Value,
	FORMAT(SUM(Profit), 'C0') AS Profit,
	FORMAT(SUM(Profit) / SUM(Sales), 'P1') AS Profit_Margin
FROM vw_Superstore_Clean
GROUP BY 
	CASE 
		WHEN Order_Month IN (11,12) THEN 'Holiday Season (Nov-Dec)'
		WHEN Order_Month IN (6,7,8) THEN 'Summer Season (Jun-Aug)'
		WHEN Order_Month IN (3,4,5) THEN 'Spring Season (Mar-May)'
		ELSE 'Other Months'
	END
ORDER BY SUM(Sales) DESC;


-- Shipping and Operations Analysis
PRINT('SHIPPING AND OPERATION ANALYSIS');

-- Shipping Performance by Region and Mode
SELECT
	Region,
	Ship_Mode,
	COUNT(*) AS Orders,
	FORMAT(SUM(Sales), 'C0') AS Sales,
	ROUND(AVG(Shipping_Days), 1) AS Avg_Shipping_Days,
	MIN(Shipping_Days) AS Min_Days,
	MAX(Shipping_Days) AS Max_Days,
	ROUND(STDEV(Shipping_Days), 1) AS Shipping_Days_StdDev,
	SUM(CASE WHEN Shipping_Days <= 3 THEN 1 ELSE 0 END) AS Fast_Deliveries,
	FORMAT(SUM(CASE WHEN Shipping_Days <= 3 THEN 1 ELSE 0 END)*100.0 / COUNT(*), 'N1') + '%' AS Fast_Delivery_Rate
FROM vw_Superstore_Clean
GROUP BY Region, Ship_Mode
ORDER BY Region, Avg_Shipping_Days;

-- Order Size vs Shipping
SELECT
	Order_Size_Category,
	Ship_Mode,
	COUNT(*) AS Orders,
	ROUND(AVG(Shipping_Days), 1) AS Avg_Shipping_Days,
	FORMAT(AVG(Sales),'C') AS Avg_Order_Value,
	ROUND(AVG(Profit_Margin_Pct), 1) AS Avg_Profit_Margin
FROM vw_Superstore_Clean
GROUP BY Order_Size_Category, Ship_Mode
ORDER BY 
	CASE Order_Size_Category
		WHEN 'Small (<$100)' THEN 1 
		WHEN 'Medium ($100-$499)' THEN 2
		WHEN 'Large ($500-$999)' THEN 3
		WHEN 'Very Large ($1000+)' THEN 4
	END,
	Ship_Mode;