USE DW_AdventureWorks;
GO

CREATE OR ALTER PROCEDURE etl.usp_Clean_SalesTerritory
AS
BEGIN
  SET NOCOUNT ON;

  -- ODS�i temizle (tam y�kleme i�in)
  TRUNCATE TABLE ods.SalesTerritory;

  -- Yeniden y�kle
  INSERT INTO ods.SalesTerritory (TerritoryID, Name, CountryRegionCode, GroupName)
  SELECT
    TerritoryID,
    Name,
    CountryRegionCode,
    [Group] AS GroupName
  FROM stg.SalesTerritory;
END;
GO
