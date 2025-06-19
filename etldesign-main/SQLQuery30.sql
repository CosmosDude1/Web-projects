-- 1) ETL þemasýný oluþtur
USE DW_AdventureWorks;
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'etl')
    EXEC('CREATE SCHEMA etl AUTHORIZATION dbo;');
GO
