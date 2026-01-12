USE AdventureWorks2012;

-- a
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

-- b
ALTER TABLE dbo.Employee
ADD CONSTRAINT UK_Employee_NationalIDNumber UNIQUE (NationalIDNumber);

-- c
ALTER TABLE dbo.Employee
ADD CONSTRAINT CK_Employee_VacationHours CHECK (VacationHours > 0);

-- d
ALTER TABLE dbo.Employee
ADD CONSTRAINT DF_Employee_VacationHours DEFAULT (144) FOR VacationHours;

-- e
INSERT INTO dbo.Employee (
    BusinessEntityID,
    NationalIDNumber,
    LoginID,
    JobTitle,
    BirthDate,
    MaritalStatus,
    Gender,
    HireDate,
    SickLeaveHours,
    ModifiedDate
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
    e.SickLeaveHours,
    e.ModifiedDate
FROM HumanResources.Employee e
WHERE e.JobTitle = 'Buyer';

-- f
ALTER TABLE dbo.Employee
ALTER COLUMN ModifiedDate DATE NULL;

SELECT * FROM dbo.Employee;