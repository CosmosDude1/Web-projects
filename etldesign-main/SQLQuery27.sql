USE DW_AdventureWorks;
GO

-- Staging'te veri var mý?
SELECT COUNT(*) AS StgCount FROM stg.SalesTerritory;
-- ODS'te veri var mý?
SELECT COUNT(*) AS OdsCount FROM ods.SalesTerritory;
-- Dim tablosuna insert için SP'nin çalýþýp çalýþmadýðýný görebilmek için
SELECT COUNT(*) AS DimCount FROM dwh.DimSalesTerritory;
GO
