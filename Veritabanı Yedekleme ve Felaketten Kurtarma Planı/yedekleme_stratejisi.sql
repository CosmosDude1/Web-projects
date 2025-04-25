-- ============================================================================
-- AdventureWorks2019 Veritabanı için Yedekleme Stratejisi (EXPRESS SÜRÜMÜ)
-- ============================================================================
USE master;
GO

-- Veritabanını SIMPLE recovery modeline al
ALTER DATABASE AdventureWorks2019 
SET RECOVERY SIMPLE;
GO

-- Yedekler için klasör yolu tanımlama
DECLARE @BackupDirectory NVARCHAR(255) = N'C:\SQL_Backups\AdventureWorks2019';
DECLARE @DatabaseName NVARCHAR(128) = N'AdventureWorks2019';
DECLARE @BackupDate NVARCHAR(20) = REPLACE(CONVERT(NVARCHAR, GETDATE(), 112) + '_' + 
    REPLACE(CONVERT(NVARCHAR, GETDATE(), 108), ':', ''), ' ', '_');

-- Yedekleme klasörünü oluştur (eğer yoksa)
DECLARE @Cmd NVARCHAR(500) = N'IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N''' + @BackupDirectory + ''') AND type IN (N''U'')) EXEC master.dbo.xp_create_subdir N''' + @BackupDirectory + '''';
EXEC sp_executesql @Cmd;

-- ============================================================================
-- TAM YEDEKLEME (FULL BACKUP)
-- ============================================================================
DECLARE @FullBackupFileName NVARCHAR(255) = @BackupDirectory + N'\' + @DatabaseName + 
    N'_FULL_' + @BackupDate + N'.bak';

BACKUP DATABASE @DatabaseName 
TO DISK = @FullBackupFileName
WITH 
    INIT, -- Yeni medya seti oluştur
    STATS = 10, -- İlerleme durumunu 10% aralıklarla göster
    CHECKSUM, -- Bütünlük kontrolü için checksum ekle
    DESCRIPTION = N'AdventureWorks2019 Tam Yedekleme';
GO

-- ============================================================================
-- YEDEKLEME DOĞRULAMA (BACKUP VALIDATION)
-- ============================================================================
-- Son yapılan yedeklemenin doğruluğunu kontrol et
DECLARE @LastBackupFile NVARCHAR(255);

SELECT TOP 1 @LastBackupFile = physical_device_name
FROM msdb.dbo.backupset bs
JOIN msdb.dbo.backupmediafamily bmf ON bs.media_set_id = bmf.media_set_id
WHERE database_name = N'AdventureWorks2019'
ORDER BY backup_start_date DESC;

IF @LastBackupFile IS NOT NULL
BEGIN
    RESTORE VERIFYONLY FROM DISK = @LastBackupFile;
END
GO

-- Yedekleme geçmişini görüntüle
SELECT 
    database_name,
    backup_start_date,
    backup_finish_date,
    CAST(backup_size/1024/1024 AS DECIMAL(10,2)) AS backup_size_mb,
    name AS backup_name,
    physical_device_name
FROM msdb.dbo.backupset bs
JOIN msdb.dbo.backupmediafamily bmf ON bs.media_set_id = bmf.media_set_id
WHERE database_name = N'AdventureWorks2019'
ORDER BY backup_start_date DESC;
GO

-- ============================================================================
-- KULLANIM ÖRNEKLERİ VE AÇIKLAMALAR (EXPRESS SÜRÜMÜ)
-- ============================================================================
/*
SQL SERVER EXPRESS YEDEKLEME STRATEJİSİ:

1. Tam Yedekleme (Full Backup):
   - Tüm veritabanının tam bir kopyasını alır
   - Önerilen sıklık: Günlük (düşük trafik saatlerinde)
   - Express sürümünde sadece tam yedekleme desteklenir
   - Sıkıştırma (COMPRESSION) desteklenmez

ÖNEMLİ NOTLAR:

1. Express sürümünde SQL Server Agent olmadığı için Windows Task Scheduler kullanın
2. Yedekleme dosyaları için yeterli disk alanı olduğundan emin olun
3. Yedeklemeleri düzenli test edin
4. Yedekleme dosyalarını farklı bir fiziksel lokasyonda da saklayın
5. Eski yedekleri temizlemek için bir bakım planı oluşturun

WINDOWS TASK SCHEDULER KULLANIMI:
1. Program: sqlcmd.exe
2. Argümanlar: -S .\SQLEXPRESS -E -i "C:\Scripts\yedekleme_stratejisi.sql"
3. Zamanlamayı günlük olarak ayarlayın

ESKİ YEDEKLERİ TEMİZLEME (CMD ile):
forfiles /p "C:\SQL_Backups\AdventureWorks2019" /s /m *.bak /d -30 /c "cmd /c del @path"
*/ 