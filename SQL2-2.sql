USE AdventureWorks2012;

-- a) Выполнение кода из предыдущего задания и добавление полей
-- Сначала создадим таблицу dbo.Employee если она не существует
IF OBJECT_ID('dbo.Employee', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Employee (
        BusinessEntityID INT NOT NULL PRIMARY KEY,
        NationalIDNumber NVARCHAR(15) NOT NULL,
        LoginID NVARCHAR(256) NOT NULL,
        JobTitle NVARCHAR(50) NOT NULL,
        BirthDate DATE NOT NULL,
        MaritalStatus NCHAR(1) NOT NULL,
        Gender NCHAR(1) NOT NULL,
        HireDate DATE NOT NULL,
        VacationHours SMALLINT NOT NULL,
        SickLeaveHours SMALLINT NOT NULL,
        ModifiedDate DATE NULL,
        EmpNum INT,
        SumTotal MONEY,
        SumTaxAmt MONEY,
        WithoutTax AS (ISNULL(SumTotal, 0) - ISNULL(SumTaxAmt, 0)) -- Вычисляемое поле
    );

    -- Заполним данными
    INSERT INTO dbo.Employee (
        BusinessEntityID, NationalIDNumber, LoginID, JobTitle, 
        BirthDate, MaritalStatus, Gender, HireDate, 
        VacationHours, SickLeaveHours, ModifiedDate, EmpNum
    )
    SELECT 
        e.BusinessEntityID, e.NationalIDNumber, e.LoginID, e.JobTitle,
        e.BirthDate, e.MaritalStatus, e.Gender, e.HireDate,
        e.VacationHours, e.SickLeaveHours, e.ModifiedDate,
        ROW_NUMBER() OVER (ORDER BY e.BusinessEntityID) AS EmpNum
    FROM HumanResources.Employee e
    WHERE e.JobTitle = 'Buyer';
END
ELSE
BEGIN
    -- Если таблица существует, добавим новые поля
    IF COL_LENGTH('dbo.Employee', 'SumTotal') IS NULL
        ALTER TABLE dbo.Employee ADD SumTotal MONEY;
    
    IF COL_LENGTH('dbo.Employee', 'SumTaxAmt') IS NULL
        ALTER TABLE dbo.Employee ADD SumTaxAmt MONEY;
    
    IF COL_LENGTH('dbo.Employee', 'WithoutTax') IS NULL
        ALTER TABLE dbo.Employee ADD WithoutTax AS (ISNULL(SumTotal, 0) - ISNULL(SumTaxAmt, 0));
END
GO

-- b) Создание временной таблицы #Employee
CREATE TABLE #Employee (
    BusinessEntityID INT NOT NULL PRIMARY KEY,
    NationalIDNumber NVARCHAR(15) NOT NULL,
    LoginID NVARCHAR(256) NOT NULL,
    JobTitle NVARCHAR(50) NOT NULL,
    BirthDate DATE NOT NULL,
    MaritalStatus NCHAR(1) NOT NULL,
    Gender NCHAR(1) NOT NULL,
    HireDate DATE NOT NULL,
    VacationHours SMALLINT NOT NULL,
    SickLeaveHours SMALLINT NOT NULL,
    ModifiedDate DATE NULL,
    EmpNum INT,
    SumTotal MONEY,
    SumTaxAmt MONEY
);
GO

-- c) Заполнение временной таблицы с использованием CTE
WITH EmployeeSalesCTE AS (
    SELECT 
        poh.EmployeeID AS BusinessEntityID,
        SUM(poh.TotalDue) AS SumTotal,
        SUM(poh.TaxAmt) AS SumTaxAmt
    FROM Purchasing.PurchaseOrderHeader poh
    WHERE poh.EmployeeID IS NOT NULL
    GROUP BY poh.EmployeeID
    HAVING SUM(poh.TotalDue) > 5000000
)
INSERT INTO #Employee (
    BusinessEntityID, NationalIDNumber, LoginID, JobTitle,
    BirthDate, MaritalStatus, Gender, HireDate,
    VacationHours, SickLeaveHours, ModifiedDate, EmpNum,
    SumTotal, SumTaxAmt
)
SELECT 
    e.BusinessEntityID,
    e.NationalIDNumber,
    e.LoginID,
    e.JobTitle,
    e.BirthDate,
    e.MaritalStatus,
    e.Gender,
    e.HireDate,
    e.VacationHours,
    e.SickLeaveHours,
    e.ModifiedDate,
    e.EmpNum,
    es.SumTotal,
    es.SumTaxAmt
FROM dbo.Employee e
INNER JOIN EmployeeSalesCTE es ON e.BusinessEntityID = es.BusinessEntityID;
GO

-- d) Удаление строк из dbo.Employee где MaritalStatus = 'S'
DELETE FROM dbo.Employee 
WHERE MaritalStatus = 'S';
GO

-- e) MERGE выражение
MERGE dbo.Employee AS target
USING #Employee AS source
ON target.BusinessEntityID = source.BusinessEntityID
WHEN MATCHED THEN
    UPDATE SET 
        target.SumTotal = source.SumTotal,
        target.SumTaxAmt = source.SumTaxAmt
WHEN NOT MATCHED BY TARGET THEN
    INSERT (
        BusinessEntityID, NationalIDNumber, LoginID, JobTitle,
        BirthDate, MaritalStatus, Gender, HireDate,
        VacationHours, SickLeaveHours, ModifiedDate, EmpNum,
        SumTotal, SumTaxAmt
    )
    VALUES (
        source.BusinessEntityID, source.NationalIDNumber, source.LoginID, source.JobTitle,
        source.BirthDate, source.MaritalStatus, source.Gender, source.HireDate,
        source.VacationHours, source.SickLeaveHours, source.ModifiedDate, source.EmpNum,
        source.SumTotal, source.SumTaxAmt
    )
WHEN NOT MATCHED BY SOURCE THEN
    DELETE;
GO

-- Проверка результатов
SELECT * FROM dbo.Employee;
GO

-- Очистка временной таблицы
DROP TABLE #Employee;
GO