-- ===================================================
-- SQL Güvenlik ve Erişim Kontrolü Projesi
-- Adım 6: SQL Server Audit Sistemi Kurulumu (Düzeltilmiş)
-- ===================================================

PRINT N'=== SQL SERVER AUDIT KURULUMU BAŞLATILIYOR ===';
SET NOCOUNT ON;
GO

USE master;
GO

-- Audit logları için dizin oluştur (varsa hata vermez)
PRINT N'C:\AuditLogs dizini kontrol ediliyor/oluşturuluyor...';
BEGIN TRY
    EXEC xp_create_subdir N'C:\AuditLogs';
    PRINT N'✓ C:\AuditLogs dizini hazır.';
END TRY
BEGIN CATCH
    PRINT N'Uyarı: C:\AuditLogs dizini oluşturulamadı veya zaten var. ' + ERROR_MESSAGE();
END CATCH
GO

-- Mevcut Server Audit'i (varsa) kaldır
IF EXISTS (SELECT * FROM sys.server_audits WHERE name = N'SecureDB_Audit')
BEGIN
    PRINT N'Mevcut SecureDB_Audit sunucu denetimi devre dışı bırakılıyor...';
    ALTER SERVER AUDIT SecureDB_Audit WITH (STATE = OFF);
    PRINT N'Mevcut SecureDB_Audit sunucu denetimi siliniyor...';
    DROP SERVER AUDIT SecureDB_Audit;
    PRINT N'✓ Eski SecureDB_Audit sunucu denetimi kaldırıldı.';
END
GO

-- Yeni Server Audit oluştur
PRINT N'SecureDB_Audit sunucu denetimi oluşturuluyor...';
CREATE SERVER AUDIT SecureDB_Audit
TO FILE 
(
    FILEPATH = N'C:\AuditLogs\',
    MAXSIZE = 100 MB,
    MAX_ROLLOVER_FILES = 10,
    RESERVE_DISK_SPACE = OFF
)
WITH 
(
    QUEUE_DELAY = 1000,
    ON_FAILURE = CONTINUE -- Hata durumunda SQL Server'ı durdurma
);
PRINT N'✓ SecureDB_Audit sunucu denetimi oluşturuldu.';
GO

-- Server Audit'i aktifleştir
PRINT N'SecureDB_Audit sunucu denetimi aktifleştiriliyor...';
ALTER SERVER AUDIT SecureDB_Audit WITH (STATE = ON);
PRINT N'✓ SecureDB_Audit sunucu denetimi aktifleştirildi.';
GO

-- Mevcut Server Audit Specification'ı (varsa) kaldır
IF EXISTS (SELECT * FROM sys.server_audit_specifications WHERE name = N'SecureDB_Login_Audit_Spec')
BEGIN
    PRINT N'Mevcut SecureDB_Login_Audit_Spec belirtimi devre dışı bırakılıyor...';
    ALTER SERVER AUDIT SPECIFICATION SecureDB_Login_Audit_Spec WITH (STATE = OFF);
    PRINT N'Mevcut SecureDB_Login_Audit_Spec belirtimi siliniyor...';
    DROP SERVER AUDIT SPECIFICATION SecureDB_Login_Audit_Spec;
    PRINT N'✓ Eski SecureDB_Login_Audit_Spec belirtimi kaldırıldı.';
END
GO

-- Server Audit Specification (Login denemeleri için) oluştur
PRINT N'SecureDB_Login_Audit_Spec sunucu denetim belirtimi oluşturuluyor...';
CREATE SERVER AUDIT SPECIFICATION SecureDB_Login_Audit_Spec
FOR SERVER AUDIT SecureDB_Audit
    ADD (FAILED_LOGIN_GROUP),
    ADD (SUCCESSFUL_LOGIN_GROUP),
    ADD (LOGOUT_GROUP); -- LOGOUT_GROUP eklendi
PRINT N'✓ SecureDB_Login_Audit_Spec sunucu denetim belirtimi oluşturuldu.';
GO

-- Server Audit Specification'ı aktifleştir
PRINT N'SecureDB_Login_Audit_Spec belirtimi aktifleştiriliyor...';
ALTER SERVER AUDIT SPECIFICATION SecureDB_Login_Audit_Spec WITH (STATE = ON);
PRINT N'✓ SecureDB_Login_Audit_Spec belirtimi aktifleştirildi.';
GO

USE SecureDB;
GO

-- Mevcut Database Audit Specification'ı (varsa) kaldır
IF EXISTS (SELECT * FROM sys.database_audit_specifications WHERE name = N'SecureDB_DML_Audit_Spec')
BEGIN
    PRINT N'Mevcut SecureDB_DML_Audit_Spec (SecureDB) belirtimi devre dışı bırakılıyor...';
    ALTER DATABASE AUDIT SPECIFICATION SecureDB_DML_Audit_Spec WITH (STATE = OFF);
    PRINT N'Mevcut SecureDB_DML_Audit_Spec (SecureDB) belirtimi siliniyor...';
    DROP DATABASE AUDIT SPECIFICATION SecureDB_DML_Audit_Spec;
    PRINT N'✓ Eski SecureDB_DML_Audit_Spec (SecureDB) belirtimi kaldırıldı.';
END
GO

-- Database Audit Specification (SensitiveData üzerindeki DML işlemleri için) oluştur
PRINT N'SecureDB_DML_Audit_Spec (SecureDB) veritabanı denetim belirtimi oluşturuluyor...';
CREATE DATABASE AUDIT SPECIFICATION SecureDB_DML_Audit_Spec
FOR SERVER AUDIT SecureDB_Audit
    ADD (SELECT, INSERT, UPDATE, DELETE ON OBJECT::dbo.SensitiveData BY public)
WITH (STATE = ON);
PRINT N'✓ SecureDB_DML_Audit_Spec (SecureDB) veritabanı denetim belirtimi oluşturuldu ve aktifleştirildi.';
GO

PRINT N'';
PRINT N'=== AUDIT YAPILANDIRMA KONTROLÜ ===';
-- Sunucu Denetimini Kontrol Et
PRINT N'--- Sunucu Denetimi (SecureDB_Audit) Durumu ---';
SELECT
    sa.name AS AuditName,
    sa.is_state_enabled,
    CASE sa.is_state_enabled WHEN 1 THEN N'ON' WHEN 0 THEN N'OFF' ELSE N'UNKNOWN' END AS AuditStatus,
    sa.type_desc AS AuditType,
    sfn.audit_file_path AS CurrentLogFile
FROM sys.server_audits sa
LEFT JOIN sys.dm_server_audit_status sfn ON sa.audit_id = sfn.audit_id
WHERE sa.name = N'SecureDB_Audit';
GO

-- Sunucu Düzeyi Denetim Belirtimini Kontrol Et
PRINT N'--- Sunucu Düzeyi Denetim Belirtimi (SecureDB_Login_Audit_Spec) Detayları ---';
SELECT
    sas.name AS ServerSpecificationName,
    sads.audit_action_name,
    sas.is_state_enabled AS IsEnabled,
    sa.name AS AuditName
FROM sys.server_audit_specifications sas
JOIN sys.server_audits sa ON sas.audit_guid = sa.audit_guid
LEFT JOIN sys.server_audit_specification_details sads ON sas.server_specification_id = sads.server_specification_id
WHERE sas.name = N'SecureDB_Login_Audit_Spec';
GO

-- Veritabanı Düzeyi Denetim Belirtimini Kontrol Et
PRINT N'--- Veritabanı Düzeyi Denetim Belirtimi (SecureDB_DML_Audit_Spec) Detayları ---';
USE SecureDB;
GO
SELECT
    das.name AS DatabaseSpecificationName,
    dads.audit_action_name,
    dads.class_desc,
    OBJECT_NAME(dads.major_id) AS TargetObject,
    USER_NAME(dads.audited_principal_id) AS TargetPrincipal,
    das.is_state_enabled AS IsEnabled,
    sa.name AS AuditName
FROM sys.database_audit_specifications das
JOIN sys.server_audits sa ON das.audit_guid = sa.audit_guid
LEFT JOIN sys.database_audit_specification_details dads ON das.database_specification_id = dads.database_specification_id
WHERE das.name = N'SecureDB_DML_Audit_Spec';
GO
USE master; -- Ana contexte geri dön
GO

PRINT N'';
PRINT N'=== AUDIT TEST VERİLERİ OLUŞTURULUYOR ===';
USE SecureDB;
GO

BEGIN TRY
    PRINT N'Audit testi için ''Audit System Test User'' ekleniyor (Stored Procedure ile)...';
    EXEC dbo.sp_InsertUserDataSecure_ColumnEnc 
        @FullName = N'Audit System Test User', 
        @CreditCardNumber_Plain = N'9876-5432-1098-7654';
    PRINT N'✓ Audit testi için veri başarıyla eklendi.';

    PRINT N'Audit testi için ''Audit System Test User'' sorgulanıyor...';
    EXEC dbo.sp_GetUserDataSecure_ColumnEnc @FullName = N'Audit System Test User';
    PRINT N'✓ Audit testi için veri başarıyla sorgulandı.';

END TRY
BEGIN CATCH
    PRINT N'HATA: Audit test verisi eklenirken/sorgulanırken sorun oluştu: ' + ERROR_MESSAGE();
END CATCH
GO

PRINT N'Test verileri oluşturuldu/sorgulandı. Audit logları kayıt altına alınmış olmalı.';
PRINT N'=== SQL SERVER AUDIT KURULUMU TAMAMLANDI ===';
PRINT N'Audit dosyaları: C:\AuditLogs\ klasöründe bulunmaktadır.';
PRINT N'Audit loglarını görüntülemek için `07_ViewAuditLogs.sql` scriptini çalıştırabilirsiniz.';
GO 