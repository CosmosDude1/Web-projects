USE DW_AdventureWorks;
GO

EXEC etl.usp_Load_DimSalesTerritory;
GO

SELECT COUNT(*) AS DimCount
FROM dwh.DimSalesTerritory;

SELECT TOP 5 *
FROM dwh.DimSalesTerritory;
GO
