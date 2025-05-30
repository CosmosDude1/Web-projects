-- ===================================================
-- SQL Güvenlik ve Erişim Kontrolü Projesi
-- Adım 6: SQL Server Audit Aktifleştirme
-- ===================================================

USE master;
GO

-- ===================================================
-- SERVER AUDIT OLUŞTURMA
-- ===================================================

-- Eğer audit mevcutsa kapat ve sil
IF EXISTS (SELECT * FROM sys.server_audits WHERE name = 'SecureDB_Audit')
BEGIN
    ALTER SERVER AUDIT SecureDB_Audit WITH (STATE = OFF);
    DROP SERVER AUDIT SecureDB_Audit;
    PRINT 'Mevcut audit silindi.';
END
GO

-- Audit dizinini oluştur (gerekiyorsa)
EXEC xp_create_subdir 'C:\AuditLogs';
GO

-- Server Audit oluştur
CREATE SERVER AUDIT SecureDB_Audit
TO FILE 
(
    FILEPATH = 'C:\AuditLogs\',
    MAXSIZE = 100 MB,
    MAX_ROLLOVER_FILES = 10,
    RESERVE_DISK_SPACE = OFF
)
WITH 
(
    QUEUE_DELAY = 1000,
    ON_FAILURE = CONTINUE
);
GO

-- Server Audit'i aktifleştir
ALTER SERVER AUDIT SecureDB_Audit WITH (STATE = ON);
GO

PRINT 'Server Audit oluşturuldu ve aktifleştirildi.';
GO

-- ===================================================
-- SERVER AUDIT SPECIFICATION - LOGIN İZLEME
-- ===================================================

-- Login attempts için server audit specification
IF EXISTS (SELECT * FROM sys.server_audit_specifications WHERE name = 'SecureDB_Login_Audit_Spec')
BEGIN
    ALTER SERVER AUDIT SPECIFICATION SecureDB_Login_Audit_Spec WITH (STATE = OFF);
    DROP SERVER AUDIT SPECIFICATION SecureDB_Login_Audit_Spec;
END
GO

CREATE SERVER AUDIT SPECIFICATION SecureDB_Login_Audit_Spec
FOR SERVER AUDIT SecureDB_Audit
ADD (FAILED_LOGIN_GROUP),
ADD (SUCCESSFUL_LOGIN_GROUP),
ADD (LOGOUT_GROUP);
GO

-- Server audit specification'ı aktifleştir
ALTER SERVER AUDIT SPECIFICATION SecureDB_Login_Audit_Spec WITH (STATE = ON);
GO

PRINT 'Login audit specification oluşturuldu ve aktifleştirildi.';
GO

-- ===================================================
-- DATABASE AUDIT SPECIFICATION - SELECT İZLEME
-- ===================================================

USE SecureDB;
GO

-- SensitiveData tablosundaki SELECT işlemleri için database audit specification
IF EXISTS (SELECT * FROM sys.database_audit_specifications WHERE name = 'SecureDB_Select_Audit_Spec')
BEGIN
    ALTER DATABASE AUDIT SPECIFICATION SecureDB_Select_Audit_Spec WITH (STATE = OFF);
    DROP DATABASE AUDIT SPECIFICATION SecureDB_Select_Audit_Spec;
END
GO

CREATE DATABASE AUDIT SPECIFICATION SecureDB_Select_Audit_Spec
FOR SERVER AUDIT SecureDB_Audit
ADD (SELECT ON dbo.SensitiveData BY public),
ADD (INSERT ON dbo.SensitiveData BY public),
ADD (UPDATE ON dbo.SensitiveData BY public),
ADD (DELETE ON dbo.SensitiveData BY public);
GO

-- Database audit specification'ı aktifleştir
ALTER DATABASE AUDIT SPECIFICATION SecureDB_Select_Audit_Spec WITH (STATE = ON);
GO

PRINT 'Database audit specification oluşturuldu ve aktifleştirildi.';
GO

-- ===================================================
-- AUDIT DURUMUNU KONTROL ET
-- ===================================================

-- Server audit durumu
SELECT 
    name AS audit_name,
    type_desc,
    on_failure_desc,
    is_state_enabled,
    queue_delay,
    audit_file_path,
    max_file_size,
    max_rollover_files
FROM sys.server_audits
WHERE name = 'SecureDB_Audit';
GO

-- Server audit specifications
SELECT 
    sas.name AS spec_name,
    sas.is_state_enabled,
    sasmd.audit_action_name,
    sa.name AS audit_name
FROM sys.server_audit_specifications sas
JOIN sys.server_audit_specification_details sasmd ON sas.server_specification_id = sasmd.server_specification_id
JOIN sys.server_audits sa ON sas.audit_id = sa.audit_id
WHERE sa.name = 'SecureDB_Audit';
GO

-- Database audit specifications
SELECT 
    das.name AS spec_name,
    das.is_state_enabled,
    dasd.audit_action_name,
    dasd.object_name,
    sa.name AS audit_name
FROM sys.database_audit_specifications das
JOIN sys.database_audit_specification_details dasd ON das.database_specification_id = dasd.database_specification_id
JOIN sys.server_audits sa ON das.audit_id = sa.audit_id
WHERE sa.name = 'SecureDB_Audit';
GO

-- ===================================================
-- TEST VERİLERİ OLUŞTURMA (AUDIT LOG'LARI İÇİN)
-- ===================================================

PRINT '=== AUDIT TEST VERİLERİ OLUŞTURULUYOR ===';
GO

-- Test sorguları çalıştır (audit logları oluşturmak için)
SELECT COUNT(*) AS TotalRecords FROM dbo.SensitiveData;
GO

SELECT TOP 1 * FROM dbo.SensitiveData WHERE FullName LIKE 'Ahmet%';
GO

-- Test insert
INSERT INTO dbo.SensitiveData (FullName, CreditCardNumber, ExpiryDate, SecurityCode)
VALUES ('Test Audit User', '9999-8888-7777-6666', '2025-01-01', '999');
GO

PRINT 'Test verileri oluşturuldu. Audit logları kayıt altına alındı.';
GO

PRINT '=== SQL SERVER AUDIT KURULUMU TAMAMLANDI ===';
PRINT 'Audit dosyaları: C:\AuditLogs\ klasöründe';
PRINT 'Audit loglarını görüntülemek için 07_ViewAuditLogs.sql scriptini çalıştırın.';
GO 