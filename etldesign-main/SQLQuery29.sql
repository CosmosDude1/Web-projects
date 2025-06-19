USE DW_AdventureWorks;
GO

IF OBJECT_ID('ods.SalesTerritory','U') IS NULL
BEGIN
  CREATE TABLE ods.SalesTerritory (
    TerritoryID       INT    PRIMARY KEY,
    Name              NVARCHAR(50),
    CountryRegionCode NCHAR(3),
    GroupName         NVARCHAR(50),
    RowDtm            DATETIME DEFAULT SYSUTCDATETIME()
  );
END
GO
