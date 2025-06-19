/* Bir kerelik tam kopya – kolon/tip bire bir */
SELECT *, SYSUTCDATETIME() AS ExtractDtm
INTO stg.Product
FROM AdventureWorks2019.Production.Product;
GO

SELECT *, SYSUTCDATETIME() AS ExtractDtm
INTO stg.SalesTerritory
FROM AdventureWorks2019.Sales.SalesTerritory;
GO

SELECT *, SYSUTCDATETIME() AS ExtractDtm
INTO stg.Store
FROM AdventureWorks2019.Sales.Store;
GO

SELECT *, SYSUTCDATETIME() AS ExtractDtm
INTO stg.Address
FROM AdventureWorks2019.Person.Address;
GO

SELECT *, SYSUTCDATETIME() AS ExtractDtm
INTO stg.StateProvince
FROM AdventureWorks2019.Person.StateProvince;
GO

SELECT *, SYSUTCDATETIME() AS ExtractDtm
INTO stg.SalesTaxRate
FROM AdventureWorks2019.Sales.SalesTaxRate;
GO
