--Sales overview query--
SELECT 
    YEAR(O.OrderDate) AS OrderYear, 
    MONTH(O.OrderDate) AS OrderMonth, 
    SUM(OD.UnitPrice * OD.Quantity * (1 - OD.Discount)) AS TotalRevenue, 
    COUNT(DISTINCT O.OrderID) AS TotalOrders,
    SUM(OD.UnitPrice * OD.Quantity * (1 - OD.Discount)) / COUNT(DISTINCT O.OrderID) AS AvgOrderValue
FROM Orders O
JOIN [Order Details] OD ON O.OrderID = OD.OrderID
GROUP BY YEAR(O.OrderDate), MONTH(O.OrderDate)
ORDER BY OrderYear, OrderMonth;


--Top 5 Customers by Revenue
SELECT TOP 5
    C.CustomerID, 
    C.CompanyName, 
    SUM(OD.UnitPrice * OD.Quantity * (1 - OD.Discount)) AS Revenue
FROM Customers C
JOIN Orders O ON C.CustomerID = O.CustomerID
JOIN [Order Details] OD ON O.OrderID = OD.OrderID
GROUP BY C.CustomerID, C.CompanyName
ORDER BY Revenue DESC;


--Sales grouped by categories--
SELECT 
    C.CategoryName, 
    SUM(OD.UnitPrice * OD.Quantity * (1 - OD.Discount)) AS TotalSales
FROM Categories C
JOIN Products P ON C.CategoryID = P.CategoryID
JOIN [Order Details] OD ON P.ProductID = OD.ProductID
GROUP BY C.CategoryName
ORDER BY TotalSales DESC;

--Total Revenue for each month--
SELECT 
    FORMAT(O.OrderDate, 'yyyy-MM') AS OrderMonth, 
    SUM(OD.UnitPrice * OD.Quantity * (1 - OD.Discount)) AS Revenue
FROM Orders O
JOIN [Order Details] OD ON O.OrderID = OD.OrderID
GROUP BY FORMAT(O.OrderDate, 'yyyy-MM')
ORDER BY OrderMonth;


-- Employee performance query--
SELECT 
    E.EmployeeID, 
    E.FirstName + ' ' + E.LastName AS EmployeeName, 
    SUM(OD.UnitPrice * OD.Quantity * (1 - OD.Discount)) AS SalesAmount
FROM Employees E
JOIN Orders O ON E.EmployeeID = O.EmployeeID
JOIN [Order Details] OD ON O.OrderID = OD.OrderID
GROUP BY E.EmployeeID, E.FirstName, E.LastName
ORDER BY SalesAmount DESC;