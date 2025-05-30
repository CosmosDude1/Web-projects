-- ===================================================
-- SQL Güvenlik ve Erişim Kontrolü Projesi
-- Adım 7: Audit Loglarını Görüntüleme ve Dışa Aktarma
-- ===================================================

USE master;
GO

-- ===================================================
-- AUDIT LOGLARINI GÖRÜNTÜLEME
-- ===================================================

PRINT '=== AUDIT LOGLARI GÖRÜNTÜLENİYOR ===';
GO

-- Audit dosyalarının listesini al
SELECT
    sa.name AS audit_name,
    sfn.audit_file_path,
    sa.is_state_enabled
FROM sys.server_audits sa
LEFT JOIN sys.dm_server_audit_status sfn ON sa.audit_id = sfn.audit_id
WHERE sa.name = N'SecureDB_Audit';
GO

-- Audit loglarını oku ve görüntüle
SELECT TOP 50
    event_time,
    action_id,
    succeeded,
    permission_bitmask,
    is_column_permission,
    session_id,
    server_principal_name,
    database_principal_name,
    target_server_principal_name,
    target_database_principal_name,
    object_name,
    class_type,
    session_server_principal_name,
    server_instance_name,
    database_name,
    schema_name,
    object_id,
    file_name,
    audit_file_offset,
    user_defined_event_id,
    user_defined_information,
    audit_schema_version,
    sequence_number,
    action_id_desc = 
        CASE action_id
            WHEN 'LGIS' THEN 'LOGIN SUCCESS'
            WHEN 'LGIF' THEN 'LOGIN FAILED'
            WHEN 'LGO' THEN 'LOGOUT'
            WHEN 'SL' THEN 'SELECT'
            WHEN 'IN' THEN 'INSERT'
            WHEN 'UP' THEN 'UPDATE'
            WHEN 'DL' THEN 'DELETE'
            ELSE action_id
        END,
    statement
FROM fn_get_audit_file('C:\AuditLogs\SecureDB_Audit_*.sqlaudit', DEFAULT, DEFAULT)
ORDER BY event_time DESC;
GO

-- ===================================================
-- BELIRLI OLAYLARI FİLTRELEME
-- ===================================================

PRINT '=== LOGIN OLAYLARI ===';
GO

-- Sadece login olayları
SELECT 
    event_time,
    action_id,
    succeeded,
    server_principal_name,
    session_server_principal_name,
    statement
FROM fn_get_audit_file('C:\AuditLogs\SecureDB_Audit_*.sqlaudit', DEFAULT, DEFAULT)
WHERE action_id IN ('LGIS', 'LGIF', 'LGO')
ORDER BY event_time DESC;
GO

PRINT '=== SENSİTİVE DATA TABLOSI ERİŞİMLERİ ===';
GO

-- SensitiveData tablosu erişimleri
SELECT 
    event_time,
    action_id,
    succeeded,
    server_principal_name,
    database_principal_name,
    object_name,
    schema_name,
    statement
FROM fn_get_audit_file('C:\AuditLogs\SecureDB_Audit_*.sqlaudit', DEFAULT, DEFAULT)
WHERE object_name = 'SensitiveData'
   OR statement LIKE '%SensitiveData%'
ORDER BY event_time DESC;
GO

-- ===================================================
-- AUDIT LOGLARINI TABLO OLARAK KAYDETME
-- ===================================================

USE SecureDB;
GO

-- Audit logs tablosu oluştur
IF OBJECT_ID('dbo.AuditLogArchive', 'U') IS NOT NULL
    DROP TABLE dbo.AuditLogArchive;
GO

CREATE TABLE dbo.AuditLogArchive
(
    LogID INT IDENTITY(1,1) PRIMARY KEY,
    EventTime DATETIME2,
    ActionID VARCHAR(4),
    ActionDescription VARCHAR(50),
    Succeeded BIT,
    ServerPrincipalName NVARCHAR(128),
    DatabasePrincipalName NVARCHAR(128),
    ObjectName NVARCHAR(128),
    SchemaName NVARCHAR(128),
    DatabaseName NVARCHAR(128),
    Statement NVARCHAR(4000),
    SessionID INT,
    ArchiveDate DATETIME2 DEFAULT GETDATE()
);
GO

-- Audit loglarını tabloya aktar
INSERT INTO dbo.AuditLogArchive 
(
    EventTime, ActionID, ActionDescription, Succeeded, 
    ServerPrincipalName, DatabasePrincipalName, ObjectName, 
    SchemaName, DatabaseName, Statement, SessionID
)
SELECT 
    event_time,
    action_id,
    CASE action_id
        WHEN 'LGIS' THEN 'LOGIN SUCCESS'
        WHEN 'LGIF' THEN 'LOGIN FAILED'
        WHEN 'LGO' THEN 'LOGOUT'
        WHEN 'SL' THEN 'SELECT'
        WHEN 'IN' THEN 'INSERT'
        WHEN 'UP' THEN 'UPDATE'
        WHEN 'DL' THEN 'DELETE'
        ELSE action_id
    END,
    succeeded,
    server_principal_name,
    database_principal_name,
    object_name,
    schema_name,
    database_name,
    LEFT(statement, 4000),
    session_id
FROM fn_get_audit_file('C:\AuditLogs\SecureDB_Audit_*.sqlaudit', DEFAULT, DEFAULT)
WHERE event_time >= DATEADD(DAY, -7, GETDATE()); -- Son 7 günün logları
GO

-- Arşivlenen log sayısını göster
SELECT 
    COUNT(*) AS TotalArchivedLogs,
    MIN(EventTime) AS OldestLog,
    MAX(EventTime) AS NewestLog
FROM dbo.AuditLogArchive;
GO

-- ===================================================
-- AUDIT LOG İSTATİSTİKLERİ
-- ===================================================

PRINT '=== AUDIT LOG İSTATİSTİKLERİ ===';
GO

-- Eylem türlerine göre dağılım
SELECT 
    ActionDescription,
    COUNT(*) AS EventCount,
    COUNT(CASE WHEN Succeeded = 1 THEN 1 END) AS SuccessCount,
    COUNT(CASE WHEN Succeeded = 0 THEN 1 END) AS FailureCount
FROM dbo.AuditLogArchive
GROUP BY ActionDescription
ORDER BY EventCount DESC;
GO

-- Kullanıcılara göre aktivite
SELECT 
    ISNULL(ServerPrincipalName, 'Unknown') AS Username,
    COUNT(*) AS ActivityCount,
    MIN(EventTime) AS FirstActivity,
    MAX(EventTime) AS LastActivity
FROM dbo.AuditLogArchive
WHERE ServerPrincipalName IS NOT NULL
GROUP BY ServerPrincipalName
ORDER BY ActivityCount DESC;
GO

-- ===================================================
-- AUDIT LOGLARINI CSV DOSYASINA AKTARMA
-- ===================================================

PRINT '=== AUDIT LOGLARI CSV DOSYASINA AKTARILIYOR ===';
GO

-- BCP komutu ile CSV export (SQL Server Agent veya xp_cmdshell gerekir)
-- Aşağıdaki komutu Command Prompt'tan çalıştırın:

PRINT 'CSV export için aşağıdaki BCP komutunu Command Prompt''tan çalıştırın:';
PRINT '';
PRINT 'bcp "SELECT EventTime, ActionDescription, ServerPrincipalName, ObjectName, Statement FROM SecureDB.dbo.AuditLogArchive" queryout "C:\AuditLogs\AuditLogExport.csv" -c -t"," -T -S localhost';
PRINT '';

-- Alternatif: PowerShell ile export
PRINT 'Alternatif PowerShell komutu:';
PRINT 'Invoke-Sqlcmd -Query "SELECT * FROM SecureDB.dbo.AuditLogArchive" -ServerInstance "localhost" | Export-Csv -Path "C:\AuditLogs\AuditLogExport.csv" -NoTypeInformation';
GO

-- ===================================================
-- AUDIT TEMIZLIK VE BAKIMI
-- ===================================================

-- Eski audit loglarını temizleme procedure'u
CREATE OR ALTER PROCEDURE sp_CleanupAuditLogs
    @DaysToKeep INT = 30
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @CutoffDate DATETIME2 = DATEADD(DAY, -@DaysToKeep, GETDATE());
    DECLARE @DeletedRows INT;
    
    DELETE FROM dbo.AuditLogArchive 
    WHERE EventTime < @CutoffDate;
    
    SET @DeletedRows = @@ROWCOUNT;
    
    PRINT CONCAT(@DeletedRows, ' audit log kaydı silindi.');
    PRINT CONCAT('Silinen kayıtlar: ', @CutoffDate, ' tarihinden eski olanlar.');
END
GO

PRINT '=== AUDIT LOG GÖRÜNTÜLEMESİ TAMAMLANDI ===';
PRINT 'Audit logları AuditLogArchive tablosunda saklandı.';
PRINT 'Düzenli temizlik için sp_CleanupAuditLogs procedure''unu kullanın.';
GO 