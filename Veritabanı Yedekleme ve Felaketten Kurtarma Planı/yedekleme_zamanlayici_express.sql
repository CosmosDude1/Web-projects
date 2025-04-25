-- ============================================================================
-- AdventureWorks2019 Veritabanı için Windows Task Scheduler Yedekleme Scripti
-- ============================================================================
USE master;
GO

-- Veritabanını SIMPLE recovery modeline al
ALTER DATABASE AdventureWorks2019 
SET RECOVERY SIMPLE;
GO

-- Yedekleme işlemi için tek bir script
DECLARE @BackupDirectory NVARCHAR(255) = N'C:\SQL_Backups\AdventureWorks2019';
DECLARE @DatabaseName NVARCHAR(128) = N'AdventureWorks2019';
DECLARE @BackupDate NVARCHAR(20) = REPLACE(CONVERT(NVARCHAR, GETDATE(), 112) + '_' + 
    REPLACE(CONVERT(NVARCHAR, GETDATE(), 108), ':', ''), ' ', '_');

-- Yedekleme klasörünü oluştur (eğer yoksa)
DECLARE @Cmd NVARCHAR(500) = N'IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N''' + @BackupDirectory + ''') AND type IN (N''U'')) EXEC master.dbo.xp_create_subdir N''' + @BackupDirectory + '''';
EXEC sp_executesql @Cmd;

-- Tam Yedekleme Dosya Adı
DECLARE @FullBackupFileName NVARCHAR(255) = @BackupDirectory + N'\' + @DatabaseName + 
    N'_FULL_' + @BackupDate + N'.bak';

-- Tam Yedekleme
BACKUP DATABASE @DatabaseName 
TO DISK = @FullBackupFileName
WITH 
    INIT,
    STATS = 10,
    CHECKSUM,
    DESCRIPTION = N'AdventureWorks2019 Günlük Tam Yedekleme';

-- Yedekleme doğrulama
RESTORE VERIFYONLY FROM DISK = @FullBackupFileName;
GO

/*
WINDOWS TASK SCHEDULER KURULUM TALİMATLARI:

1. Windows Task Scheduler'ı açın (taskschd.msc)

2. İki ayrı görev oluşturun:

A) YEDEKLEME GÖREVİ
   "Temel Görev Oluştur" seçeneğine tıklayın:
   - Ad: "AdventureWorks2019 Günlük Yedekleme"
   - Açıklama: "AdventureWorks2019 veritabanının günlük tam yedeğini alır"
   - Başlangıç: Her gün
   - Saat: 01:00
   - Program/script: sqlcmd
   - Argümanlar: -S .\SQLEXPRESS -E -i "C:\Scripts\yedekleme_zamanlayici_express.sql"
   - Başlangıç konumu: C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\170\Tools\Binn

B) TEMİZLEME GÖREVİ
   "Temel Görev Oluştur" seçeneğine tıklayın:
   - Ad: "AdventureWorks2019 Eski Yedek Temizleme"
   - Açıklama: "30 günden eski yedekleri temizler"
   - Başlangıç: Her gün
   - Saat: 02:00
   - Program/script: powershell
   - Argümanlar: -ExecutionPolicy Bypass -File "C:\Scripts\temizle_yedekler.ps1"

Her iki görev için de:
- "Görev açık olduğunda en yüksek ayrıcalıklarla çalıştır" seçeneğini işaretleyin
- "Yapılandır" kısmında "Windows Server 2003, Windows XP veya Windows 2000" seçeneğini işaretleyin

NOT: 
1. Bu scripti C:\Scripts klasörüne kaydedin
2. Aşağıdaki PowerShell scriptini de "temizle_yedekler.ps1" adıyla C:\Scripts klasörüne kaydedin
*/ 