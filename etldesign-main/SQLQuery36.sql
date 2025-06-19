USE DW_AdventureWorks;
GO

CREATE OR ALTER PROCEDURE etl.usp_Clean_SalesTerritory
AS
BEGIN
  SET NOCOUNT ON;

  -- ODS’i temizle (tam yükleme için)
  TRUNCATE TABLE ods.SalesTerritory;

  -- Yeniden yükle
  INSERT INTO ods.SalesTerritory (TerritoryID, Name, CountryRegionCode, GroupName)
  SELECT
    TerritoryID,
    Name,
    CountryRegionCode,
    [Group] AS GroupName
  FROM stg.SalesTerritory;
END;
GO
