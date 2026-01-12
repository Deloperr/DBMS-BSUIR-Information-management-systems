RESTORE DATABASE AdventureWorks2012
FROM DISK = 'C:\Backup\AdventureWorks2012-Full Database Backup.bak'

WITH 
    FILE = 1,

    MOVE N'AdventureWorks2012_Data' TO N'C:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\AdventureWorks2012_Data.mdf',
    MOVE N'AdventureWorks2012_Log' TO N'C:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\AdventureWorks2012_Log.ldf',

    NOUNLOAD, 
    STATS = 5,
    REPLACE;
GO

BACKUP DATABASE AdventureWorks2012
TO DISK='C:\New\AdventureWorksBackup';
go

USE AdventureWorks2012;

-- 1
SELECT 
    DepartmentID,
    Name AS DepartmentName,
    GroupName
FROM HumanResources.Department
WHERE GroupName = 'Research and Development'
ORDER BY Name ASC;

-- 2
SELECT 
    MIN(SickLeaveHours) AS MinSickLeaveHours
FROM HumanResources.Employee;

-- 3
SELECT TOP 10
    JobTitle,
    CASE 
        WHEN CHARINDEX(' ', JobTitle) > 0 
        THEN LEFT(JobTitle, CHARINDEX(' ', JobTitle) - 1)
        ELSE JobTitle
    END AS FirstWord
FROM HumanResources.Employee
GROUP BY JobTitle
ORDER BY JobTitle ASC;
