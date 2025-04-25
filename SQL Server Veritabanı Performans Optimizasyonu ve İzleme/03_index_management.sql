USE AdventureWorks2019;
GO

-- İndeks Yönetimi Scripti
-- AdventureWorks2019 için indeks optimizasyonları

-- 1. Fragmentasyon Analizi
SELECT 
    OBJECT_NAME(ind.OBJECT_ID) AS TableName,
    ind.name AS IndexName,
    indexstats.avg_fragmentation_in_percent,
    indexstats.page_count,
    indexstats.record_count,
    indexstats.avg_page_space_used_in_percent
FROM sys.dm_db_index_physical_stats(DB_ID('AdventureWorks2019'), NULL, NULL, NULL, NULL) indexstats
INNER JOIN sys.indexes ind 
    ON ind.object_id = indexstats.object_id
    AND ind.index_id = indexstats.index_id
WHERE indexstats.avg_fragmentation_in_percent > 30
ORDER BY indexstats.avg_fragmentation_in_percent DESC;

-- 2. Kullanılmayan İndeksleri Bulma
SELECT 
    OBJECT_NAME(i.object_id) AS TableName,
    i.name AS IndexName,
    ius.user_seeks,
    ius.user_scans,
    ius.user_lookups,
    ius.user_updates,
    ius.last_user_seek,
    ius.last_user_scan,
    ius.last_user_lookup,
    ius.last_user_update
FROM sys.dm_db_index_usage_stats ius
INNER JOIN sys.indexes i 
    ON ius.object_id = i.object_id 
    AND ius.index_id = i.index_id
WHERE ius.database_id = DB_ID('AdventureWorks2019')
    AND ius.user_seeks = 0 
    AND ius.user_scans = 0 
    AND ius.user_lookups = 0
    AND ius.user_updates > 0;

-- 3. İndeks Bakımı
-- Fragmentasyonu %30'dan fazla olan indeksleri yeniden oluştur
DECLARE @TableName NVARCHAR(128)
DECLARE @IndexName NVARCHAR(128)
DECLARE @SQL NVARCHAR(MAX)

DECLARE IndexCursor CURSOR FOR
SELECT 
    OBJECT_NAME(ind.OBJECT_ID),
    ind.name
FROM sys.dm_db_index_physical_stats(DB_ID('AdventureWorks2019'), NULL, NULL, NULL, NULL) indexstats
INNER JOIN sys.indexes ind 
    ON ind.object_id = indexstats.object_id
    AND ind.index_id = indexstats.index_id
WHERE indexstats.avg_fragmentation_in_percent > 30
    AND ind.is_primary_key = 0;

OPEN IndexCursor
FETCH NEXT FROM IndexCursor INTO @TableName, @IndexName

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @SQL = 'ALTER INDEX [' + @IndexName + '] ON [' + @TableName + '] REBUILD'
    EXEC sp_executesql @SQL
    FETCH NEXT FROM IndexCursor INTO @TableName, @IndexName
END

CLOSE IndexCursor
DEALLOCATE IndexCursor;

-- 4. İndeks Kullanım İstatistiklerini Sıfırlama
DBCC DROPCLEANBUFFERS;
DBCC FREEPROCCACHE; 