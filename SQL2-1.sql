USE AdventureWorks2012;

-- Сначала создадим таблицу dbo.Employee если она не существует
IF OBJECT_ID('dbo.Employee', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Employee (
        BusinessEntityID INT NOT NULL,
        NationalIDNumber NVARCHAR(15) NOT NULL,
        LoginID NVARCHAR(256) NOT NULL,
        JobTitle NVARCHAR(50) NOT NULL,
        BirthDate DATE NOT NULL,
        MaritalStatus NCHAR(1) NOT NULL,
        Gender NCHAR(1) NOT NULL,
        HireDate DATE NOT NULL,
        VacationHours SMALLINT NOT NULL,
        SickLeaveHours SMALLINT NOT NULL,
        ModifiedDate DATETIME NOT NULL
    );

    -- Заполним данными
    INSERT INTO dbo.Employee (
        BusinessEntityID, NationalIDNumber, LoginID, JobTitle, 
        BirthDate, MaritalStatus, Gender, HireDate, 
        VacationHours, SickLeaveHours, ModifiedDate
    )
    SELECT 
        BusinessEntityID, NationalIDNumber, LoginID, JobTitle,
        BirthDate, MaritalStatus, Gender, HireDate,
        144, SickLeaveHours, ModifiedDate  -- VacationHours = 144 по умолчанию
    FROM HumanResources.Employee 
    WHERE JobTitle = 'Buyer';
END
GO

-- a) Добавление поля EmpNum типа int
ALTER TABLE dbo.Employee ADD EmpNum INT;
GO

-- b) и c) 
BEGIN
    DECLARE @EmployeeTable TABLE (
        BusinessEntityID INT,
        NationalIDNumber NVARCHAR(15),
        LoginID NVARCHAR(256),
        JobTitle NVARCHAR(50),
        BirthDate DATE,
        MaritalStatus NCHAR(1),
        Gender NCHAR(1),
        HireDate DATE,
        VacationHours SMALLINT,
        SickLeaveHours SMALLINT,
        ModifiedDate DATE NULL,
        EmpNum INT
    );

    -- Заполнение табличной переменной
    INSERT INTO @EmployeeTable 
    SELECT 
        e.BusinessEntityID, e.NationalIDNumber, e.LoginID, e.JobTitle,
        e.BirthDate, e.MaritalStatus, e.Gender, e.HireDate,
        hr.VacationHours, e.SickLeaveHours, e.ModifiedDate,
        ROW_NUMBER() OVER (ORDER BY e.BusinessEntityID) AS EmpNum
    FROM dbo.Employee e
    INNER JOIN HumanResources.Employee hr ON e.BusinessEntityID = hr.BusinessEntityID;

    -- Обновление полей в dbo.Employee
    UPDATE e
    SET e.VacationHours = CASE WHEN vt.VacationHours = 0 THEN e.VacationHours ELSE vt.VacationHours END,
        e.EmpNum = vt.EmpNum
    FROM dbo.Employee e
    INNER JOIN @EmployeeTable vt ON e.BusinessEntityID = vt.BusinessEntityID;
END
GO

-- d) Удаление данных
DELETE FROM dbo.Employee
WHERE BusinessEntityID IN (
    SELECT p.BusinessEntityID 
    FROM Person.Person p 
    WHERE p.EmailPromotion = 0
);
GO

-- e) Поиск и удаление ограничений
-- Поиск ограничений
SELECT name AS ConstraintName, type_desc AS ConstraintType
FROM sys.objects 
WHERE parent_object_id = OBJECT_ID('dbo.Employee') 
AND type IN ('C', 'D', 'UQ');
GO

-- Удаление поля EmpName если существует
IF COL_LENGTH('dbo.Employee', 'EmpName') IS NOT NULL
    ALTER TABLE dbo.Employee DROP COLUMN EmpName;
GO

-- Удаление всех ограничений
DECLARE @sql NVARCHAR(MAX);
SET @sql = '';

SELECT @sql = @sql + 'ALTER TABLE dbo.Employee DROP CONSTRAINT ' + name + ';'
FROM sys.objects 
WHERE parent_object_id = OBJECT_ID('dbo.Employee') 
AND type IN ('C', 'D', 'UQ');

IF @sql <> '' 
    EXEC sp_executesql @sql;
GO

-- f) Удаление таблицы
IF OBJECT_ID('dbo.Employee', 'U') IS NOT NULL
    DROP TABLE dbo.Employee;
GO