USE DW_AdventureWorks;
GO

-- Eðer tablo zaten varsa silebilirsiniz (opsiyonel)
IF OBJECT_ID('dwh.DimSalesTerritory','U') IS NOT NULL
  DROP TABLE dwh.DimSalesTerritory;
GO

-- 1) Tabloyu CREATE edin, sadece tipiyle
CREATE TABLE dwh.DimSalesTerritory (
  DimTerritoryKey INT IDENTITY PRIMARY KEY,
  TerritoryID     INT         NOT NULL,
  Name            NVARCHAR(50),
  CountryRegion   NCHAR(3),
  GroupName       NVARCHAR(50),
  RowDtm          DATETIME    DEFAULT SYSUTCDATETIME()
);

-- 2) Ardýndan UNIQUE kýsýtýný ekleyin
ALTER TABLE dwh.DimSalesTerritory
ADD CONSTRAINT UQ_DimSalesTerritory_TerritoryID UNIQUE (TerritoryID);
GO
