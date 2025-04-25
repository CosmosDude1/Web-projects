-- ============================================================================
-- AdventureWorks2019 Veritabanı Yedek Doğrulama Scripti
-- ============================================================================

-- Değişkenleri tanımla
DECLARE @BackupPath NVARCHAR(255) = N'C:\SQL_Backups\AdventureWorks2019';
DECLARE @DatabaseName NVARCHAR(128) = N'AdventureWorks2019';

-- Son yedeklemeyi bul ve doğrula
DECLARE @LastBackupFile NVARCHAR(255);
SELECT TOP 1 @LastBackupFile = physical_device_name
FROM msdb.dbo.backupset bs
JOIN msdb.dbo.backupmediafamily bmf 
    ON bs.media_set_id = bmf.media_set_id
WHERE database_name = @DatabaseName
ORDER BY backup_start_date DESC;

-- Yedeği doğrula
IF @LastBackupFile IS NOT NULL
BEGIN
    PRINT 'Yedek dosyası doğrulanıyor: ' + @LastBackupFile;
    RESTORE VERIFYONLY FROM DISK = @LastBackupFile;
END
ELSE
BEGIN
    PRINT 'Yedek dosyası bulunamadı!';
END

-- Son 7 günlük yedekleme geçmişini kontrol et
SELECT 
    database_name AS [Veritabanı],
    backup_start_date AS [Başlangıç],
    backup_finish_date AS [Bitiş],
    CAST(backup_size/1024/1024 AS DECIMAL(10,2)) AS [Boyut_MB],
    CAST(compressed_backup_size/1024/1024 AS DECIMAL(10,2)) AS [Sıkıştırılmış_MB],
    name AS [Yedek_Adı],
    physical_device_name AS [Dosya_Yolu],
    CASE type 
        WHEN 'D' THEN 'Tam Yedekleme'
        WHEN 'I' THEN 'Fark Yedeklemesi'
        WHEN 'L' THEN 'İşlem Günlüğü'
        ELSE 'Diğer' 
    END AS [Yedek_Türü]
FROM msdb.dbo.backupset bs
JOIN msdb.dbo.backupmediafamily bmf 
    ON bs.media_set_id = bmf.media_set_id
WHERE database_name = @DatabaseName
AND backup_start_date >= DATEADD(day, -7, GETDATE())
ORDER BY backup_start_date DESC;

-- Yedekleme başarı oranını kontrol et
SELECT 
    CAST(COUNT(CASE WHEN has_backup_checksums = 1 THEN 1 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS [Checksum_Yüzdesi],
    CAST(COUNT(CASE WHEN is_damaged = 0 THEN 1 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS [Sağlam_Yedek_Yüzdesi],
    COUNT(*) AS [Toplam_Yedek_Sayısı]
FROM msdb.dbo.backupset
WHERE database_name = @DatabaseName
AND backup_start_date >= DATEADD(day, -7, GETDATE());

-- Disk alanı kontrolü
SELECT 
    vs.volume_mount_point AS [Disk],
    vs.logical_volume_name AS [Mantıksal_Ad],
    CAST(vs.total_bytes/1024/1024/1024 AS DECIMAL(10,2)) AS [Toplam_GB],
    CAST(vs.available_bytes/1024/1024/1024 AS DECIMAL(10,2)) AS [Boş_GB],
    CAST(100 * vs.available_bytes / vs.total_bytes AS DECIMAL(5,2)) AS [Boş_Yüzde]
FROM sys.master_files AS f
CROSS APPLY sys.dm_os_volume_stats(f.database_id, f.file_id) vs
WHERE f.database_id = DB_ID(@DatabaseName)
GROUP BY vs.volume_mount_point, vs.logical_volume_name, vs.total_bytes, vs.available_bytes; 