USE DW_AdventureWorks;
GO

-- Staging'te veri var m�?
SELECT COUNT(*) AS StgCount FROM stg.SalesTerritory;
-- ODS'te veri var m�?
SELECT COUNT(*) AS OdsCount FROM ods.SalesTerritory;
-- Dim tablosuna insert i�in SP'nin �al���p �al��mad���n� g�rebilmek i�in
SELECT COUNT(*) AS DimCount FROM dwh.DimSalesTerritory;
GO
