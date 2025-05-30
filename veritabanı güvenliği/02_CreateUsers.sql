-- ===================================================
-- SQL Güvenlik ve Erişim Kontrolü Projesi
-- Adım 2: Kullanıcı Oluşturma ve Kimlik Doğrulama
-- ===================================================

USE master;
GO

-- SQL Server Authentication kullanıcısı oluştur (User1)
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = 'User1')
BEGIN
    CREATE LOGIN User1 
    WITH PASSWORD = 'SecurePassword123!',
         DEFAULT_DATABASE = SecureDB,
         CHECK_EXPIRATION = ON,
         CHECK_POLICY = ON;
    PRINT 'User1 SQL Server Authentication login oluşturuldu.';
END
GO

-- Windows Authentication kullanıcısı oluştur (User2)
-- Not: Bu kullanıcı Windows sisteminde mevcut olmalıdır
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = 'DOMAIN\User2')
BEGIN
    -- Gerçek Windows kullanıcısı için aşağıdaki satırı uncomment edin
    -- CREATE LOGIN [DOMAIN\User2] FROM WINDOWS;
    
    -- Test için local Windows kullanıcısı
    CREATE LOGIN [User2] 
    WITH PASSWORD = 'WindowsPassword123!',
         DEFAULT_DATABASE = SecureDB;
    PRINT 'User2 Windows Authentication login oluşturuldu.';
END
GO

-- SecureDB veritabanında kullanıcıları oluştur
USE SecureDB;
GO

-- User1 için database user oluştur
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'User1')
BEGIN
    CREATE USER User1 FOR LOGIN User1;
    PRINT 'User1 database kullanıcısı oluşturuldu.';
END
GO

-- User2 için database user oluştur
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'User2')
BEGIN
    CREATE USER User2 FOR LOGIN User2;
    PRINT 'User2 database kullanıcısı oluşturuldu.';
END
GO

-- Kullanıcı rollerini göster
SELECT 
    dp.name AS principal_name,
    dp.type_desc AS principal_type,
    sp.name AS login_name,
    sp.type_desc AS login_type
FROM sys.database_principals dp
LEFT JOIN sys.server_principals sp ON dp.sid = sp.sid
WHERE dp.name IN ('User1', 'User2');
GO 

-- ===================================================
-- KULLANICI YETKİLERİ
-- ===================================================
PRINT N'Kullanıcı yetkileri ayarlanıyor...';

-- User1'e Stored Procedure'leri çalıştırma yetkisi ver
-- Bu, User1'in verileri deşifre etmesini ve şifreli veri eklemesini sağlar
GRANT EXECUTE ON OBJECT::dbo.sp_GetUserDataSecure_ColumnEnc TO User1;
GRANT EXECUTE ON OBJECT::dbo.sp_InsertUserDataSecure_ColumnEnc TO User1;
PRINT N'User1 için sp_GetUserDataSecure_ColumnEnc ve sp_InsertUserDataSecure_ColumnEnc üzerinde EXECUTE yetkisi verildi.';

-- User1'in doğrudan SensitiveData tablosuna SELECT, INSERT, UPDATE, DELETE yetkisi OLMAMALI.
-- Bu, en az yetki prensibine aykırıdır ve SP'lerin amacını bozar.
-- Eğer varsa, bu yetkileri kaldır:
IF EXISTS (
    SELECT 1
    FROM sys.database_permissions dp
    JOIN sys.database_principals u ON dp.grantee_principal_id = u.principal_id
    WHERE u.name = 'User1' AND dp.major_id = OBJECT_ID('dbo.SensitiveData') AND dp.permission_name IN ('SELECT', 'INSERT', 'UPDATE', 'DELETE')
)
BEGIN
    REVOKE SELECT ON OBJECT::dbo.SensitiveData FROM User1;
    REVOKE INSERT ON OBJECT::dbo.SensitiveData FROM User1;
    REVOKE UPDATE ON OBJECT::dbo.SensitiveData FROM User1;
    REVOKE DELETE ON OBJECT::dbo.SensitiveData FROM User1;
    PRINT N'User1''in SensitiveData tablosu üzerindeki doğrudan SELECT, INSERT, UPDATE, DELETE yetkileri (varsa) kaldırıldı.';
END

-- User2'ye sadece SensitiveData tablosunda SELECT yetkisi ver (şifreli veriyi görebilir)
GRANT SELECT ON OBJECT::dbo.SensitiveData TO User2;
PRINT N'User2 için SensitiveData tablosunda SELECT yetkisi verildi.';

-- User2'nin Stored Procedure'leri çalıştırma yetkisi OLMAMALI.
IF EXISTS (
    SELECT 1
    FROM sys.database_permissions dp
    JOIN sys.database_principals u ON dp.grantee_principal_id = u.principal_id
    WHERE u.name = 'User2' AND dp.major_id IN (OBJECT_ID('dbo.sp_GetUserDataSecure_ColumnEnc'), OBJECT_ID('dbo.sp_InsertUserDataSecure_ColumnEnc')) AND dp.permission_name = 'EXECUTE'
)
BEGIN
    REVOKE EXECUTE ON OBJECT::dbo.sp_GetUserDataSecure_ColumnEnc FROM User2;
    REVOKE EXECUTE ON OBJECT::dbo.sp_InsertUserDataSecure_ColumnEnc FROM User2;
    PRINT N'User2''nin sp_GetUserDataSecure_ColumnEnc ve sp_InsertUserDataSecure_ColumnEnc üzerindeki EXECUTE yetkileri (varsa) kaldırıldı.';
END
GO

PRINT N'Kullanıcı yetkileri başarıyla ayarlandı.';
GO 