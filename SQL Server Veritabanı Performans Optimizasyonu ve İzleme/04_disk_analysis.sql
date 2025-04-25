USE AdventureWorks2019;
GO

-- Disk ve Veri Yoğunluğu Analizi Scripti
-- AdventureWorks2019 için disk optimizasyonları

-- 1. Veritabanı Boyut Analizi
SELECT 
    DB_NAME() AS DatabaseName,
    name AS FileName,
    size/128.0 AS CurrentSizeMB,
    size/128.0 - CAST(FILEPROPERTY(name, 'SpaceUsed') AS INT)/128.0 AS FreeSpaceMB,
    CAST(FILEPROPERTY(name, 'SpaceUsed') AS INT)/128.0 AS UsedSpaceMB,
    (CAST(FILEPROPERTY(name, 'SpaceUsed') AS FLOAT)/size)*100 AS UsedSpacePercentage
FROM sys.database_files
WHERE type_desc = 'ROWS';

-- 2. Tablo Boyut Analizi
SELECT 
    t.NAME AS TableName,
    s.Name AS SchemaName,
    p.rows AS [RowCount],
    CAST(ROUND((SUM(a.total_pages) * 8) / 1024.00, 2) AS NUMERIC(36, 2)) AS TotalSpaceMB,
    CAST(ROUND((SUM(a.used_pages) * 8) / 1024.00, 2) AS NUMERIC(36, 2)) AS UsedSpaceMB,
    CAST(ROUND(((SUM(a.total_pages) - SUM(a.used_pages)) * 8) / 1024.00, 2) AS NUMERIC(36, 2)) AS UnusedSpaceMB
FROM sys.tables t
INNER JOIN sys.indexes i ON t.OBJECT_ID = i.object_id
INNER JOIN sys.partitions p ON i.object_id = p.OBJECT_ID AND i.index_id = p.index_id
INNER JOIN sys.allocation_units a ON p.partition_id = a.container_id
INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE t.NAME NOT LIKE 'dtproperties' AND i.index_id <= 1
GROUP BY t.Name, s.Name, p.Rows
ORDER BY TotalSpaceMB DESC;

-- 3. Log Dosyası Analizi
SELECT 
    DB_NAME() AS DatabaseName,
    name AS LogFileName,
    size/128.0 AS CurrentSizeMB,
    max_size/128.0 AS MaxSizeMB,
    growth AS GrowthMB,
    is_percent_growth
FROM sys.database_files
WHERE type_desc = 'LOG';

-- 4. Veri Sıkıştırma Önerileri
SELECT 
    t.name AS TableName,
    i.name AS IndexName,
    i.type_desc AS IndexType,
    p.data_compression_desc AS CompressionType,
    p.[rows] AS [RowCount],
    CAST(ROUND((SUM(a.total_pages) * 8) / 1024.00, 2) AS NUMERIC(36, 2)) AS TotalSpaceMB
FROM sys.tables t
INNER JOIN sys.indexes i ON t.object_id = i.object_id
INNER JOIN sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
INNER JOIN sys.allocation_units a ON p.partition_id = a.container_id
WHERE t.is_ms_shipped = 0
GROUP BY t.name, i.name, i.type_desc, p.data_compression_desc, p.[rows]
HAVING SUM(a.total_pages) > 1000  -- 8MB'dan büyük tablolar
ORDER BY TotalSpaceMB DESC;

-- 5. Tempdb Kullanım Analizi
SELECT 
    s.session_id,
    r.request_id,
    r.cpu_time,
    r.reads,
    r.writes,
    r.logical_reads,
    r.[row_count] AS [RowCount],
    r.start_time,
    r.status,
    r.command,
    r.wait_type,
    r.wait_time,
    r.last_wait_type,
    r.blocking_session_id,
    r.open_transaction_count,
    s.login_time,
    s.host_name,
    s.program_name,
    s.login_name
FROM sys.dm_exec_sessions s
INNER JOIN sys.dm_exec_requests r ON s.session_id = r.session_id
WHERE s.session_id > 50; 