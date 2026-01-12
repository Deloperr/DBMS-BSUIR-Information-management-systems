USE AdventureWorks2012;

-- a) Создание таблицы Sales.CreditCardHst для хранения истории изменений
IF OBJECT_ID('Sales.CreditCardHst', 'U') IS NOT NULL
    DROP TABLE Sales.CreditCardHst;

CREATE TABLE Sales.CreditCardHst (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    Action CHAR(6) NOT NULL, -- INSERT, UPDATE, DELETE
    ModifiedDate DATETIME NOT NULL,
    SourceID INT NOT NULL, -- CreditCardID из исходной таблицы
    UserName NVARCHAR(100) NOT NULL,
    CardType NVARCHAR(50) NULL,
    CardNumber NVARCHAR(25) NULL,
    ExpMonth TINYINT NULL,
    ExpYear SMALLINT NULL,
    OldCardType NVARCHAR(50) NULL, -- Старое значение для UPDATE
    OldCardNumber NVARCHAR(25) NULL,
    OldExpMonth TINYINT NULL,
    OldExpYear SMALLINT NULL
);
GO

-- b) Создание AFTER триггера для операций INSERT, UPDATE, DELETE
IF OBJECT_ID('Sales.trg_CreditCard_Audit', 'TR') IS NOT NULL
    DROP TRIGGER Sales.trg_CreditCard_Audit;
GO

CREATE TRIGGER Sales.trg_CreditCard_Audit
ON Sales.CreditCard
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Для операции INSERT
    IF EXISTS (SELECT * FROM inserted) AND NOT EXISTS (SELECT * FROM deleted)
    BEGIN
        INSERT INTO Sales.CreditCardHst (
            Action, ModifiedDate, SourceID, UserName,
            CardType, CardNumber, ExpMonth, ExpYear
        )
        SELECT 
            'INSERT', 
            GETDATE(),
            i.CreditCardID,
            SYSTEM_USER,
            i.CardType,
            i.CardNumber,
            i.ExpMonth,
            i.ExpYear
        FROM inserted i;
    END
    
    -- Для операции UPDATE
    IF EXISTS (SELECT * FROM inserted) AND EXISTS (SELECT * FROM deleted)
    BEGIN
        INSERT INTO Sales.CreditCardHst (
            Action, ModifiedDate, SourceID, UserName,
            CardType, CardNumber, ExpMonth, ExpYear,
            OldCardType, OldCardNumber, OldExpMonth, OldExpYear
        )
        SELECT 
            'UPDATE',
            GETDATE(),
            i.CreditCardID,
            SYSTEM_USER,
            i.CardType,
            i.CardNumber,
            i.ExpMonth,
            i.ExpYear,
            d.CardType,
            d.CardNumber,
            d.ExpMonth,
            d.ExpYear
        FROM inserted i
        INNER JOIN deleted d ON i.CreditCardID = d.CreditCardID;
    END
    
    -- Для операции DELETE
    IF NOT EXISTS (SELECT * FROM inserted) AND EXISTS (SELECT * FROM deleted)
    BEGIN
        INSERT INTO Sales.CreditCardHst (
            Action, ModifiedDate, SourceID, UserName,
            CardType, CardNumber, ExpMonth, ExpYear
        )
        SELECT 
            'DELETE',
            GETDATE(),
            d.CreditCardID,
            SYSTEM_USER,
            d.CardType,
            d.CardNumber,
            d.ExpMonth,
            d.ExpYear
        FROM deleted d;
    END
END;
GO

-- c) Создание представления VIEW
IF OBJECT_ID('Sales.vw_CreditCard', 'V') IS NOT NULL
    DROP VIEW Sales.vw_CreditCard;
GO

CREATE VIEW Sales.vw_CreditCard
AS
SELECT 
    CreditCardID,
    CardType,
    CardNumber,
    ExpMonth,
    ExpYear,
    ModifiedDate
FROM Sales.CreditCard;
GO

-- d) Тестирование операций через представление 
BEGIN
    DECLARE @NewCreditCardID INT;
    
    -- Проверяем исходные данные
    SELECT 'Before operations' AS Status, COUNT(*) AS Count FROM Sales.CreditCard;
    SELECT 'History before' AS Status, COUNT(*) AS Count FROM Sales.CreditCardHst;

    -- Вставка новой строки через представление
    INSERT INTO Sales.vw_CreditCard (CardType, CardNumber, ExpMonth, ExpYear, ModifiedDate)
    VALUES ('Superior', '1111222233334444', 12, 2025, GETDATE());

    -- Получаем ID вставленной записи
    SET @NewCreditCardID = SCOPE_IDENTITY();
    PRINT 'New CreditCardID: ' + CAST(@NewCreditCardID AS VARCHAR(10));

    -- Проверяем после INSERT
    SELECT 'After INSERT' AS Status, COUNT(*) AS Count FROM Sales.CreditCard;
    SELECT * FROM Sales.CreditCardHst WHERE Action = 'INSERT';

    -- Обновление вставленной строки через представление
    UPDATE Sales.vw_CreditCard 
    SET CardType = 'Premium', ExpYear = 2026, ModifiedDate = GETDATE()
    WHERE CreditCardID = @NewCreditCardID;

    -- Проверяем после UPDATE
    SELECT 'After UPDATE' AS Status, COUNT(*) AS Count FROM Sales.CreditCard;
    SELECT * FROM Sales.CreditCardHst WHERE Action = 'UPDATE';

    -- Удаление вставленной строки через представление
    DELETE FROM Sales.vw_CreditCard 
    WHERE CreditCardID = @NewCreditCardID;

    -- Проверяем после DELETE
    SELECT 'After DELETE' AS Status, COUNT(*) AS Count FROM Sales.CreditCard;
    SELECT * FROM Sales.CreditCardHst WHERE Action = 'DELETE';

    -- Финальная проверка всех операций в истории
    SELECT 
        Action,
        COUNT(*) AS OperationCount,
        MAX(ModifiedDate) AS LastOperation
    FROM Sales.CreditCardHst 
    GROUP BY Action
    ORDER BY LastOperation DESC;
END
GO

-- Просмотр всей истории изменений
SELECT 
    ID,
    Action,
    ModifiedDate,
    SourceID,
    UserName,
    CardType,
    CardNumber,
    ExpMonth,
    ExpYear,
    OldCardType,
    OldCardNumber,
    OldExpMonth,
    OldExpYear
FROM Sales.CreditCardHst 
ORDER BY ModifiedDate DESC;