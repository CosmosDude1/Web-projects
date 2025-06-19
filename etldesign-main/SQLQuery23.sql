USE DW_AdventureWorks;
GO

IF OBJECT_ID('dwh.DimAddress','U') IS NULL
BEGIN
  CREATE TABLE dwh.DimAddress (
    DimAddressKey   INT         IDENTITY PRIMARY KEY,
    AddressID       INT         UNIQUE,
    AddressLine1    NVARCHAR(60),
    AddressLine2    NVARCHAR(60) NULL,
    City            NVARCHAR(30),
    StateProvinceID INT,
    PostalCode      NVARCHAR(15),
    RowDtm          DATETIME    DEFAULT SYSUTCDATETIME()
  );
END
GO

/* 2) Load SP’sini oluþtur */
CREATE OR ALTER PROCEDURE etl.usp_Load_DimAddress
AS
BEGIN
  SET NOCOUNT ON;

  INSERT INTO dwh.DimAddress (AddressID, AddressLine1, AddressLine2, City, StateProvinceID, PostalCode)
  SELECT
    o.AddressID,
    o.AddressLine1,
    o.AddressLine2,
    o.City,
    o.StateProvinceID,
    o.PostalCode
  FROM ods.Address AS o
  WHERE NOT EXISTS (
    SELECT 1 
    FROM dwh.DimAddress AS d 
    WHERE d.AddressID = o.AddressID
  );
END;
GO


EXEC etl.usp_Load_DimAddress;
GO


SELECT TOP 5 * FROM dwh.DimAddress;
GO
EXEC etl.usp_Load_DimSalesTerritory;
SELECT TOP 5 * FROM dwh.DimSalesTerritory;
GO
