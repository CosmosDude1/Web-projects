
DECLARE @DW_DB  sysname = N'DW_AdventureWorks';   -- yeni depo DB
DECLARE @SRC_DB sysname = N'AdventureWorks2019';  -- kaynak OLTP
DECLARE @SERVER sysname = N'(local)';             -- ayný sunucu

IF DB_ID(@DW_DB) IS NOT NULL
BEGIN
    ALTER DATABASE [DW_AdventureWorks] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE [DW_AdventureWorks];
END
GO


CREATE DATABASE [DW_AdventureWorks]  /* basit kurtarma */
CONTAINMENT = NONE;
ALTER DATABASE [DW_AdventureWorks] SET RECOVERY SIMPLE;
GO
USE [DW_AdventureWorks];
GO
EXEC('CREATE SCHEMA stg AUTHORIZATION dbo');
EXEC('CREATE SCHEMA ods AUTHORIZATION dbo');
EXEC('CREATE SCHEMA dwh AUTHORIZATION dbo');
EXEC('CREATE SCHEMA rpt AUTHORIZATION dbo');
EXEC('CREATE SCHEMA etl AUTHORIZATION dbo');
GO

/********************************************************************
 2. EXTRACT ? AdventureWorks tablolarýný STAGING’e kopyala
********************************************************************/
-- tablo listesi (gerekirse ekleyin/çýkarýn)
DECLARE @tbl TABLE (SchemaName sysname, TableName sysname);
INSERT @tbl VALUES
('Production','Product'), ('Production','ProductDescription'),
('Production','ProductModel'), ('Production','ProductInventory'),
('Sales','SalesTerritory'), ('Sales','SalesTaxRate'), ('Sales','Store'),
('Sales','ShoppingCartItem'), ('Sales','SpecialOfferProduct'),
('Person','Address'), ('Person','StateProvince'), ('Person','PersonPhone'),
('Person','BusinessEntity'), ('Purchasing','ShipMethod'),
/* … 30 tablonun tamamýný buraya ekleyin … */
('Production','BillOfMaterials');

DECLARE @sql nvarchar(max) = N'';
SELECT @sql = STRING_AGG(
   N'
IF OBJECT_ID(''stg.'+QUOTENAME(t.TableName)+N''') IS NULL
    SELECT *, SYSUTCDATETIME() AS ExtractDtm
    INTO   stg.'+QUOTENAME(t.TableName)+N'
    FROM   '+QUOTENAME(@SRC_DB)+N'.'+QUOTENAME(t.SchemaName)+N'.'+QUOTENAME(t.TableName)+N';'
, NCHAR(10))
FROM @tbl t;

EXEC(@sql);
GO

/********************************************************************
 3. ODS TABLOLARINI OLUÞTUR + TEMÝZLEME SP’leri
********************************************************************/
-- Örnek: Ürün
IF OBJECT_ID('ods.Product') IS NULL
BEGIN
    CREATE TABLE ods.Product(
        ProductID           int          PRIMARY KEY,
        Name                nvarchar(100) NOT NULL,
        Color               nvarchar(15)  NULL,
        StandardCost        money         NOT NULL,
        ListPrice           money         NOT NULL,
        ProductModelID      int           NULL,
        RowDtm              datetime      DEFAULT SYSUTCDATETIME()
    );
END
GO
CREATE OR ALTER PROCEDURE etl.usp_Clean_Product
AS
BEGIN
    SET NOCOUNT ON;
    MERGE ods.Product AS tgt
    USING (
        SELECT  ProductID,
                Name,
                NULLIF(LTRIM(RTRIM(Color)),'')    AS Color,
                ABS(StandardCost)                 AS StandardCost,
                ABS(ListPrice)                    AS ListPrice,
                ProductModelID
        FROM    stg.Product
    ) AS s
    ON tgt.ProductID = s.ProductID
    WHEN MATCHED THEN
        UPDATE SET Name          = s.Name,
                   Color         = s.Color,
                   StandardCost  = s.StandardCost,
                   ListPrice     = s.ListPrice,
                   ProductModelID= s.ProductModelID,
                   RowDtm        = SYSUTCDATETIME()
    WHEN NOT MATCHED THEN
        INSERT (ProductID, Name, Color, StandardCost, ListPrice, ProductModelID)
        VALUES (s.ProductID, s.Name, s.Color, s.StandardCost, s.ListPrice, s.ProductModelID);
END
GO

/* Benzer þekilde Address, StateProvince, SalesTerritory, Store, SalesTaxRate…
   ==?  ister kopyalayýn ister tabloya özel kurallar ekleyin                 */

/********************************************************************
 4. BOYUT ÖRNEKLERÝ
********************************************************************/
IF OBJECT_ID('dwh.DimProduct') IS NULL
   CREATE TABLE dwh.DimProduct (
       DimProductKey   int IDENTITY PRIMARY KEY,
       ProductID       int UNIQUE,
       Name            nvarchar(100),
       Color           nvarchar(15),
       PriceBand       varchar(6),
       RowDtm          datetime DEFAULT SYSUTCDATETIME()
   );
GO
CREATE OR ALTER PROCEDURE etl.usp_Load_DimProduct
AS
BEGIN
    INSERT INTO dwh.DimProduct (ProductID, Name, Color, PriceBand)
    SELECT  o.ProductID,
            o.Name,
            o.Color,
            CASE WHEN o.ListPrice<100 THEN 'Low'
                 WHEN o.ListPrice<1000 THEN 'Mid' ELSE 'High' END
    FROM ods.Product o
    WHERE NOT EXISTS (
        SELECT 1 FROM dwh.DimProduct d WHERE d.ProductID = o.ProductID
    );
END
GO

/********************************************************************
 5. METRÝK / KALÝTE RAPOR VIEW’larý
********************************************************************/
CREATE OR ALTER VIEW rpt.vw_DQ_Product AS
SELECT
    COUNT(*)                                    AS Total,
    SUM(CASE WHEN Color IS NULL THEN 1 END)     AS MissingColor,
    CAST(100.0*SUM(CASE WHEN Color IS NULL THEN 1 END)/COUNT(*) AS decimal(5,2)) AS PctMissingColor
FROM ods.Product;
GO

/********************************************************************
 6. ETL ÇALIÞTIR – tek seferlik
********************************************************************/
EXEC etl.usp_Clean_Product;
EXEC etl.usp_Load_DimProduct;
/* diðer clean/load prosedürlerini de burada çaðýrýn */
GO

/********************************************************************
 7. SON KONTROL
********************************************************************/
SELECT TOP 5 * FROM ods.Product;
SELECT TOP 5 * FROM dwh.DimProduct;
SELECT *    FROM rpt.vw_DQ_Product;
