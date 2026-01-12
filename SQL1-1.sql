CREATE DATABASE NewDatabase;
go

USE NewDatabase;
GO

CREATE SCHEMA sales;
go

CREATE SCHEMA persons;
go

CREATE TABLE sales.Orders (OrderNum INT NULL);
go

 BACKUP DATABASE NewDatabase
 TO DISK = 'C:\Backup\Test\testDatabase';
 go

 DROP DATABASE NewDatabase;
 go

RESTORE DATABASE NewDatabase from Disk='C:\Backup\Test\testDatabase';
go