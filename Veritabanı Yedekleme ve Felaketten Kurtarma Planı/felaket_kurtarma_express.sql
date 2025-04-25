-- ============================================================================
-- AdventureWorks2019 Veritabanı Felaketten Kurtarma Senaryoları (EXPRESS SÜRÜMÜ)
-- ============================================================================

-- xp_cmdshell'i etkinleştir
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
GO

EXEC sp_configure 'xp_cmdshell', 1;
RECONFIGURE;
GO

USE master;
GO

-- ============================================================================
-- 1. TAM GERİ YÜKLEME (FULL RESTORE)
-- ============================================================================
/* 
Bu senaryoda, veritabanı tamamen kaybedilmiş veya yeni bir sunucuya 
taşınması gerektiğinde kullanılacak tam geri yükleme işlemi.
*/

-- Tam bir yedekten geri yükleme işlemi
DECLARE @BackupFile NVARCHAR(255) = N'C:\SQL_Backups\AdventureWorks2019\AdventureWorks2019_FULL_20250423_120000.bak';
DECLARE @DataFileLocation NVARCHAR(255) = N'C:\Program Files\Microsoft SQL Server\MSSQL16.SQLEXPRESS\MSSQL\DATA\';
DECLARE @LogFileLocation NVARCHAR(255) = N'C:\Program Files\Microsoft SQL Server\MSSQL16.SQLEXPRESS\MSSQL\DATA\';

-- Eğer veritabanı varsa, bağlantıları kapat ve veritabanını sil
IF DB_ID('AdventureWorks2019') IS NOT NULL
BEGIN
    ALTER DATABASE AdventureWorks2019 SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE AdventureWorks2019;
END

-- Tam yedekten geri yükleme işlemi
RESTORE DATABASE AdventureWorks2019
FROM DISK = @BackupFile
WITH 
    MOVE 'AdventureWorks2019' TO CONCAT(@DataFileLocation, N'AdventureWorks2019.mdf'),
    MOVE 'AdventureWorks2019_log' TO CONCAT(@LogFileLocation, N'AdventureWorks2019_log.ldf'),
    STATS = 10,
    RECOVERY; -- Tam geri yükleme için RECOVERY kullanılır

-- Çoklu kullanıcı moduna geri dön
ALTER DATABASE AdventureWorks2019 SET MULTI_USER;
GO

-- ============================================================================
-- 2. BELİRLİ BİR ZAMANA GERİ YÜKLEME (POINT-IN-TIME RECOVERY)
-- ============================================================================
/*
Bu senaryoda, veritabanında belirli bir hata olduğunda veya yanlışlıkla 
veri silindiğinde, belirli bir zaman noktasına geri dönüş yapılabilir.
*/

-- Tam, fark ve işlem günlüğü yedeklerini kullanarak belirli bir zamana geri yükleme
DECLARE @FullBackupFile NVARCHAR(255) = N'C:\SQL_Backups\AdventureWorks2019\AdventureWorks2019_FULL_20250423_120000.bak';
DECLARE @DiffBackupFile NVARCHAR(255) = N'C:\SQL_Backups\AdventureWorks2019\AdventureWorks2019_DIFF_20250424_000000.bak';
DECLARE @LogBackupFile1 NVARCHAR(255) = N'C:\SQL_Backups\AdventureWorks2019\AdventureWorks2019_LOG_20250424_010000.trn';
DECLARE @LogBackupFile2 NVARCHAR(255) = N'C:\SQL_Backups\AdventureWorks2019\AdventureWorks2019_LOG_20250424_020000.trn';
DECLARE @LogBackupFile3 NVARCHAR(255) = N'C:\SQL_Backups\AdventureWorks2019\AdventureWorks2019_LOG_20250424_030000.trn';
DECLARE @PointInTime DATETIME = '2025-04-24 02:30:00'; -- Geri dönmek istediğimiz tarih/saat
DECLARE @DataFileLocation NVARCHAR(255) = N'C:\Program Files\Microsoft SQL Server\MSSQL16.SQLEXPRESS\MSSQL\DATA\';
DECLARE @LogFileLocation NVARCHAR(255) = N'C:\Program Files\Microsoft SQL Server\MSSQL16.SQLEXPRESS\MSSQL\DATA\';

-- Eğer veritabanı varsa, bağlantıları kapat ve veritabanını sil
IF DB_ID('AdventureWorks2019') IS NOT NULL
BEGIN
    ALTER DATABASE AdventureWorks2019 SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE AdventureWorks2019;
END

-- 1. Tam yedekten geri yükleme - NORECOVERY ile
RESTORE DATABASE AdventureWorks2019
FROM DISK = @FullBackupFile
WITH 
    MOVE 'AdventureWorks2019' TO CONCAT(@DataFileLocation, N'AdventureWorks2019.mdf'),
    MOVE 'AdventureWorks2019_log' TO CONCAT(@LogFileLocation, N'AdventureWorks2019_log.ldf'),
    NORECOVERY, -- Daha fazla yedek uygulanacağı için NORECOVERY
    STATS = 10;

-- 2. Fark yedeğini uygulama - NORECOVERY ile
RESTORE DATABASE AdventureWorks2019
FROM DISK = @DiffBackupFile
WITH 
    NORECOVERY, -- Daha fazla log yedeği uygulanacağı için NORECOVERY
    STATS = 10;

-- 3. Log yedeklerini uygulama - İlk iki log NORECOVERY ile
RESTORE LOG AdventureWorks2019
FROM DISK = @LogBackupFile1
WITH 
    NORECOVERY, 
    STATS = 10;

RESTORE LOG AdventureWorks2019
FROM DISK = @LogBackupFile2
WITH 
    NORECOVERY, 
    STATS = 10;

-- 4. Son log yedeğini belirli bir zamana kadar uygulama - RECOVERY ile
RESTORE LOG AdventureWorks2019
FROM DISK = @LogBackupFile3
WITH 
    RECOVERY, -- Son işlem olduğu için RECOVERY 
    STOPAT = @PointInTime, -- Belirli zaman noktasına kadar
    STATS = 10;

-- Çoklu kullanıcı moduna geri dön
ALTER DATABASE AdventureWorks2019 SET MULTI_USER;
GO

-- ============================================================================
-- 3. SAYFA DÜZELT GERİ YÜKLEME (PAGE RESTORE) - EXPRESS SÜRÜMÜNDE DESTEKLENMEZ
-- ============================================================================
/*
NOT: Bu bölüm SQL Server Express sürümünde desteklenmediği için yorum satırına alınmıştır.
Aşağıdaki kodlar sadece referans amaçlı bırakılmıştır.

Bu senaryoda, veritabanının sadece belirli bir sayfası veya veri dosyasının
bir bölümü bozulduğunda, tüm veritabanını değil sadece o bölümü kurtarıyoruz.

-- Bozuk sayfaları belirleme
SELECT * FROM msdb.dbo.suspect_pages
WHERE database_id = DB_ID('AdventureWorks2019')
ORDER BY last_update_date DESC;

-- Sayfa ID'sini belirledikten sonra, o sayfayı onarma (örnek)
DECLARE @PageID INT = 1234; -- Örnek bir sayfa ID
DECLARE @FullBackupFile NVARCHAR(255) = N'C:\SQL_Backups\AdventureWorks2019\AdventureWorks2019_FULL_20250423_120000.bak';
DECLARE @DiffBackupFile NVARCHAR(255) = N'C:\SQL_Backups\AdventureWorks2019\AdventureWorks2019_DIFF_20250424_000000.bak';
DECLARE @LogBackupFile NVARCHAR(255) = N'C:\SQL_Backups\AdventureWorks2019\AdventureWorks2019_LOG_20250424_010000.trn';

-- Veritabanını tek kullanıcı moduna al (sayfalar tamir edilirken veritabanı çevrimiçi kalabilir)
ALTER DATABASE AdventureWorks2019 SET SINGLE_USER WITH ROLLBACK IMMEDIATE;

-- Tam yedeği kullan ve sayfa onarımı için hazırla
RESTORE DATABASE AdventureWorks2019 
PAGE = @PageID
FROM DISK = @FullBackupFile
WITH NORECOVERY;

-- Fark yedeğinden sayfa onarımı yap
RESTORE DATABASE AdventureWorks2019 
PAGE = @PageID
FROM DISK = @DiffBackupFile
WITH NORECOVERY;

-- Log yedeğinden sayfa onarımı tamamla
RESTORE LOG AdventureWorks2019 
FROM DISK = @LogBackupFile
WITH RECOVERY;

-- Çoklu kullanıcı moduna geri dön
ALTER DATABASE AdventureWorks2019 SET MULTI_USER;
*/

-- ============================================================================
-- 4. VERİTABANI MIRRORING İLE FELAKET KURTARMA - EXPRESS SÜRÜMÜNDE DESTEKLENMEZ
-- ============================================================================
/*
NOT: Bu bölüm SQL Server Express sürümünde desteklenmediği için yorum satırına alınmıştır.
Aşağıdaki kodlar sadece referans amaçlı bırakılmıştır.

Bu senaryoda, yüksek erişilebilirlik için Database Mirroring yapılandırılır.
Ana sunucu çalışmaz hale geldiğinde, otomatik olarak yedek sunucuya geçiş yapılır.

-- Birincil sunucuda (Principal Server) yapılandırma
-- Mirroring için veritabanını hazırla
ALTER DATABASE AdventureWorks2019 SET RECOVERY FULL;

-- Tam yedek al (Mirror sunucuya taşınacak)
BACKUP DATABASE AdventureWorks2019 
TO DISK = N'C:\SQL_Backups\AdventureWorks2019\AdventureWorks2019_Mirror_Full.bak'
WITH FORMAT;

-- İşlem günlüğünün yedeğini al
BACKUP LOG AdventureWorks2019 
TO DISK = N'C:\SQL_Backups\AdventureWorks2019\AdventureWorks2019_Mirror_Log.trn';

-- Mirroring için endpoint oluştur
CREATE ENDPOINT [Mirroring] 
STATE = STARTED 
AS TCP (LISTENER_PORT = 5022) 
FOR DATABASE_MIRRORING (ROLE = PARTNER, AUTHENTICATION = WINDOWS NEGOTIATE);

-- Mirroring başlat
ALTER DATABASE AdventureWorks2019 
SET PARTNER = 'TCP://MIRROR_SERVER_NAME:5022';

-- İkincil sunucuda (Mirror Server) yapılandırma (bu kodlar MIRROR_SERVER'da çalıştırılmalı)
-- Yedek yükleme
RESTORE DATABASE AdventureWorks2019 
FROM DISK = N'C:\SQL_Backups\AdventureWorks2019\AdventureWorks2019_Mirror_Full.bak'
WITH NORECOVERY;

-- Log yedeğini yükle
RESTORE LOG AdventureWorks2019 
FROM DISK = N'C:\SQL_Backups\AdventureWorks2019\AdventureWorks2019_Mirror_Log.trn'
WITH NORECOVERY;

-- Mirroring için endpoint oluştur
CREATE ENDPOINT [Mirroring] 
STATE = STARTED 
AS TCP (LISTENER_PORT = 5022) 
FOR DATABASE_MIRRORING (ROLE = PARTNER, AUTHENTICATION = WINDOWS NEGOTIATE);

-- Mirroring başlat
ALTER DATABASE AdventureWorks2019 
SET PARTNER = 'TCP://PRINCIPAL_SERVER_NAME:5022';

-- İsteğe bağlı olarak üçüncü bir sunucu Witness olarak yapılandırılabilir
-- (Automatic Failover için gereklidir)
-- Witness sunucuda:
CREATE ENDPOINT [Mirroring] 
STATE = STARTED 
AS TCP (LISTENER_PORT = 5022) 
FOR DATABASE_MIRRORING (ROLE = WITNESS, AUTHENTICATION = WINDOWS NEGOTIATE);

-- Birincil sunucuda:
ALTER DATABASE AdventureWorks2019 
SET WITNESS = 'TCP://WITNESS_SERVER_NAME:5022';
*/

-- ============================================================================
-- 5. KAZARA SİLİNEN VERİLERİ GERİ GETİRME
-- ============================================================================
/*
Bu senaryoda, kazara silinen bir tablo veya verileri geri getirmek için
belirli bir zaman noktasına geri dönüş yaparız, sonra silinen verileri 
orijinal veritabanına kopyalarız.
*/

-- Önce silinen verinin tarihini not ederiz
-- Diyelim ki HumanResources.Employee tablosundaki bazı veriler 2025-04-24 10:15 civarında silindi

-- 1. Geçici bir kurtarma veritabanı oluştur
DECLARE @FullBackupFile NVARCHAR(255) = N'C:\SQL_Backups\AdventureWorks2019\AdventureWorks2019_FULL_20250423_120000.bak';
DECLARE @DiffBackupFile NVARCHAR(255) = N'C:\SQL_Backups\AdventureWorks2019\AdventureWorks2019_DIFF_20250424_000000.bak';
DECLARE @LogBackupFile1 NVARCHAR(255) = N'C:\SQL_Backups\AdventureWorks2019\AdventureWorks2019_LOG_20250424_100000.trn';
DECLARE @PointInTime DATETIME = '2025-04-24 10:14:00'; -- Silme işleminden hemen önceki zaman
DECLARE @DataFileLocation NVARCHAR(255) = N'C:\Program Files\Microsoft SQL Server\MSSQL16.SQLEXPRESS\MSSQL\DATA\';
DECLARE @LogFileLocation NVARCHAR(255) = N'C:\Program Files\Microsoft SQL Server\MSSQL16.SQLEXPRESS\MSSQL\DATA\';

-- Eğer kurtarma veritabanı varsa sil
IF DB_ID('AdventureWorks2019_Recovery') IS NOT NULL
BEGIN
    DROP DATABASE AdventureWorks2019_Recovery;
END

-- Tam yedekten kurtarma veritabanını oluştur
RESTORE DATABASE AdventureWorks2019_Recovery
FROM DISK = @FullBackupFile
WITH 
    MOVE 'AdventureWorks2019' TO CONCAT(@DataFileLocation, N'AdventureWorks2019_Recovery.mdf'),
    MOVE 'AdventureWorks2019_log' TO CONCAT(@LogFileLocation, N'AdventureWorks2019_Recovery_log.ldf'),
    NORECOVERY, 
    STATS = 10;

-- Fark yedeğini uygula
RESTORE DATABASE AdventureWorks2019_Recovery
FROM DISK = @DiffBackupFile
WITH 
    NORECOVERY, 
    STATS = 10;

-- İşlem günlüğünü belirli bir zamana kadar uygula
RESTORE LOG AdventureWorks2019_Recovery
FROM DISK = @LogBackupFile1
WITH 
    RECOVERY,
    STOPAT = @PointInTime,
    STATS = 10;

-- 2. Şimdi silinen verileri kurtarma veritabanından asıl veritabanına kopyalayabiliriz
-- Örnek INSERT INTO ile kopyalama
/*
INSERT INTO AdventureWorks2019.HumanResources.Employee
SELECT * FROM AdventureWorks2019_Recovery.HumanResources.Employee
WHERE BusinessEntityID NOT IN (
    SELECT BusinessEntityID FROM AdventureWorks2019.HumanResources.Employee
);
*/

-- 3. Doğrulama ve temizlik
-- Geri yüklenen verileri doğrula
SELECT COUNT(*) AS RecoveredRowCount 
FROM AdventureWorks2019_Recovery.HumanResources.Employee;

SELECT COUNT(*) AS OriginalRowCount 
FROM AdventureWorks2019.HumanResources.Employee;

-- Kurtarma veritabanını sil
DROP DATABASE AdventureWorks2019_Recovery;
GO

-- ============================================================================
-- 6. DAHA BÜYÜK FELAKETLER İÇİN KURTARMA SENARYOLARI - KISMİ DESTEKLENEN
-- ============================================================================
/*
Bu senaryolarda, sunucu tamamen çalışmaz durumda olduğunda veya 
veri merkezi kaybı durumlarında uygulanacak planlar tanımlanır.
Bunlar genellikle tam bir DR (Disaster Recovery) stratejisinin parçasıdır.
*/

/*
-- Tüm sistem veritabanlarını da içeren tam sunucu geri yükleme
-- 1. Yeni bir SQL Server yükleyin
-- 2. SQL Server servisini başlatın
-- 3. master, model ve msdb sistem veritabanlarını geri yükleme
RESTORE DATABASE master
FROM DISK = N'C:\SQL_Backups\SystemDBs\master.bak'
WITH REPLACE;

-- 4. SQL Server'ı yeniden başlat
-- 5. Diğer sistem veritabanlarını geri yükle
RESTORE DATABASE model
FROM DISK = N'C:\SQL_Backups\SystemDBs\model.bak'
WITH REPLACE;

RESTORE DATABASE msdb
FROM DISK = N'C:\SQL_Backups\SystemDBs\msdb.bak'
WITH REPLACE;

-- 6. Kullanıcı veritabanlarını geri yükle
RESTORE DATABASE AdventureWorks2019
FROM DISK = N'C:\SQL_Backups\AdventureWorks2019\AdventureWorks2019_FULL_20250423_120000.bak'
WITH RECOVERY, REPLACE;
*/

-- ============================================================================
-- 7. ÖRNEK SENARYOLAR VE TEST STRATEJİLERİ
-- ============================================================================
-- Düzenli test edilen felaket kurtarma planı adımları

-- Örnek Test Senaryosu 1: Yanlışlıkla silinen verilerin kurtarılması
/*
1. Test amacıyla silme işlemi:
   DELETE FROM AdventureWorks2019.Sales.SalesOrderDetail WHERE SalesOrderID = 43659;
   
2. İşlem günlüğü yedeği al
   BACKUP LOG AdventureWorks2019 TO DISK = N'C:\SQL_Backups\AdventureWorks2019\Test_LOG.trn';

3. Kurtarma işlemini uygula (yukarıdaki 5. senaryoda olduğu gibi)

4. Silinen verileri değerlendir
   SELECT * FROM AdventureWorks2019_Recovery.Sales.SalesOrderDetail WHERE SalesOrderID = 43659;

5. Verileri geri yükle
   INSERT INTO AdventureWorks2019.Sales.SalesOrderDetail
   SELECT * FROM AdventureWorks2019_Recovery.Sales.SalesOrderDetail 
   WHERE SalesOrderID = 43659;

6. Doğrula
   SELECT COUNT(*) FROM AdventureWorks2019.Sales.SalesOrderDetail WHERE SalesOrderID = 43659;
*/

-- Örnek Test Senaryosu 2: Yanlış bir TRUNCATE komutu sonrası kurtarma
/*
1. Test amacıyla tablonun yedeğini al
   SELECT * INTO Sales.SalesOrderDetail_Backup FROM AdventureWorks2019.Sales.SalesOrderDetail;

2. Yanlışlıkla truncate işlemi
   TRUNCATE TABLE AdventureWorks2019.Sales.SalesOrderDetail;

3. Kurtarma işlemini uygula (yukarıdaki senaryolarda olduğu gibi point-in-time recovery)

4. Tabloyu karşılaştır ve doğrula
   SELECT COUNT(*) FROM AdventureWorks2019_Recovery.Sales.SalesOrderDetail;
   
5. Truncate yapılan tabloya verileri geri yükle
   INSERT INTO AdventureWorks2019.Sales.SalesOrderDetail
   SELECT * FROM AdventureWorks2019_Recovery.Sales.SalesOrderDetail;

6. Verileri geri yükledikten sonra yedek tabloyu kaldırabilirsiniz
   DROP TABLE Sales.SalesOrderDetail_Backup;
*/

-- ============================================================================
-- 8. YEDEKLERİN VE KURTARMA PLANLARININ DOKÜMANTASYONU
-- ============================================================================
/*
Aşağıdaki bilgileri içeren bir dokümantasyon hazırlayın:

1. Yedekleme Planı
   - Tam Yedekleme: Her Pazar 01:00
   - Fark Yedeklemesi: Her gün 00:00
   - İşlem Günlüğü Yedeklemesi: Her saat başı

2. Saklama Politikası
   - Tam Yedeklemeler: 60 gün
   - Fark Yedeklemeleri: 30 gün
   - İşlem Günlüğü Yedeklemeleri: 7 gün

3. Kurtarma Süresi Hedefleri (RTO)
   - Kritik İş Uygulamaları: 1 saat
   - Standart Uygulamalar: 4 saat

4. Veri Kaybı Hedefleri (RPO)
   - Kritik İş Uygulamaları: 15 dakika
   - Standart Uygulamalar: 1 saat

5. Kurtarma Talimatları
   - Bu betikteki senaryoları içeren adım adım talimatlar

6. İletişim Planı
   - Acil durumda aranacak kişiler ve iletişim bilgileri
   - Eskalasyon prosedürleri
*/

-- ============================================================================
-- AdventureWorks2019 Veritabanı Yedekleme Stratejisi (EXPRESS SÜRÜMÜ)
-- ============================================================================
USE master;
GO

-- Veritabanını SIMPLE recovery modeline al
ALTER DATABASE AdventureWorks2019 
SET RECOVERY SIMPLE;
GO

-- Yedekleme dizini oluştur
DECLARE @BackupPath NVARCHAR(255) = N'C:\SQL_Backups\AdventureWorks2019';
DECLARE @Cmd NVARCHAR(500) = N'IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N''' + @BackupPath + ''') AND type IN (N''U'')) EXEC master.dbo.xp_create_subdir N''' + @BackupPath + '''';
EXEC sp_executesql @Cmd;

-- Tam yedek al (COMPRESSION olmadan)
DECLARE @FullBackupFile NVARCHAR(255) = @BackupPath + N'\AdventureWorks2019_FULL_' + REPLACE(CONVERT(NVARCHAR(20), GETDATE(), 120), ':', '') + N'.bak';

BACKUP DATABASE AdventureWorks2019 
TO DISK = @FullBackupFile
WITH 
    INIT,
    NAME = N'AdventureWorks2019-Full Database Backup',
    STATS = 10;
GO

-- Yedek doğrulama
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

-- Eski yedekleri temizleme (30 günden eski)
DECLARE @BackupPath NVARCHAR(255) = N'C:\SQL_Backups\AdventureWorks2019';
DECLARE @cmd NVARCHAR(500) = N'forfiles /p "' + @BackupPath + '" /s /m *.bak /d -30 /c "cmd /c del @path"';
EXEC xp_cmdshell @cmd;
GO

-- NOT: Bu script'i SQL Server Agent Job olarak zamanlanmış görev şeklinde çalıştırabilirsiniz
-- Express sürümünde SQL Server Agent olmadığı için Windows Task Scheduler kullanabilirsiniz
/*
Windows Task Scheduler için örnek komut:
sqlcmd -S .\SQLEXPRESS -E -i "C:\Scripts\yedekleme_express.sql"
*/ 