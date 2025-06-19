USE DW_AdventureWorks;
GO

IF OBJECT_ID('etl.usp_Clean_SalesTerritory','P') IS NOT NULL
  DROP PROCEDURE etl.usp_Clean_SalesTerritory;
GO
