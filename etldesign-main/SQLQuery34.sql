USE DW_AdventureWorks;
GO

CREATE OR ALTER PROCEDURE etl.usp_Clean_SalesTerritory
AS
BEGIN
  SET NOCOUNT ON;

  )
  TRUNCATE TABLE ods.SalesTerritory;

  INSERT INTO ods.SalesTerritory (TerritoryID, Name, CountryRegionCode, GroupName)
  SELECT
    TerritoryID,
    Name,
    CountryRegionCode,
    [Group] AS GroupName
  FROM stg.SalesTerritory;
END;
GO
