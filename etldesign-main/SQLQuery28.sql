-- Temizleme SP'sini tekrar çalıştırın:
EXEC etl.usp_Clean_SalesTerritory;
GO

-- Tekrar kontrol:
SELECT COUNT(*) AS OdsCount FROM ods.SalesTerritory;
SELECT TOP 5 * FROM ods.SalesTerritory;
GO
