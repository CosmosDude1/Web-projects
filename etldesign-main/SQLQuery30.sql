-- 1) ETL �emas�n� olu�tur
USE DW_AdventureWorks;
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'etl')
    EXEC('CREATE SCHEMA etl AUTHORIZATION dbo;');
GO
