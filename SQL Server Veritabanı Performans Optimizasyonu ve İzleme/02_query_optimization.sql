USE AdventureWorks2019;
GO

-- Sorgu Optimizasyonu Scripti
-- AdventureWorks2019 için performans iyileştirmeleri

-- 1. Eksik İndeks Önerileri
SELECT 
    migs.avg_total_user_cost * (migs.avg_user_impact / 100.0) * (migs.user_seeks + migs.user_scans) AS improvement_measure,
    'CREATE INDEX [IX_' + OBJECT_NAME(mid.object_id) + '_' + 
    REPLACE(REPLACE(REPLACE(ISNULL(mid.equality_columns,''),', ','_'),'[',''),']','') +
    CASE 
        WHEN mid.inequality_columns IS NOT NULL 
        THEN '_' + REPLACE(REPLACE(REPLACE(mid.inequality_columns,', ','_'),'[',''),']','')
        ELSE '' 
    END + ']' +
    ' ON ' + mid.statement +
    ' (' + ISNULL(mid.equality_columns,'') +
    CASE 
        WHEN mid.equality_columns IS NOT NULL AND mid.inequality_columns IS NOT NULL 
        THEN ',' 
        ELSE '' 
    END +
    ISNULL(mid.inequality_columns, '') + ')' +
    ISNULL(' INCLUDE (' + mid.included_columns + ')', '') AS create_index_statement,
    migs.avg_total_user_cost * (migs.avg_user_impact / 100.0) * (migs.user_seeks + migs.user_scans) AS total_impact,
    migs.avg_user_impact
FROM sys.dm_db_missing_index_group_stats AS migs
INNER JOIN sys.dm_db_missing_index_groups AS mig
    ON migs.group_handle = mig.index_group_handle
INNER JOIN sys.dm_db_missing_index_details AS mid
    ON mig.index_handle = mid.index_handle
WHERE mid.database_id = DB_ID('AdventureWorks2019')
ORDER BY improvement_measure DESC;

-- 2. Yavaş Çalışan Sorguları İyileştirme Örnekleri
-- Örnek 1: Satış raporu optimizasyonu
-- Önceki sorgu
/*
SELECT 
    p.Name AS ProductName,
    c.Name AS CategoryName,
    SUM(sod.OrderQty) AS TotalQuantity,
    SUM(sod.LineTotal) AS TotalAmount
FROM Sales.SalesOrderDetail sod
INNER JOIN Production.Product p ON sod.ProductID = p.ProductID
INNER JOIN Production.ProductSubcategory psc ON p.ProductSubcategoryID = psc.ProductSubcategoryID
INNER JOIN Production.ProductCategory c ON psc.ProductCategoryID = c.ProductCategoryID
GROUP BY p.Name, c.Name
ORDER BY TotalAmount DESC;
*/

-- Optimize edilmiş sorgu
SELECT 
    p.Name AS ProductName,
    c.Name AS CategoryName,
    SUM(sod.OrderQty) AS TotalQuantity,
    SUM(sod.LineTotal) AS TotalAmount
FROM Sales.SalesOrderDetail sod WITH (NOLOCK)
INNER JOIN Production.Product p WITH (NOLOCK) 
    ON sod.ProductID = p.ProductID
INNER JOIN Production.ProductSubcategory psc WITH (NOLOCK) 
    ON p.ProductSubcategoryID = psc.ProductSubcategoryID
INNER JOIN Production.ProductCategory c WITH (NOLOCK) 
    ON psc.ProductCategoryID = c.ProductCategoryID
WHERE sod.ModifiedDate >= DATEADD(MONTH, -1, GETDATE()) -- Son 1 aylık veri
GROUP BY p.Name, c.Name
ORDER BY TotalAmount DESC
OPTION (RECOMPILE);

-- 3. İstatistik Güncelleme
-- Tüm tabloların istatistiklerini güncelle
EXEC sp_updatestats;

-- 4. Sorgu İstatistiklerini Temizleme
DBCC FREEPROCCACHE;
DBCC DROPCLEANBUFFERS; 