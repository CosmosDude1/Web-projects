USE DW_AdventureWorks;
GO

-- ODS’yi temizleyin (opsiyonel, test için)
TRUNCATE TABLE ods.SalesTerritory;
GO

-- Direkt insert: staging’den ODS’ye
INSERT INTO ods.SalesTerritory (TerritoryID, Name, CountryRegionCode, GroupName)
SELECT
  TerritoryID,
  Name,
  CountryRegionCode,
  [Group] AS GroupName
FROM stg.SalesTerritory;
GO

-- Sonucu kontrol edin
SELECT COUNT(*)      AS OdsCount,
       MIN(RowDtm)   AS FirstLoad
FROM   ods.SalesTerritory;
SELECT TOP 5 * FROM ods.SalesTerritory;
GO
