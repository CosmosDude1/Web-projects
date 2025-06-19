/* Örnek staging þemasý */
CREATE SCHEMA stg;
GO

/* Staging tablosu – ekstra metadata alanlarý ekle */
CREATE TABLE stg.ProductDescription (
    SurKey        bigint IDENTITY(1,1) PRIMARY KEY,
    SourceID      int            NOT NULL,
    Description   nvarchar(max),
    ModifiedDate  datetime,
    ExtractDtm    datetime       DEFAULT GETDATE(),  -- ne zaman çektim?
    SourceSystem  varchar(10)    DEFAULT 'AW'
);
GO

/* Ýlk toplu çekiþ */
INSERT INTO stg.ProductDescription (SourceID, Description, ModifiedDate)
SELECT ProductDescriptionID, Description, ModifiedDate
FROM   AdventureWorks2019.Production.ProductDescription;
