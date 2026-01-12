USE AdventureWorks2012;

-- 1. Scalar-valued функция: суммарная стоимость продуктов по модели
IF OBJECT_ID('dbo.ufn_GetTotalModelPrice', 'FN') IS NOT NULL
    DROP FUNCTION dbo.ufn_GetTotalModelPrice;
GO

CREATE FUNCTION dbo.ufn_GetTotalModelPrice(@ProductModelID INT)
RETURNS MONEY
AS
BEGIN
    DECLARE @TotalPrice MONEY;
    
    SELECT @TotalPrice = SUM(ISNULL(ListPrice, 0))
    FROM Production.Product
    WHERE ProductModelID = @ProductModelID;
    
    RETURN ISNULL(@TotalPrice, 0);
END;
GO

SELECT dbo.ufn_GetTotalModelPrice(1) AS TotalPriceForModel1;

-- 2. Inline table-valued функция: 2 последних заказа заказчика
IF OBJECT_ID('dbo.ufn_GetLastTwoOrders', 'IF') IS NOT NULL
    DROP FUNCTION dbo.ufn_GetLastTwoOrders;
GO

CREATE FUNCTION dbo.ufn_GetLastTwoOrders(@CustomerID INT)
RETURNS TABLE
AS
RETURN (
    SELECT TOP 2 
        SalesOrderID,
        OrderDate,
        TotalDue,
        Status
    FROM Sales.SalesOrderHeader
    WHERE CustomerID = @CustomerID
    ORDER BY OrderDate DESC
);
GO

-- Тест

-- Scalar-valued функция
SELECT 
    pm.ProductModelID,
    pm.Name AS ModelName,
    dbo.ufn_GetTotalModelPrice(pm.ProductModelID) AS TotalModelPrice
FROM Production.ProductModel pm
WHERE pm.ProductModelID IN (1, 2, 3, 4, 5);
GO

-- CROSS APPLY - возвращает только заказчиков с заказами
SELECT 
    c.CustomerID,
    c.AccountNumber,
    ord.SalesOrderID,
    ord.OrderDate,
    ord.TotalDue
FROM Sales.Customer c
CROSS APPLY dbo.ufn_GetLastTwoOrders(c.CustomerID) ord
WHERE c.CustomerID IN (
    SELECT TOP 10 CustomerID 
    FROM Sales.SalesOrderHeader 
    GROUP BY CustomerID 
    HAVING COUNT(*) >= 2
    ORDER BY CustomerID
)
ORDER BY c.CustomerID, ord.OrderDate DESC;
GO

-- OUTER APPLY - возвращает всех заказчиков, даже без заказов
SELECT 
    c.CustomerID,
    c.AccountNumber,
    ord.SalesOrderID,
    ord.OrderDate,
    ord.TotalDue
FROM Sales.Customer c
OUTER APPLY dbo.ufn_GetLastTwoOrders(c.CustomerID) ord
ORDER BY c.CustomerID, ord.OrderDate DESC;
GO

-- Сохраняем код inline функции перед изменением
SELECT OBJECT_DEFINITION(OBJECT_ID('dbo.ufn_GetLastTwoOrders')) AS InlineFunctionCode;
GO

-- 3. Multistatement table-valued функция (заменяем inline)
IF OBJECT_ID('dbo.ufn_GetLastTwoOrders_Multi', 'TF') IS NOT NULL
    DROP FUNCTION dbo.ufn_GetLastTwoOrders_Multi;
GO

CREATE FUNCTION dbo.ufn_GetLastTwoOrders_Multi(@CustomerID INT)
RETURNS @LastOrders TABLE (
    SalesOrderID INT,
    OrderDate DATETIME,
    TotalDue MONEY,
    Status TINYINT,
    OrderRank INT
)
AS
BEGIN
    INSERT INTO @LastOrders
    SELECT 
        SalesOrderID,
        OrderDate,
        TotalDue,
        Status,
        ROW_NUMBER() OVER (ORDER BY OrderDate DESC) AS OrderRank
    FROM Sales.SalesOrderHeader
    WHERE CustomerID = @CustomerID;
    
    -- Оставляем только 2 последних заказа
    DELETE FROM @LastOrders WHERE OrderRank > 2;
    
    RETURN;
END;
GO

-- Тестирование multistatement функции
SELECT 
    c.CustomerID,
    c.AccountNumber,
    ord.SalesOrderID,
    ord.OrderDate,
    ord.TotalDue,
    ord.OrderRank
FROM Sales.Customer c
CROSS APPLY dbo.ufn_GetLastTwoOrders_Multi(c.CustomerID) ord
ORDER BY c.CustomerID, ord.OrderRank;
GO
