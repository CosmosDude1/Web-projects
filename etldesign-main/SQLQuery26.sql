USE DW_AdventureWorks;
GO

-- 1) Prosed�r� tan�mlay�n
CREATE OR ALTER PROCEDURE etl.usp_Load_DimSalesTerritory
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dwh.DimSalesTerritory (TerritoryID, Name, CountryRegion, GroupName)
    SELECT
      s.TerritoryID,
      s.Name,
      s.CountryRegionCode,
      s.GroupName
    FROM ods.SalesTerritory AS s
    WHERE NOT EXISTS (
      SELECT 1
      FROM dwh.DimSalesTerritory d
      WHERE d.TerritoryID = s.TerritoryID
    );
END;
GO

-- 2) Prosed�r� tetikleyin
EXEC etl.usp_Load_DimSalesTerritory;
GO

-- 3) Do�rulay�n
SELECT TOP 5 * FROM dwh.DimSalesTerritory;
GO
