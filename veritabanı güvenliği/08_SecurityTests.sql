-- ===================================================
-- SQL Güvenlik ve Erişim Kontrolü Projesi
-- Adım 8: Güvenlik Testleri ve Yetki Kontrolü (Sütun Şifrelemeli)
-- ===================================================

USE SecureDB;
GO

-- -- !!! GEÇİCİ - SADECE TEST İÇİN !!!
-- -- Normalde bu yetkiler 02_CreateLoginsAndUsers.sql içinde verilmeli.
-- PRINT N'--- GEÇİCİ: User1 için SP EXECUTE yetkileri veriliyor (TEST AMAÇLI) ---';
-- GRANT EXECUTE ON OBJECT::dbo.sp_GetUserDataSecure_ColumnEnc TO User1;
-- GRANT EXECUTE ON OBJECT::dbo.sp_InsertUserDataSecure_ColumnEnc TO User1;
-- GO

-- ===================================================
-- USER1 YETKİ TESTLERİ (SQL AUTHENTICATION)
-- ===================================================

PRINT N'=== USER1 YETKİ TESTLERİ BAŞLANIYOR ===';
GO

-- User1 olarak bağlan
EXECUTE AS USER = 'User1';
GO

PRINT N'Şu anda bağlı kullanıcı: ' + USER_NAME();
GO

-- User1'in SELECT yetkisini test et (Şifreli veriyi doğrudan OKUYAMAMALI)
PRINT N'--- User1 SELECT yetkisi testi (Şifreli Veri - BAŞARISIZ OLMALI) ---';
BEGIN TRY
    SELECT TOP 1 ID, FullName, CreditCardNumber AS Encrypted_CC FROM dbo.SensitiveData;
    -- Eğer buraya ulaşırsa, User1'in SELECT izni var demektir, bu BEKLENMEDİK bir durum.
    PRINT N'User1 SELECT işlemi (şifreli veri) BAŞARILI (BEKLENMEDİK! User1''in doğrudan SELECT izni olmamalıydı).';
END TRY
BEGIN CATCH
    -- SELECT izni olmadığı için CATCH bloğuna düşmesi BEKLENEN durumdur.
    PRINT N'User1 SELECT işlemi (şifreli veri) BAŞARISIZ (BEKLENEN): ' + ERROR_MESSAGE();
END CATCH
GO

-- User1'in Stored Procedure ile deşifreli veri okuma yetkisi (Eğer SP'ye EXECUTE izni varsa)
-- User1'in normalde simetrik anahtarı açma yetkisi OLMAMALI. Bu test SP üzerinden yapılır.
PRINT N'--- User1 SELECT yetkisi testi (Deşifreli Veri - Stored Procedure ile) ---';
BEGIN TRY
    -- User1'e sp_GetUserDataSecure_ColumnEnc üzerinde EXECUTE izni zaten 02_CreateLoginsAndUsers.sql dosyasında verilmeliydi.
    -- EXECUTE AS CALLER; -- Ana contexte dön -- Bu satırlar kaldırıldı
    -- GRANT EXECUTE ON OBJECT::sp_GetUserDataSecure_ColumnEnc TO User1; -- Bu satırlar kaldırıldı
    -- EXECUTE AS USER = 'User1'; -- User1 contextine geri dön -- Bu satırlar kaldırıldı

    EXEC sp_GetUserDataSecure_ColumnEnc @FullName = N'Ahmet Yılmaz';
    PRINT N'User1 SELECT işlemi (deşifreli veri - SP ile) BAŞARILI';
END TRY
BEGIN CATCH
    PRINT N'User1 SELECT işlemi (deşifreli veri - SP ile) BAŞARISIZ: ' + ERROR_MESSAGE();
END CATCH
GO

-- User1'in INSERT yetkisini test et (Stored Procedure ile şifreleyerek)
PRINT N'--- User1 INSERT yetkisi testi (Stored Procedure ile) ---';
BEGIN TRY
    -- User1'e sp_InsertUserDataSecure_ColumnEnc üzerinde EXECUTE izni zaten 02_CreateLoginsAndUsers.sql dosyasında verilmeliydi.
    -- EXECUTE AS CALLER; -- Ana contexte dön -- Bu satırlar kaldırıldı
    -- GRANT EXECUTE ON OBJECT::sp_InsertUserDataSecure_ColumnEnc TO User1; -- Bu satırlar kaldırıldı
    -- EXECUTE AS USER = 'User1'; -- User1 contextine geri dön -- Bu satırlar kaldırıldı

    EXEC sp_InsertUserDataSecure_ColumnEnc @FullName = N'User1 SP Test', @CreditCardNumber_Plain = N'1111-0000-1111-0000';
    PRINT N'User1 INSERT işlemi (SP ile) BAŞARILI';
END TRY
BEGIN CATCH
    PRINT N'User1 INSERT işlemi (SP ile) BAŞARISIZ: ' + ERROR_MESSAGE();
END CATCH
GO

-- User1 context'inden çık
REVERT;
GO
PRINT N'Şu anda bağlı kullanıcı (REVERT sonrası): ' + USER_NAME();
GO

-- ===================================================
-- USER2 YETKİ TESTLERİ (SIMULATED WINDOWS AUTH)
-- ===================================================

PRINT N'=== USER2 YETKİ TESTLERİ BAŞLANIYOR ===';
GO

REVERT; -- Önceki context'ten çıkıldığından emin ol
EXECUTE AS USER = 'User2';
GO

PRINT N'Şu anda bağlı kullanıcı: ' + USER_NAME();
GO

-- User2'nin SELECT yetkisini test et (Şifreli veriyi okuyabilmeli ama deşifre edememeli)
PRINT N'--- User2 SELECT yetkisi testi (Şifreli Veri) ---';
BEGIN TRY
    SELECT TOP 1 ID, FullName, CreditCardNumber AS Encrypted_CC FROM dbo.SensitiveData;
    PRINT N'User2 SELECT işlemi (şifreli veri) BAŞARILI';
END TRY
BEGIN CATCH
    PRINT N'User2 SELECT işlemi (şifreli veri) BAŞARISIZ: ' + ERROR_MESSAGE();
END CATCH
GO

-- User2'nin Stored Procedure ile deşifreli veri okuma denemesi (Yetkisi olmamalı)
PRINT N'--- User2 SELECT yetkisi testi (Deşifreli Veri - Stored Procedure ile - BAŞARISIZ OLMALI) ---';
BEGIN TRY
    EXEC sp_GetUserDataSecure_ColumnEnc @FullName = N'Ahmet Yılmaz';
    PRINT N'User2 SELECT işlemi (deşifreli veri - SP ile) BAŞARILI (BEKLENMEDİK! User2''nin SP''ye EXECUTE izni olmamalıydı veya SP anahtarı açamamalıydı).';
END TRY
BEGIN CATCH
    PRINT N'User2 SELECT işlemi (deşifreli veri - SP ile) BAŞARISIZ (BEKLENEN): ' + ERROR_MESSAGE();
END CATCH
GO

REVERT;
GO
PRINT N'Şu anda bağlı kullanıcı (REVERT sonrası): ' + USER_NAME();
GO

-- ===================================================
-- SÜTUN ŞİFRELEME KONTROLLERİ
-- ===================================================
PRINT N'=== SÜTUN ŞİFRELEME KONTROLLERİ ===';
GO

-- Anahtarların ve sertifikanın varlığını kontrol et
IF EXISTS(SELECT * FROM sys.symmetric_keys WHERE name = N'SecureColumnSymmetricKey')
    PRINT N'✓ Simetrik anahtar (SecureColumnSymmetricKey) mevcut.';
ELSE
    PRINT N'✗ HATA: Simetrik anahtar (SecureColumnSymmetricKey) bulunamadı!';
GO

IF EXISTS(SELECT * FROM sys.certificates WHERE name = N'SecureDB_ColumnEncryption_Cert')
    PRINT N'✓ Şifreleme sertifikası (SecureDB_ColumnEncryption_Cert) mevcut.';
ELSE
    PRINT N'✗ HATA: Şifreleme sertifikası (SecureDB_ColumnEncryption_Cert) bulunamadı!';
GO

-- Verinin gerçekten şifreli olup olmadığını kontrol et (birkaç kayıt)
PRINT N'--- Şifreli Veri Örneği (CreditCardNumber) ---';
SELECT TOP 3 FullName, CreditCardNumber FROM dbo.SensitiveData;
GO

-- Yetkili bir kullanıcı (veya dbo) olarak veriyi deşifre etmeyi dene
PRINT N'--- Deşifre Edilmiş Veri Örneği (dbo yetkisiyle) ---';
BEGIN TRY
    REVERT; -- dbo veya yüksek yetkili bağlama dön
    OPEN SYMMETRIC KEY SecureColumnSymmetricKey DECRYPTION BY CERTIFICATE SecureDB_ColumnEncryption_Cert;
    SELECT TOP 3 FullName, CONVERT(NVARCHAR(100), DecryptByKey(CreditCardNumber)) AS Decrypted_CC FROM dbo.SensitiveData;
    CLOSE SYMMETRIC KEY SecureColumnSymmetricKey;
    PRINT N'✓ Veri deşifre etme (dbo) BAŞARILI.';
END TRY
BEGIN CATCH
    PRINT N'✗ HATA: Veri deşifre etme (dbo) BAŞARISIZ: ' + ERROR_MESSAGE();
    IF EXISTS(SELECT * FROM sys.openkeys WHERE key_name = 'SecureColumnSymmetricKey')
        CLOSE SYMMETRIC KEY SecureColumnSymmetricKey;
END CATCH
GO

-- ===================================================
-- FİNAL GÜVENLİK SKORU (Sütun Şifreleme Odaklı)
-- ===================================================

PRINT N'=== GÜVENLİK SKORU HESAPLANIYOR (Sütun Şifreleme) ===';
GO

DECLARE @SecurityScore_ColEnc INT = 0;
DECLARE @MaxScore_ColEnc INT = 100;

-- Sütun Şifreleme Anahtarları ve Sertifika Kontrolü (25 Puan)
IF EXISTS(SELECT * FROM sys.symmetric_keys WHERE name = N'SecureColumnSymmetricKey') AND 
   EXISTS(SELECT * FROM sys.certificates WHERE name = N'SecureDB_ColumnEncryption_Cert') -- AND
   --EXISTS(SELECT * FROM sys.database_master_keys) -- DMK varlığını da kontrol et -- Bu satır kaldırıldı
BEGIN
    SET @SecurityScore_ColEnc = @SecurityScore_ColEnc + 25;
    PRINT N'✓ Sütun Şifreleme Altyapısı (Sertifika, Simetrik Anahtar) mevcut (+25 puan)';
END
ELSE
    PRINT N'✗ Sütun Şifreleme Altyapısı eksik (0 puan)';

-- Audit aktif mi? (25 Puan)
IF EXISTS (SELECT * FROM sys.server_audits WHERE name = N'SecureDB_Audit' AND is_state_enabled = 1) AND
   EXISTS (SELECT * FROM sys.server_audit_specifications WHERE name = N'SecureDB_Login_Audit_Spec' AND is_state_enabled = 1) AND
   EXISTS (SELECT das.name FROM sys.database_audit_specifications das JOIN sys.server_audits sa ON das.audit_guid = sa.audit_guid WHERE das.name = N'SecureDB_DML_Audit_Spec' AND das.is_state_enabled = 1 AND sa.name = N'SecureDB_Audit')
BEGIN
    SET @SecurityScore_ColEnc = @SecurityScore_ColEnc + 25;
    PRINT N'✓ Audit aktif (Login & DML) (+25 puan)';
END
ELSE
    PRINT N'✗ Audit aktif değil veya eksik (0 puan)';

-- Kullanıcı izinleri minimal mi? (25 Puan)
-- User1: Sadece SP'ler üzerinden INSERT/SELECT (deşifreli)
-- User2: Sadece SELECT (şifreli)
IF (SELECT COUNT(*) FROM sys.database_permissions p 
    JOIN sys.database_principals pr ON p.grantee_principal_id = pr.principal_id 
    WHERE pr.name IN (N'User1', N'User2') AND 
          (p.permission_name IN (N'CONTROL', N'ALTER', N'CREATE TABLE') OR 
           (pr.name = N'User1' AND p.permission_name = N'SELECT' AND OBJECT_NAME(p.major_id) = N'SensitiveData' AND p.state_desc = 'GRANT') OR -- User1 doğrudan tablo SELECT yetkisi olmamalı
           (pr.name = N'User1' AND p.permission_name = N'INSERT' AND OBJECT_NAME(p.major_id) = N'SensitiveData' AND p.state_desc = 'GRANT') -- User1 doğrudan tablo INSERT yetkisi olmamalı
          )
   ) = 0 AND
   EXISTS (SELECT 1 FROM sys.database_permissions p JOIN sys.database_principals pr ON p.grantee_principal_id = pr.principal_id WHERE pr.name = N'User1' AND p.permission_name = N'EXECUTE' AND OBJECT_NAME(p.major_id) = N'sp_InsertUserDataSecure_ColumnEnc') AND
   EXISTS (SELECT 1 FROM sys.database_permissions p JOIN sys.database_principals pr ON p.grantee_principal_id = pr.principal_id WHERE pr.name = N'User1' AND p.permission_name = N'EXECUTE' AND OBJECT_NAME(p.major_id) = N'sp_GetUserDataSecure_ColumnEnc') AND
   EXISTS (SELECT 1 FROM sys.database_permissions p JOIN sys.database_principals pr ON p.grantee_principal_id = pr.principal_id WHERE pr.name = N'User2' AND p.permission_name = N'SELECT' AND OBJECT_NAME(p.major_id) = N'SensitiveData' AND p.state_desc = 'GRANT')
BEGIN
    SET @SecurityScore_ColEnc = @SecurityScore_ColEnc + 25;
    PRINT N'✓ Minimal kullanıcı izinleri (SP odaklı erişim) (+25 puan)';
END
ELSE
    PRINT N'✗ Aşırı veya eksik kullanıcı izinleri (0 puan)';

-- Stored procedures (şifreleme/deşifreleme yapan) kullanılıyor mu? (25 Puan)
IF EXISTS (SELECT * FROM sys.procedures WHERE name = N'sp_GetUserDataSecure_ColumnEnc') AND
   EXISTS (SELECT * FROM sys.procedures WHERE name = N'sp_InsertUserDataSecure_ColumnEnc')
BEGIN
    SET @SecurityScore_ColEnc = @SecurityScore_ColEnc + 25;
    PRINT N'✓ Güvenli Stored Procedure''ler (şifreleme/deşifreleme) mevcut (+25 puan)';
END
ELSE
    PRINT N'✗ Güvenli Stored Procedure''ler eksik (0 puan)';

PRINT N'';
PRINT N'=== SON GÜVENLİK SKORU (Sütun Şifreleme): ' + CAST(@SecurityScore_ColEnc AS VARCHAR(10)) + N'/' + CAST(@MaxScore_ColEnc AS VARCHAR(10)) + N' ===';

-- CASE ifadesi IF...ELSE IF...ELSE olarak değiştirildi
IF @SecurityScore_ColEnc = 100
    PRINT N'Güvenlik durumu: MÜKEMMEL ✓'
ELSE IF @SecurityScore_ColEnc >= 75
    PRINT N'Güvenlik durumu: İYİ ✓'
ELSE IF @SecurityScore_ColEnc >= 50
    PRINT N'Güvenlik durumu: ORTA'
ELSE
    PRINT N'Güvenlik durumu: ZAYIF - İyileştirme gerekli! (' + CAST(100-@SecurityScore_ColEnc AS VARCHAR(10)) + N' puan eksik)';

PRINT N'';
PRINT N'=== GÜVENLİK TESTLERİ (Sütun Şifreleme) TAMAMLANDI ===';
GO 