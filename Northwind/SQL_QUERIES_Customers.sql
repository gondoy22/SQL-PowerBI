--Query for getting lifetime value of a customer--

WITH CustomersAndOrders AS(
	SELECT
		c.CustomerID,
		c.CompanyName,
		MIN(o.OrderDate) AS FirstOrder,
		MAX(o.OrderDate) AS LastOrder,
		SUM(od.Quantity * od.UnitPrice) AS TotalRevenue
	FROM
		Orders o
	JOIN
		Customers c on c.CustomerID = o.CustomerID
	JOIN
		[Order Details] od on od.OrderID = o.OrderID
	GROUP BY
		c.CustomerID, c.CompanyName )

SELECT
	CompanyName,
	FirstOrder,
	LastOrder,
	DATEDIFF(DAY, FirstOrder, LastOrder) As CustomerLifetime,
	TotalRevenue/ NULLIF(DATEDIFF(DAY, FirstOrder, LastOrder),0) As LifetimeValue
FROM
	CustomersAndOrders

--Customer segmentation query--

WITH CustomersRFM AS(
	SELECT
		c.CustomerID,
		c.CompanyName,
		c.Country,
		DATEDIFF(DAY, MAX(o.OrderDate), GETDATE()) As Recency,
		COUNT(DISTINCT o.OrderID) As Frequency,
		SUM(od.Quantity * od.UnitPrice) As Monetary_Value
	FROM
		Orders o 
	JOIN
		[Order Details] od on od.OrderID = o.OrderID
	JOIN
		Customers c on c.CustomerID = o.CustomerID
	GROUP BY
		c.CustomerID,
		c.CompanyName,
		c.Country
),

RFM_scores AS(
	SELECT
		CustomerID, 
		CompanyName,
		Country,
		Recency, 
		Frequency, 
		Monetary_Value,
		NTILE(4) OVER (ORDER BY Recency DESC) AS R_Score, 
		NTILE(4) OVER (ORDER BY Frequency) AS F_Score, 
		NTILE(4) OVER (ORDER BY Monetary_Value) AS M_Score
    FROM 
        CustomersRFM
),

RFM_combined AS(
	SELECT
		CustomerID, 
		CompanyName,
		Country,
		Recency, 
		Frequency, 
		Monetary_Value,
		R_Score,
		F_Score,
		M_score,
		(R_score+F_score+M_score) AS RFM_Total
    FROM 
        RFM_scores
)
SELECT 
	CustomerID,
	CompanyName,
	Country,
	Recency,
	Frequency,
	Monetary_Value,
	R_Score,
	F_score,
	M_score,
	RFM_Total,
	CASE
		WHEN RFM_Total >= 10 THEN 'High-value'
		WHEN RFM_Total BETWEEN 7 AND 9 THEN 'Loyal'
		WHEN RFM_Total BETWEEN 4 AND 6 THEN 'At-Risk'
		ELSE 'New Customer'
	END AS CustomerSegment
FROM
	RFM_combined
ORDER BY
	RFM_Total DESC;


--Query for average monetary value per Customer Segment--

WITH CustomersRFM AS (
    SELECT
        c.CustomerID,
        c.CompanyName,
        c.Country,
        DATEDIFF(DAY, MAX(o.OrderDate), GETDATE()) AS Recency,
        COUNT(DISTINCT o.OrderID) AS Frequency,
        SUM(od.Quantity * od.UnitPrice) AS Monetary_Value
    FROM
        Orders o
    JOIN
        [Order Details] od ON od.OrderID = o.OrderID
    JOIN
        Customers c ON c.CustomerID = o.CustomerID
    GROUP BY
        c.CustomerID,
        c.CompanyName,
        c.Country
),
RFM_scores AS (
    SELECT
        CustomerID,
        CompanyName,
        Country,
        Recency,
        Frequency,
        Monetary_Value,
        NTILE(4) OVER (ORDER BY Recency DESC) AS R_Score,
        NTILE(4) OVER (ORDER BY Frequency) AS F_Score,
        NTILE(4) OVER (ORDER BY Monetary_Value) AS M_Score
    FROM
        CustomersRFM
),
RFM_combined AS (
    SELECT
        CustomerID,
        CompanyName,
        Country,
        Recency,
        Frequency,
        Monetary_Value,
        R_Score,
        F_Score,
        M_Score,
        (R_Score + F_Score + M_Score) AS RFM_Total
    FROM
        RFM_scores
),
CustomerSegments AS (
    SELECT
        CustomerID,
        CompanyName,
        Country,
        Recency,
        Frequency,
        Monetary_Value,
        R_Score,
        F_Score,
        M_Score,
        RFM_Total,
        CASE
            WHEN RFM_Total >= 10 THEN 'High-value'
            WHEN RFM_Total BETWEEN 7 AND 9 THEN 'Loyal'
            WHEN RFM_Total BETWEEN 4 AND 6 THEN 'At-Risk'
            ELSE 'New Customer'
        END AS CustomerSegment
    FROM
        RFM_combined
)
SELECT
    CustomerSegment,
    AVG(Monetary_Value) AS AvgMonetaryValue
FROM
    CustomerSegments
GROUP BY
    CustomerSegment
ORDER BY
    AvgMonetaryValue DESC;


--Query for lifetime value over time--

WITH CustomerRevenue AS (
    SELECT
        o.CustomerID,
        o.OrderDate,
        SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)) AS Revenue
    FROM
        Orders o
    JOIN
        [Order Details] od ON o.OrderID = od.OrderID
    GROUP BY
        o.CustomerID,
        o.OrderDate
),
LTVOverTime AS (
    SELECT
        CustomerID,
        OrderDate,
        SUM(Revenue) OVER (PARTITION BY CustomerID ORDER BY OrderDate) AS CumulativeRevenue
    FROM
        CustomerRevenue
)
SELECT
    c.CompanyName,
    ltv.OrderDate,
    ltv.CumulativeRevenue AS LifetimeValue
FROM
    LTVOverTime ltv
JOIN
    Customers c ON ltv.CustomerID = c.CustomerID
ORDER BY
    CompanyName,
    OrderDate;