-- ============================================================================
-- AdventureWorks2019 Veritabanı Eski Yedek Temizleme Scripti
-- ============================================================================

-- xp_cmdshell'i etkinleştir
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
GO

EXEC sp_configure 'xp_cmdshell', 1;
RECONFIGURE;
GO

-- Değişkenleri tanımla
DECLARE @BackupPath NVARCHAR(255) = N'C:\SQL_Backups\AdventureWorks2019';
DECLARE @DaysToKeep INT = 30;
DECLARE @DatabaseName NVARCHAR(128) = N'AdventureWorks2019';

-- Temizlik öncesi yedek dosyalarının durumunu kontrol et
PRINT 'Temizlik öncesi yedek dosyaları:';
DECLARE @PreCleanCmd NVARCHAR(500) = N'dir "' + @BackupPath + '"';
EXEC xp_cmdshell @PreCleanCmd;

-- Eski .bak dosyalarını temizle
DECLARE @CleanCmd NVARCHAR(500) = N'forfiles /p "' + @BackupPath + 
    '" /s /m *.bak /d -' + CAST(@DaysToKeep AS NVARCHAR(3)) + 
    ' /c "cmd /c del @path"';
EXEC xp_cmdshell @CleanCmd;

-- Temizlik sonrası kalan dosyaları listele
PRINT 'Temizlik sonrası kalan yedek dosyaları:';
DECLARE @PostCleanCmd NVARCHAR(500) = N'dir "' + @BackupPath + '"';
EXEC xp_cmdshell @PostCleanCmd;

-- Yedekleme geçmişini güncelle
PRINT 'Son 30 günlük yedekleme geçmişi:';
SELECT 
    database_name AS [Veritabanı],
    backup_start_date AS [Başlangıç],
    backup_finish_date AS [Bitiş],
    CAST(backup_size/1024/1024 AS DECIMAL(10,2)) AS [Boyut_MB],
    name AS [Yedek_Adı],
    physical_device_name AS [Dosya_Yolu]
FROM msdb.dbo.backupset bs
JOIN msdb.dbo.backupmediafamily bmf 
    ON bs.media_set_id = bmf.media_set_id
WHERE database_name = @DatabaseName
AND backup_start_date >= DATEADD(day, -@DaysToKeep, GETDATE())
ORDER BY backup_start_date DESC;

-- Disk alanı tasarrufu raporu
SELECT 
    COUNT(*) AS [Silinen_Dosya_Sayısı],
    CAST(SUM(backup_size)/1024/1024 AS DECIMAL(10,2)) AS [Temizlenen_Alan_MB]
FROM msdb.dbo.backupset bs
WHERE database_name = @DatabaseName
AND backup_start_date < DATEADD(day, -@DaysToKeep, GETDATE());

-- Kalan disk alanı kontrolü
SELECT 
    vs.volume_mount_point AS [Disk],
    CAST(vs.total_bytes/1024/1024/1024 AS DECIMAL(10,2)) AS [Toplam_GB],
    CAST(vs.available_bytes/1024/1024/1024 AS DECIMAL(10,2)) AS [Boş_GB],
    CAST(100 * vs.available_bytes / vs.total_bytes AS DECIMAL(5,2)) AS [Boş_Yüzde]
FROM sys.master_files AS f
CROSS APPLY sys.dm_os_volume_stats(f.database_id, f.file_id) vs
WHERE f.database_id = DB_ID(@DatabaseName)
GROUP BY vs.volume_mount_point, vs.total_bytes, vs.available_bytes; 