USE AdventureWorks2012;

-- 1
SELECT 
    e.BusinessEntityID,
    e.JobTitle,
    s.Name AS ShiftName,
    CONVERT(TIME, s.StartTime) AS StartTime,
    CONVERT(TIME, s.EndTime) AS EndTime
FROM HumanResources.Employee e
INNER JOIN HumanResources.EmployeeDepartmentHistory edh ON e.BusinessEntityID = edh.BusinessEntityID
INNER JOIN HumanResources.Shift s ON edh.ShiftID = s.ShiftID
WHERE edh.EndDate IS NULL
ORDER BY e.BusinessEntityID;

-- 2
SELECT 
    d.GroupName,
    COUNT(DISTINCT e.BusinessEntityID) AS EmpCount
FROM HumanResources.Employee e
INNER JOIN HumanResources.EmployeeDepartmentHistory edh ON e.BusinessEntityID = edh.BusinessEntityID
INNER JOIN HumanResources.Department d ON edh.DepartmentID = d.DepartmentID
WHERE edh.EndDate IS NULL
GROUP BY d.GroupName
ORDER BY EmpCount ASC;

-- 3
SELECT 
    d.Name AS DepartmentName,
    e.BusinessEntityID,
    eph.Rate,
    MAX(eph.Rate) OVER (PARTITION BY d.DepartmentID) AS MaxInDepartment,
    DENSE_RANK() OVER (PARTITION BY d.DepartmentID ORDER BY eph.Rate) AS RateGroup
FROM HumanResources.EmployeePayHistory eph
INNER JOIN HumanResources.Employee e ON eph.BusinessEntityID = e.BusinessEntityID
INNER JOIN HumanResources.EmployeeDepartmentHistory edh ON e.BusinessEntityID = edh.BusinessEntityID
INNER JOIN HumanResources.Department d ON edh.DepartmentID = d.DepartmentID
INNER JOIN Person.Person p ON e.BusinessEntityID = p.BusinessEntityID
WHERE edh.EndDate IS NULL
ORDER BY d.Name, eph.Rate, RateGroup DESC;