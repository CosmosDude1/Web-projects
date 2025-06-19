USE DW_AdventureWorks;
GO

-- 1) Address’i staging’e çek
IF OBJECT_ID('stg.Address','U') IS NULL
BEGIN
    SELECT *, SYSUTCDATETIME() AS ExtractDtm
    INTO   stg.Address
    FROM   AdventureWorks2019.Person.Address;
END
GO

-- 2) SalesTerritory’i staging’e çek
IF OBJECT_ID('stg.SalesTerritory','U') IS NULL
BEGIN
    SELECT *, SYSUTCDATETIME() AS ExtractDtm
    INTO   stg.SalesTerritory
    FROM   AdventureWorks2019.Sales.SalesTerritory;
END
GO

-- 3) Oluþtuðunu doðrulayýn
SELECT TOP 5 * FROM stg.Address;
SELECT TOP 5 * FROM stg.SalesTerritory;
GO

-- 4) Temizleme SP’lerini tekrar çalýþtýrýn
EXEC etl.usp_Clean_Address;
EXEC etl.usp_Clean_SalesTerritory;
GO
