USE AdventureWorks2012;

-- a) Создание защищенного представления с уникальным кластерным индексом

-- Сначала создаем представление с SCHEMABINDING для возможности создания индекса
IF OBJECT_ID('Sales.vw_CreditCardDetails', 'V') IS NOT NULL
    DROP VIEW Sales.vw_CreditCardDetails;
GO

CREATE VIEW Sales.vw_CreditCardDetails
WITH SCHEMABINDING, ENCRYPTION -- ENCRYPTION скрывает исходный код
AS
SELECT 
    cc.CreditCardID,
    cc.CardType,
    cc.CardNumber,
    cc.ExpMonth,
    cc.ExpYear,
    cc.ModifiedDate AS CreditCardModifiedDate,
    pcc.BusinessEntityID,
    pcc.ModifiedDate AS PersonCreditCardModifiedDate
FROM Sales.CreditCard cc
INNER JOIN Sales.PersonCreditCard pcc ON cc.CreditCardID = pcc.CreditCardID;
GO

-- Создаем уникальный кластерный индекс по CreditCardID
IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_vw_CreditCardDetails_CreditCardID' AND object_id = OBJECT_ID('Sales.vw_CreditCardDetails'))
    DROP INDEX IX_vw_CreditCardDetails_CreditCardID ON Sales.vw_CreditCardDetails;

CREATE UNIQUE CLUSTERED INDEX IX_vw_CreditCardDetails_CreditCardID
ON Sales.vw_CreditCardDetails (CreditCardID);
GO

-- b) Создание INSTEAD OF триггеров для операций INSERT, UPDATE, DELETE

-- INSTEAD OF INSERT триггер
IF OBJECT_ID('Sales.trg_vw_CreditCardDetails_InsteadOfInsert', 'TR') IS NOT NULL
    DROP TRIGGER Sales.trg_vw_CreditCardDetails_InsteadOfInsert;
GO

CREATE TRIGGER Sales.trg_vw_CreditCardDetails_InsteadOfInsert
ON Sales.vw_CreditCardDetails
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @NewCreditCardID INT;
    
    -- Вставляем данные в Sales.CreditCard
    INSERT INTO Sales.CreditCard (CardType, CardNumber, ExpMonth, ExpYear, ModifiedDate)
    SELECT CardType, CardNumber, ExpMonth, ExpYear, GETDATE()
    FROM inserted;
    
    -- Получаем ID новой кредитной карты
    SET @NewCreditCardID = SCOPE_IDENTITY();
    
    -- Вставляем связь в Sales.PersonCreditCard
    INSERT INTO Sales.PersonCreditCard (BusinessEntityID, CreditCardID, ModifiedDate)
    SELECT BusinessEntityID, @NewCreditCardID, GETDATE()
    FROM inserted;
END;
GO

-- INSTEAD OF UPDATE триггер
IF OBJECT_ID('Sales.trg_vw_CreditCardDetails_InsteadOfUpdate', 'TR') IS NOT NULL
    DROP TRIGGER Sales.trg_vw_CreditCardDetails_InsteadOfUpdate;
GO

CREATE TRIGGER Sales.trg_vw_CreditCardDetails_InsteadOfUpdate
ON Sales.vw_CreditCardDetails
INSTEAD OF UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Обновляем только таблицу Sales.CreditCard
    UPDATE cc SET
        cc.CardType = i.CardType,
        cc.CardNumber = i.CardNumber,
        cc.ExpMonth = i.ExpMonth,
        cc.ExpYear = i.ExpYear,
        cc.ModifiedDate = GETDATE()
    FROM Sales.CreditCard cc
    INNER JOIN inserted i ON cc.CreditCardID = i.CreditCardID;
    
    PRINT 'Данные кредитной карты обновлены';
END;
GO

-- INSTEAD OF DELETE триггер
IF OBJECT_ID('Sales.trg_vw_CreditCardDetails_InsteadOfDelete', 'TR') IS NOT NULL
    DROP TRIGGER Sales.trg_vw_CreditCardDetails_InsteadOfDelete;
GO

CREATE TRIGGER Sales.trg_vw_CreditCardDetails_InsteadOfDelete
ON Sales.vw_CreditCardDetails
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Удаляем связь из Sales.PersonCreditCard
    DELETE FROM Sales.PersonCreditCard
    WHERE CreditCardID IN (SELECT CreditCardID FROM deleted);
    
    -- Проверяем, остались ли другие связи с этой кредитной картой
    DELETE FROM Sales.CreditCard
    WHERE CreditCardID IN (
        SELECT d.CreditCardID 
        FROM deleted d
        WHERE NOT EXISTS (
            SELECT 1 
            FROM Sales.PersonCreditCard pcc 
            WHERE pcc.CreditCardID = d.CreditCardID
        )
    );
    
    PRINT 'Удаление завершено';
END;
GO

-- c) Тестирование операций через представление
BEGIN
    DECLARE @TestBusinessEntityID INT = 1; -- Существующий BusinessEntityID
    
    -- Проверяем исходные данные
    SELECT 'Исходные данные в представлении' AS Status;
    SELECT * FROM Sales.vw_CreditCardDetails WHERE BusinessEntityID = @TestBusinessEntityID;
    
    SELECT 'Исходные данные в CreditCard' AS Status;
    SELECT * FROM Sales.CreditCard WHERE CreditCardID IN (
        SELECT CreditCardID FROM Sales.PersonCreditCard WHERE BusinessEntityID = @TestBusinessEntityID
    );
    
    -- Вставка новой строки через представление
    PRINT 'Вставка новой кредитной карты...';
    INSERT INTO Sales.vw_CreditCardDetails (CardType, CardNumber, ExpMonth, ExpYear, BusinessEntityID)
    VALUES ('Platinum', '9999888877776666', 6, 2027, @TestBusinessEntityID);
    
    DECLARE @NewCreditCardID INT = SCOPE_IDENTITY();
    PRINT 'Новая CreditCardID: ' + CAST(@NewCreditCardID AS VARCHAR(10));
    
    -- Проверяем после INSERT
    SELECT 'После INSERT' AS Status;
    SELECT * FROM Sales.vw_CreditCardDetails WHERE CreditCardID = @NewCreditCardID;
    
    -- Обновление вставленной строки через представление
    PRINT 'Обновление кредитной карты...';
    UPDATE Sales.vw_CreditCardDetails 
    SET CardType = 'Diamond', ExpYear = 2028, CardNumber = '5555444433332222'
    WHERE CreditCardID = @NewCreditCardID;
    
    -- Проверяем после UPDATE
    SELECT 'После UPDATE' AS Status;
    SELECT * FROM Sales.vw_CreditCardDetails WHERE CreditCardID = @NewCreditCardID;
    SELECT * FROM Sales.CreditCard WHERE CreditCardID = @NewCreditCardID;
    
    -- Удаление строки через представление
    PRINT 'Удаление кредитной карты...';
    DELETE FROM Sales.vw_CreditCardDetails 
    WHERE CreditCardID = @NewCreditCardID;
    
    -- Проверяем после DELETE
    SELECT 'После DELETE' AS Status;
    SELECT * FROM Sales.vw_CreditCardDetails WHERE CreditCardID = @NewCreditCardID;
    SELECT * FROM Sales.CreditCard WHERE CreditCardID = @NewCreditCardID;
    SELECT * FROM Sales.PersonCreditCard WHERE CreditCardID = @NewCreditCardID;
    
    -- Финальная проверка
    SELECT 'Финальная проверка' AS Status;
    SELECT 
        (SELECT COUNT(*) FROM Sales.vw_CreditCardDetails WHERE BusinessEntityID = @TestBusinessEntityID) AS InView,
        (SELECT COUNT(*) FROM Sales.CreditCard WHERE CreditCardID IN (
            SELECT CreditCardID FROM Sales.PersonCreditCard WHERE BusinessEntityID = @TestBusinessEntityID
        )) AS InCreditCard,
        (SELECT COUNT(*) FROM Sales.PersonCreditCard WHERE BusinessEntityID = @TestBusinessEntityID) AS InPersonCreditCard;
END
GO

-- Дополнительная проверка - попытка просмотреть код представления (должна вернуть NULL из-за ENCRYPTION)
SELECT definition 
FROM sys.sql_modules 
WHERE object_id = OBJECT_ID('Sales.vw_CreditCardDetails');