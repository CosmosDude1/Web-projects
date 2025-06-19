/* 1.1  Þema (isterseniz dbo’da da tutabilirsiniz) */
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'stg')
    EXEC('CREATE SCHEMA stg');
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'ods')
    EXEC('CREATE SCHEMA ods');
GO

/* 1.2  Staging tablosu — ETL dýþý “ham” veri gelir */
IF OBJECT_ID('stg.ProductDescription') IS NULL
BEGIN
    CREATE TABLE stg.ProductDescription (
        SurKey         bigint        IDENTITY(1,1) PRIMARY KEY,
        SourceID       int           NOT NULL,
        DescriptionRaw nvarchar(max) NULL,
        ModifiedRaw    varchar(30)   NULL,          -- tarih metin geldi diyelim
        LoadDtm        datetime      DEFAULT sysutcdatetime()
    );
END
GO

/* 1.3  ODS tablosu — temiz ve tip-güvenli veri */
IF OBJECT_ID('ods.ProductDescription') IS NULL
BEGIN
    CREATE TABLE ods.ProductDescription (
        OdsKey       bigint      IDENTITY(1,1) PRIMARY KEY,
        SourceID     int         NOT NULL,
        Description  nvarchar(max) NOT NULL,
        ModifiedDate date        NOT NULL,
        CleanDtm     datetime    DEFAULT sysutcdatetime()
    );
END
GO

/* 1.4  Ýsteðe baðlý “Reject” (hatalý satýr) tablosu */
IF OBJECT_ID('stg.Reject_ProductDescription') IS NULL
BEGIN
    CREATE TABLE stg.Reject_ProductDescription (
        RejectID     int          IDENTITY PRIMARY KEY,
        SourceID     int          NULL,
        Description  nvarchar(max),
        ModifiedRaw  varchar(30),
        Reason       nvarchar(200),
        RejectDtm    datetime     DEFAULT sysutcdatetime()
    );
END
GO
