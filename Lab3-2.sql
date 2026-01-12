USE AdventureWorks2012;

-- Хранимая процедура со сводной таблицей PIVOT
IF OBJECT_ID('dbo.usp_OrderCountByShipping', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_OrderCountByShipping;
GO

CREATE PROCEDURE dbo.usp_OrderCountByShipping
    @ShipMethods NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @SQL NVARCHAR(MAX);
    
    -- Динамический SQL для PIVOT
    SET @SQL = '
    SELECT 
        EmployeeID,
        ' + @ShipMethods + '
    FROM (
        SELECT 
            poh.EmployeeID,
            sm.Name AS ShipMethodName,
            COUNT(poh.PurchaseOrderID) AS OrderCount
        FROM Purchasing.PurchaseOrderHeader poh
        INNER JOIN Purchasing.ShipMethod sm ON poh.ShipMethodID = sm.ShipMethodID
        GROUP BY poh.EmployeeID, sm.Name
    ) AS SourceTable
    PIVOT (
        SUM(OrderCount)
        FOR ShipMethodName IN (' + @ShipMethods + ')
    ) AS PivotTable
    ORDER BY EmployeeID;';
    
    -- Выполнение динамического SQL
    EXEC sp_executesql @SQL;
END;
GO

-- Тестирование хранимой процедуры 
EXECUTE dbo.usp_OrderCountByShipping '[CARGO TRANSPORT 5],[OVERNIGHT J-FAST],[OVERSEAS - DELUXE]';
GO