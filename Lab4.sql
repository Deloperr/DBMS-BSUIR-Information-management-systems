USE AdventureWorks2012;
GO

-- 1) Employee XML
DECLARE @EmployeeXML XML;
SET @EmployeeXML = (
    SELECT 
        BusinessEntityID AS '@ID',
        NationalIDNumber,
        JobTitle
    FROM HumanResources.Employee
    FOR XML PATH('Employee'), ROOT('Employees')
);

SELECT @EmployeeXML AS EmpXML;

IF OBJECT_ID('tempdb..#EmployeeData') IS NOT NULL
    DROP TABLE #EmployeeData;

CREATE TABLE #EmployeeData (
    BusinessEntityID INT,
    NationalIDNumber NVARCHAR(15),
    JobTitle NVARCHAR(50)
);

INSERT INTO #EmployeeData
SELECT 
    x.value('@ID', 'INT') AS BusinessEntityID,
    x.value('(NationalIDNumber)[1]', 'NVARCHAR(15)') AS NationalIDNumber,
    x.value('(JobTitle)[1]', 'NVARCHAR(50)') AS JobTitle
FROM @EmployeeXML.nodes('/Employees/Employee') AS t(x);

SELECT * FROM #EmployeeData;
GO

-- 2) Product XML и хранимая процедура
IF OBJECT_ID('dbo.usp_ParseProductXML', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_ParseProductXML;
GO

CREATE PROCEDURE dbo.usp_ParseProductXML
    @ProductData XML
AS
BEGIN
    SELECT 
        x.value('@ID', 'INT') AS ProductID,
        x.value('(Name)[1]', 'NVARCHAR(50)') AS Name,
        x.value('(ProductNumber)[1]', 'NVARCHAR(25)') AS ProductNumber
    FROM @ProductData.nodes('/Products/Product') AS t(x);
END;
GO

DECLARE @ProductXML XML;
SET @ProductXML = (
    SELECT 
        ProductID AS '@ID',
        Name,
        ProductNumber
    FROM Production.Product
    FOR XML PATH('Product'), ROOT('Products')
);

SELECT @ProductXML AS PDXML;

EXEC dbo.usp_ParseProductXML @ProductXML;
GO

-- 3) Person XML
DECLARE @PersonXML XML;
SET @PersonXML = (
    SELECT 
        BusinessEntityID AS 'ID',
        FirstName,
        LastName
    FROM Person.Person
    FOR XML PATH('Person'), ROOT('Persons')
);

SELECT @PersonXML AS PXML;

IF OBJECT_ID('tempdb..#PersonData') IS NOT NULL
    DROP TABLE #PersonData;

CREATE TABLE #PersonData (
    BusinessEntityID INT,
    FirstName NVARCHAR(50),
    LastName NVARCHAR(50)
);

INSERT INTO #PersonData
SELECT 
    x.value('(ID)[1]', 'INT') AS BusinessEntityID,
    x.value('(FirstName)[1]', 'NVARCHAR(50)') AS FirstName,
    x.value('(LastName)[1]', 'NVARCHAR(50)') AS LastName
FROM @PersonXML.nodes('/Persons/Person') AS t(x);

SELECT * FROM #PersonData;
GO

-- 4) Vendor XML и хранимая процедура
IF OBJECT_ID('dbo.usp_ParseVendorXML', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_ParseVendorXML;
GO

CREATE PROCEDURE dbo.usp_ParseVendorXML
    @VendorData XML
AS
BEGIN
    SELECT 
        x.value('(ID)[1]', 'INT') AS BusinessEntityID,
        x.value('(Name)[1]', 'NVARCHAR(50)') AS Name,
        x.value('(AccountNumber)[1]', 'NVARCHAR(15)') AS AccountNumber
    FROM @VendorData.nodes('/Vendors/Vendor') AS t(x);
END;
GO

DECLARE @VendorXML XML;
SET @VendorXML = (
    SELECT 
        BusinessEntityID AS 'ID',
        Name,
        AccountNumber
    FROM Purchasing.Vendor
    FOR XML PATH('Vendor'), ROOT('Vendors')
);

SELECT @VendorXML AS XXX;

EXEC dbo.usp_ParseVendorXML @VendorXML;
GO

-- 5) Location XML
DECLARE @LocationXML XML;
SET @LocationXML = (
    SELECT 
        LocationID AS '@ID',
        Name AS '@Name',
        CostRate AS '@Cost'
    FROM Production.Location
    FOR XML PATH('Location'), ROOT('Locations')
);

SELECT @LocationXML;

IF OBJECT_ID('tempdb..#LocationData') IS NOT NULL
    DROP TABLE #LocationData;

CREATE TABLE #LocationData (
    LocationID INT,
    Name NVARCHAR(50),
    CostRate DECIMAL(10,4)
);

INSERT INTO #LocationData
SELECT 
    x.value('@ID', 'INT') AS LocationID,
    x.value('@Name', 'NVARCHAR(50)') AS Name,
    x.value('@Cost', 'DECIMAL(10,4)') AS CostRate
FROM @LocationXML.nodes('/Locations/Location') AS t(x);

SELECT * FROM #LocationData;
GO

-- 6) CreditCard XML и хранимая процедура
IF OBJECT_ID('dbo.usp_ParseCreditCardXML', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_ParseCreditCardXML;
GO

CREATE PROCEDURE dbo.usp_ParseCreditCardXML
    @CreditCardData XML
AS
BEGIN
    SELECT 
        x.value('@ID', 'INT') AS CreditCardID,
        x.value('@Type', 'NVARCHAR(50)') AS CardType,
        x.value('@Number', 'NVARCHAR(25)') AS CardNumber
    FROM @CreditCardData.nodes('/CreditCards/Card') AS t(x);
END;
GO

DECLARE @CreditCardXML XML;
SET @CreditCardXML = (
    SELECT 
        CreditCardID AS '@ID',
        CardType AS '@Type',
        CardNumber AS '@Number'
    FROM Sales.CreditCard
    FOR XML PATH('Card'), ROOT('CreditCards')
);

SELECT @CreditCardXML;

EXEC dbo.usp_ParseCreditCardXML @CreditCardXML;
GO

-- 7) Product с Model XML
DECLARE @ProductModelXML XML;
SET @ProductModelXML = (
    SELECT 
        p.ProductID AS '@ID',
        p.Name,
        (
            SELECT 
                pm.ProductModelID AS '@ID',
                pm.Name
            FROM Production.ProductModel pm
            WHERE pm.ProductModelID = p.ProductModelID
            FOR XML PATH('Model'), TYPE
        )
    FROM Production.Product p
    WHERE p.ProductModelID IS NOT NULL
    FOR XML PATH('Product'), ROOT('Products')
);

Select @ProductModelXML;

IF OBJECT_ID('tempdb..#ProductModelData') IS NOT NULL
    DROP TABLE #ProductModelData;

CREATE TABLE #ProductModelData (
    ProductID INT,
    ProductName NVARCHAR(50),
    ProductModelID INT,
    ModelName NVARCHAR(50)
);

INSERT INTO #ProductModelData
SELECT 
    x.value('@ID', 'INT') AS ProductID,
    x.value('(Name)[1]', 'NVARCHAR(50)') AS ProductName,
    x.value('(Model/@ID)[1]', 'INT') AS ProductModelID,
    x.value('(Model/Name)[1]', 'NVARCHAR(50)') AS ModelName
FROM @ProductModelXML.nodes('/Products/Product') AS t(x);

SELECT * FROM #ProductModelData;
GO

-- 8) Address с Province XML и хранимая процедура
IF OBJECT_ID('dbo.usp_ParseAddressXML', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_ParseAddressXML;
GO

CREATE PROCEDURE dbo.usp_ParseAddressXML
    @AddressData XML
AS
BEGIN
    SELECT 
        x.value('@ID', 'INT') AS AddressID,
        x.value('(City)[1]', 'NVARCHAR(30)') AS City,
        x.value('(Province/@ID)[1]', 'INT') AS StateProvinceID,
        x.value('(Province/Region)[1]', 'NVARCHAR(3)') AS CountryRegionCode
    FROM @AddressData.nodes('/Addresses/Address') AS t(x);
END;
GO

DECLARE @AddressXML XML;
SET @AddressXML = (
    SELECT 
        a.AddressID AS '@ID',
        a.City,
        (
            SELECT 
                sp.StateProvinceID AS '@ID',
                sp.CountryRegionCode AS 'Region'
            FROM Person.StateProvince sp
            WHERE sp.StateProvinceID = a.StateProvinceID
            FOR XML PATH('Province'), TYPE
        )
    FROM Person.Address a
    FOR XML PATH('Address'), ROOT('Addresses')
);
SELECT @AddressXML;

EXEC dbo.usp_ParseAddressXML @AddressXML;
GO

-- 9) EmployeeDepartmentHistory XML
DECLARE @HistoryXML XML;
SET @HistoryXML = (
    SELECT 
        edh.StartDate AS 'Start',
        (
            SELECT 
                d.GroupName AS 'Group',
                d.Name
            FROM HumanResources.Department d
            WHERE d.DepartmentID = edh.DepartmentID
            FOR XML PATH('Department'), TYPE
        )
    FROM HumanResources.EmployeeDepartmentHistory edh
    FOR XML PATH('Transaction'), ROOT('History')
);

SELECT @HistoryXML;

IF OBJECT_ID('tempdb..#DepartmentXMLData') IS NOT NULL
    DROP TABLE #DepartmentXMLData;

CREATE TABLE #DepartmentXMLData (
    DepartmentXML XML
);

INSERT INTO #DepartmentXMLData
SELECT 
    x.query('Department')
FROM @HistoryXML.nodes('/History/Transaction') AS t(x);

SELECT * FROM #DepartmentXMLData;
GO

-- 10) Person с Password XML и хранимая процедура
IF OBJECT_ID('dbo.usp_ParsePasswordXML', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_ParsePasswordXML;
GO

CREATE PROCEDURE dbo.usp_ParsePasswordXML
    @PersonPasswordData XML
AS
BEGIN
    SELECT 
        x.query('Password') AS PasswordXML
    FROM @PersonPasswordData.nodes('/Persons/Person') AS t(x);
END;
GO

DECLARE @PersonPasswordXML XML;
SET @PersonPasswordXML = (
    SELECT TOP 100
        p.FirstName,
        p.LastName,
        (
            SELECT 
                pw.ModifiedDate AS 'Date',
                pw.BusinessEntityID AS 'ID'
            FROM Person.Password pw
            WHERE pw.BusinessEntityID = p.BusinessEntityID
            FOR XML PATH('Password'), TYPE
        )
    FROM Person.Person p
    FOR XML PATH('Person'), ROOT('Persons')
);

SELECT @PersonPasswordXML;

EXEC dbo.usp_ParsePasswordXML @PersonPasswordXML;
GO