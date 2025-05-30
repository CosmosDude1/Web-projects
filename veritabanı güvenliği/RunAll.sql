-- ===================================================
-- SQL Güvenlik ve Erişim Kontrolü Projesi - MASTER SCRIPT (Sütun Şifrelemeli)
-- Tüm scriptleri sırasıyla çalıştırır
-- ===================================================

-- Hata durumunda işlemi durdur
SET NOCOUNT ON;
SET XACT_ABORT ON;

PRINT N'===============================================';
PRINT N'SQL GÜVENLİK PROJESİ (SÜTUN ŞİFRELEMELİ) BAŞLATILIYOR...';
PRINT N'Başlangıç Zamanı: ' + CONVERT(VARCHAR(20), GETDATE(), 120);
PRINT N'===============================================';
PRINT N'';

-- Adım 1: Veritabanı Oluşturma
PRINT N'ADIM 1: SecureDB Veritabanı Oluşturuluyor...';
PRINT N'----------------------------------------------';

USE master;
GO

-- Eğer veritabanı mevcutsa sil
IF DB_ID(N'SecureDB') IS NOT NULL
BEGIN
    ALTER DATABASE SecureDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE SecureDB;
    PRINT N'Mevcut SecureDB veritabanı silindi.';
END
GO

-- SecureDB veritabanını oluştur
CREATE DATABASE SecureDB
ON 
(
    NAME = N'SecureDB_Data',
    FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL16.SQLEXPRESS\MSSQL\DATA\SecureDB.mdf',
    SIZE = 100MB,
    MAXSIZE = 1GB,
    FILEGROWTH = 10MB
)
LOG ON 
(
    NAME = N'SecureDB_Log',
    FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL16.SQLEXPRESS\MSSQL\DATA\SecureDB.ldf',
    SIZE = 10MB,
    MAXSIZE = 100MB,
    FILEGROWTH = 5MB
);
GO

PRINT N'✓ SecureDB veritabanı başarıyla oluşturuldu.';
PRINT N'';

-- Adım 2: Kullanıcı Oluşturma
PRINT N'ADIM 2: Kullanıcılar Oluşturuluyor...';
PRINT N'--------------------------------------';

-- SQL Server Authentication kullanıcısı oluştur (User1)
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N'User1')
BEGIN
    CREATE LOGIN User1 
    WITH PASSWORD = N'SecurePassword123!',
         DEFAULT_DATABASE = SecureDB,
         CHECK_EXPIRATION = ON,
         CHECK_POLICY = ON;
    PRINT N'✓ User1 SQL Server Authentication login oluşturuldu.';
END
ELSE
    PRINT N'User1 login zaten mevcut.';

-- Test için local kullanıcı (User2)
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N'User2')
BEGIN
    CREATE LOGIN [User2] 
    WITH PASSWORD = N'WindowsPassword123!',
         DEFAULT_DATABASE = SecureDB;
    PRINT N'✓ User2 login oluşturuldu.';
END
ELSE
    PRINT N'User2 login zaten mevcut.';

-- SecureDB veritabanında kullanıcıları oluştur
USE SecureDB;
GO

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = N'User1')
BEGIN
    CREATE USER User1 FOR LOGIN User1;
    PRINT N'✓ User1 database kullanıcısı oluşturuldu.';
END
ELSE
    PRINT N'User1 database kullanıcısı zaten mevcut.';

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = N'User2')
BEGIN
    CREATE USER User2 FOR LOGIN User2;
    PRINT N'✓ User2 database kullanıcısı oluşturuldu.';
END
ELSE
    PRINT N'User2 database kullanıcısı zaten mevcut.';

PRINT N'';

-- Adım 3: Sütun Şifreleme için Anahtar Kurulumu
PRINT N'ADIM 3: Sütun Düzeyinde Şifreleme için Anahtar Kurulumu...';
PRINT N'---------------------------------------------------------';

-- Veritabanı Ana Anahtarı
IF NOT EXISTS (SELECT * FROM sys.symmetric_keys WHERE name = N'##MS_DatabaseMasterKey##') -- Master key DB contextinde kontrol edilir.
BEGIN
    PRINT N'SecureDB için Veritabanı Ana Anahtarı oluşturuluyor...';
    CREATE MASTER KEY ENCRYPTION BY PASSWORD = N'ColumnMasterKeyP@sswOrd1!';
    PRINT N'✓ SecureDB için Veritabanı Ana Anahtarı oluşturuldu.';
END
ELSE
    PRINT N'SecureDB Veritabanı Ana Anahtarı zaten mevcut.';
GO

-- Sütun Şifrelemesi için Certificate
IF NOT EXISTS (SELECT * FROM sys.certificates WHERE name = N'SecureDB_ColumnEncryption_Cert')
BEGIN
    PRINT N'Sütun şifrelemesi için sertifika (SecureDB_ColumnEncryption_Cert) oluşturuluyor...';
    CREATE CERTIFICATE SecureDB_ColumnEncryption_Cert
    WITH SUBJECT = N'SecureDB Column Encryption Certificate',
         EXPIRY_DATE = N'2035-12-31';
    PRINT N'✓ SecureDB_ColumnEncryption_Cert sertifikası oluşturuldu.';
END
ELSE
    PRINT N'SecureDB_ColumnEncryption_Cert sertifikası zaten mevcut.';
GO

-- Certificate Yedekleme
BEGIN TRY
    PRINT N'SecureDB_ColumnEncryption_Cert sertifikası yedekleniyor...';
    BACKUP CERTIFICATE SecureDB_ColumnEncryption_Cert
    TO FILE = N'C:\Temp\SecureDB_ColumnEncryption_Cert.cer'
    WITH PRIVATE KEY 
    (
        FILE = N'C:\Temp\SecureDB_ColumnEncryption_Cert.pvk',
        ENCRYPTION BY PASSWORD = N'CertBackupP@sswOrd1!'
    );
    PRINT N'✓ SecureDB_ColumnEncryption_Cert başarıyla yedeklendi.';
END TRY
BEGIN CATCH
    PRINT N'HATA: SecureDB_ColumnEncryption_Cert yedeklenemedi. ' + ERROR_MESSAGE();
    PRINT N'Lütfen C:\Temp dizininin var olduğundan ve SQL Server servis hesabının yazma izni olduğundan emin olun.';
END CATCH
GO

-- Sütun Şifrelemesi için Symmetric Key
IF NOT EXISTS (SELECT * FROM sys.symmetric_keys WHERE name = N'SecureColumnSymmetricKey')
BEGIN
    PRINT N'Simetrik anahtar (SecureColumnSymmetricKey) oluşturuluyor...';
    CREATE SYMMETRIC KEY SecureColumnSymmetricKey
    WITH ALGORITHM = AES_256
    ENCRYPTION BY CERTIFICATE SecureDB_ColumnEncryption_Cert;
    PRINT N'✓ SecureColumnSymmetricKey, SecureDB_ColumnEncryption_Cert ile şifrelenerek oluşturuldu.';
END
ELSE
    PRINT N'SecureColumnSymmetricKey simetrik anahtarı zaten mevcut.';
GO
PRINT N'';

-- Adım 4: Tablo Oluşturma ve Şifreli Veri Ekleme
PRINT N'ADIM 4: SensitiveData Tablosu ve Şifreli Veri Ekleme...';
PRINT N'-------------------------------------------------------';

-- SensitiveData tablosunu oluştur
IF OBJECT_ID(N'dbo.SensitiveData', N'U') IS NOT NULL
    DROP TABLE dbo.SensitiveData;
GO
CREATE TABLE dbo.SensitiveData
(
    ID INT IDENTITY(1,1) PRIMARY KEY,
    FullName NVARCHAR(100) NOT NULL,
    CreditCardNumber VARBINARY(256) NULL,
    ExpiryDate DATE,
    SecurityCode NVARCHAR(4),
    CreatedDate DATETIME2 DEFAULT GETDATE(),
    CreatedBy NVARCHAR(50) DEFAULT SUSER_NAME()
);
PRINT N'✓ SensitiveData tablosu (CreditCardNumber VARBINARY) oluşturuldu.';

-- Simetrik anahtarı aç
BEGIN TRY
    PRINT N'Veri ekleme için SecureColumnSymmetricKey açılıyor...';
    OPEN SYMMETRIC KEY SecureColumnSymmetricKey
    DECRYPTION BY CERTIFICATE SecureDB_ColumnEncryption_Cert;
    PRINT N'✓ SecureColumnSymmetricKey başarıyla açıldı.';

    -- Örnek hassas veri ekle (CreditCardNumber şifrelenerek)
    PRINT N'Örnek şifreli veriler ekleniyor...';
    INSERT INTO dbo.SensitiveData (FullName, CreditCardNumber, ExpiryDate, SecurityCode)
    VALUES 
        (N'Ahmet Yılmaz', EncryptByKey(Key_GUID(N'SecureColumnSymmetricKey'), N'4532-1234-5678-9012'), N'2025-12-31', N'123'),
        (N'Ayşe Demir', EncryptByKey(Key_GUID(N'SecureColumnSymmetricKey'), N'5555-4444-3333-2222'), N'2026-06-30', N'456'),
        (N'Mehmet Kaya', EncryptByKey(Key_GUID(N'SecureColumnSymmetricKey'), N'4111-1111-1111-1111'), N'2025-08-15', N'789');
    PRINT N'✓ Örnek şifreli veriler başarıyla eklendi.';
    
    CLOSE SYMMETRIC KEY SecureColumnSymmetricKey; -- İşlem sonrası anahtarı kapat
    PRINT N'✓ SecureColumnSymmetricKey kapatıldı.';
END TRY
BEGIN CATCH
    PRINT N'HATA: Şifreli veri eklenemedi veya anahtar yönetimi hatası. ' + ERROR_MESSAGE();
    IF EXISTS(SELECT * FROM sys.openkeys WHERE key_name = 'SecureColumnSymmetricKey')
        CLOSE SYMMETRIC KEY SecureColumnSymmetricKey; -- Hata durumunda da kapatmayı dene
END CATCH
GO

-- Kullanıcı izinleri
GRANT SELECT, INSERT ON dbo.SensitiveData TO User1;
GRANT SELECT ON dbo.SensitiveData TO User2;
PRINT N'✓ Kullanıcı izinleri ayarlandı.';
PRINT N'';

-- Adım 5: Audit Sistemi
PRINT N'ADIM 5: SQL Server Audit Sistemi...';
PRINT N'------------------------------------';

USE master;
GO

-- Audit dizinini oluştur
EXEC xp_create_subdir N'C:\AuditLogs';

-- Eğer audit mevcutsa kapat ve sil
IF EXISTS (SELECT * FROM sys.server_audits WHERE name = N'SecureDB_Audit')
BEGIN
    ALTER SERVER AUDIT SecureDB_Audit WITH (STATE = OFF);
    DROP SERVER AUDIT SecureDB_Audit;
END

-- Server Audit oluştur
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
    ON_FAILURE = CONTINUE
);

-- Server Audit'i aktifleştir
ALTER SERVER AUDIT SecureDB_Audit WITH (STATE = ON);
PRINT N'✓ Server Audit oluşturuldu ve aktifleştirildi.';

-- Login audit specification
IF EXISTS (SELECT * FROM sys.server_audit_specifications WHERE name = N'SecureDB_Login_Audit_Spec')
BEGIN
    ALTER SERVER AUDIT SPECIFICATION SecureDB_Login_Audit_Spec WITH (STATE = OFF);
    DROP SERVER AUDIT SPECIFICATION SecureDB_Login_Audit_Spec;
END

CREATE SERVER AUDIT SPECIFICATION SecureDB_Login_Audit_Spec
FOR SERVER AUDIT SecureDB_Audit
ADD (FAILED_LOGIN_GROUP),
ADD (SUCCESSFUL_LOGIN_GROUP),
ADD (LOGOUT_GROUP);

ALTER SERVER AUDIT SPECIFICATION SecureDB_Login_Audit_Spec WITH (STATE = ON);
PRINT N'✓ Login audit specification aktifleştirildi.';

-- Database audit specification
USE SecureDB;
GO

IF EXISTS (SELECT * FROM sys.database_audit_specifications WHERE name = N'SecureDB_DML_Audit_Spec')
BEGIN
    ALTER DATABASE AUDIT SPECIFICATION SecureDB_DML_Audit_Spec WITH (STATE = OFF);
    DROP DATABASE AUDIT SPECIFICATION SecureDB_DML_Audit_Spec;
END

CREATE DATABASE AUDIT SPECIFICATION SecureDB_DML_Audit_Spec
FOR SERVER AUDIT SecureDB_Audit
ADD (SELECT, INSERT, UPDATE, DELETE ON dbo.SensitiveData BY public);

ALTER DATABASE AUDIT SPECIFICATION SecureDB_DML_Audit_Spec WITH (STATE = ON);
PRINT N'✓ Database DML audit specification aktifleştirildi.';
PRINT N'';

-- Adım 6: Güvenlik Prosedürleri (Sütun Şifrelemeli)
PRINT N'ADIM 6: Güvenlik Prosedürleri (Sütun Şifrelemeli) Oluşturuluyor...';
PRINT N'-----------------------------------------------------------------';

CREATE OR ALTER PROCEDURE sp_GetUserDataSecure_ColumnEnc
    @FullName NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    OPEN SYMMETRIC KEY SecureColumnSymmetricKey DECRYPTION BY CERTIFICATE SecureDB_ColumnEncryption_Cert;
    SELECT ID, FullName, CONVERT(NVARCHAR(100), DecryptByKey(CreditCardNumber)) AS Decrypted_CreditCardNumber, ExpiryDate, CreatedDate
    FROM SensitiveData WHERE FullName = @FullName;
    CLOSE SYMMETRIC KEY SecureColumnSymmetricKey;
END
GO
PRINT N'✓ sp_GetUserDataSecure_ColumnEnc oluşturuldu.';

CREATE OR ALTER PROCEDURE sp_InsertUserDataSecure_ColumnEnc
    @FullName NVARCHAR(100),
    @CreditCardNumber_Plain NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    IF @FullName IS NULL OR LEN(LTRIM(RTRIM(@FullName))) = 0 BEGIN RAISERROR(N'Ad Soyad boş olamaz.', 16, 1); RETURN; END
    IF @CreditCardNumber_Plain IS NULL OR LEN(REPLACE(@CreditCardNumber_Plain, N'-', N'')) NOT BETWEEN 13 AND 19 BEGIN RAISERROR(N'Geçersiz kredi kartı formatı.', 16, 1); RETURN; END
    
    OPEN SYMMETRIC KEY SecureColumnSymmetricKey DECRYPTION BY CERTIFICATE SecureDB_ColumnEncryption_Cert;
    DECLARE @EncryptedCreditCard VARBINARY(256) = EncryptByKey(Key_GUID(N'SecureColumnSymmetricKey'), @CreditCardNumber_Plain);
    INSERT INTO SensitiveData (FullName, CreditCardNumber) VALUES (@FullName, @EncryptedCreditCard);
    CLOSE SYMMETRIC KEY SecureColumnSymmetricKey;
    PRINT N'Veri (şifrelenerek) eklendi: ' + @FullName;
END
GO
PRINT N'✓ sp_InsertUserDataSecure_ColumnEnc oluşturuldu.';
PRINT N'';

-- Adım 7: Test Verileri ve Final Kontroller
PRINT N'ADIM 7: Test Verileri ve Final Kontroller...';
PRINT N'--------------------------------------------';

-- Test sorguları çalıştır (audit logları oluşturmak için)
SELECT COUNT(*) AS TotalRecords FROM dbo.SensitiveData;
EXEC sp_InsertUserDataSecure_ColumnEnc @FullName = N'Audit Test User', @CreditCardNumber_Plain = N'0000-1111-2222-3333';
GO

PRINT N'✓ Test verileri oluşturuldu.';

-- Güvenlik durumu kontrolü
DECLARE @SecurityScore INT = 0;
DECLARE @ColumnEncryptionPoints INT = 0;
DECLARE @ColumnEncryptionNote NVARCHAR(200) = N'';

-- Sütun Şifreleme Kontrolü
IF EXISTS(SELECT * FROM sys.symmetric_keys WHERE name = N'SecureColumnSymmetricKey') AND 
   EXISTS(SELECT * FROM sys.certificates WHERE name = N'SecureDB_ColumnEncryption_Cert')
BEGIN
    SET @ColumnEncryptionPoints = 25;
END
ELSE
BEGIN
    SET @ColumnEncryptionNote = N' (Uyarı: Sütun şifreleme anahtarları/sertifikası eksik!)';
END
SET @SecurityScore = @SecurityScore + @ColumnEncryptionPoints;

-- Audit kontrol
DECLARE @AuditPoints INT = 0;
IF EXISTS (SELECT * FROM sys.server_audits WHERE name = N'SecureDB_Audit' AND is_state_enabled = 1) AND
   EXISTS (SELECT * FROM sys.server_audit_specifications WHERE name = N'SecureDB_Login_Audit_Spec' AND is_state_enabled = 1) AND
   EXISTS (SELECT das.name FROM sys.database_audit_specifications das JOIN sys.server_audits sa ON das.audit_guid = sa.audit_guid WHERE das.name = N'SecureDB_DML_Audit_Spec' AND das.is_state_enabled = 1 AND sa.name = N'SecureDB_Audit')
BEGIN
    SET @AuditPoints = 25;
END
SET @SecurityScore = @SecurityScore + @AuditPoints;

-- Kullanıcı izinleri kontrol
DECLARE @PermissionsPoints INT = 0;
IF (SELECT COUNT(*) FROM sys.database_permissions p 
    JOIN sys.database_principals pr ON p.grantee_principal_id = pr.principal_id 
    WHERE pr.name IN (N'User1', N'User2') AND p.permission_name IN (N'CONTROL', N'ALTER', N'CREATE TABLE', N'CREATE DATABASE', N'ALTER ANY DATABASE')) = 0 AND
    EXISTS (SELECT 1 FROM sys.database_permissions p JOIN sys.database_principals pr ON p.grantee_principal_id = pr.principal_id WHERE pr.name = N'User1' AND p.permission_name = N'INSERT' AND OBJECT_NAME(p.major_id) = N'SensitiveData') AND
    EXISTS (SELECT 1 FROM sys.database_permissions p JOIN sys.database_principals pr ON p.grantee_principal_id = pr.principal_id WHERE pr.name = N'User1' AND p.permission_name = N'SELECT' AND OBJECT_NAME(p.major_id) = N'SensitiveData') AND
    EXISTS (SELECT 1 FROM sys.database_permissions p JOIN sys.database_principals pr ON p.grantee_principal_id = pr.principal_id WHERE pr.name = N'User2' AND p.permission_name = N'SELECT' AND OBJECT_NAME(p.major_id) = N'SensitiveData')
BEGIN
    SET @PermissionsPoints = 25;
END
SET @SecurityScore = @SecurityScore + @PermissionsPoints;

-- Stored procedures kontrol
DECLARE @StoredProcPoints INT = 0;
IF EXISTS (SELECT * FROM sys.procedures WHERE name LIKE N'sp_GetUserDataSecure_ColumnEnc') AND
   EXISTS (SELECT * FROM sys.procedures WHERE name LIKE N'sp_InsertUserDataSecure_ColumnEnc')
BEGIN
    SET @StoredProcPoints = 25;
END
SET @SecurityScore = @SecurityScore + @StoredProcPoints;

PRINT N'';
PRINT N'===============================================';
PRINT N'SQL GÜVENLİK PROJESİ (Sütun Şifrelemeli) TAMAMLANDI!';
PRINT N'Bitiş Zamanı: ' + CONVERT(VARCHAR(20), GETDATE(), 120);
PRINT N'';
PRINT N'KURULUM ÖZETİ:';
PRINT N'✓ SecureDB veritabanı oluşturuldu';
PRINT N'✓ User1 ve User2 kullanıcıları oluşturuldu';
PRINT N'✓ Sütun şifreleme için anahtarlar ve sertifika kuruldu' + @ColumnEncryptionNote;
PRINT N'✓ SensitiveData tablosu (CreditCardNumber şifreli) ve izinler ayarlandı';
PRINT N'✓ SQL Server Audit sistemi kuruldu (Login & DML izleme)';
PRINT N'✓ Güvenli Stored Procedure'ler (şifreleme/deşifreleme destekli) oluşturuldu';
PRINT N'✓ Test verileri eklendi';
PRINT N'';
PRINT N'GÜVENLİK SKORU: ' + CAST(@SecurityScore AS VARCHAR(10)) + N'/100';
IF @SecurityScore = 100
    PRINT N'DURUM: MÜKEMMEDİ ✓';
ELSE IF @SecurityScore >= 75
    PRINT N'DURUM: İYİ ✓';
ELSE
    PRINT N'DURUM: İYİLEŞTİRME GEREKLİ ⚠️ (' + CAST(100-@SecurityScore AS VARCHAR(10)) + N' puan eksik)';
PRINT N'';
PRINT N'SONRAKI ADIMLAR:';
PRINT N'1. 07_ViewAuditLogs.sql ile audit loglarını inceleyin';
PRINT N'2. 08_SecurityTests.sql ile güvenlik testlerini çalıştırın (Sütun şifrelemesi için güncellenecek)';
PRINT N'3. SecureDB_ColumnEncryption_Cert sertifika yedeğini güvenli bir yerde saklayın.';
PRINT N'4. Audit log monitoring ve düzenli bakım ayarlayın.';
PRINT N'===============================================';
GO 