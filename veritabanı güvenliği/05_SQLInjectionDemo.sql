-- ===================================================
-- SQL Güvenlik ve Erişim Kontrolü Projesi
-- Adım 5: SQL Injection Demonstrasyonu ve Korunma (Sütun Şifrelemeli)
-- ===================================================

USE SecureDB;
GO

-- Test kullanıcısı olarak bağlan (User1)
-- EXECUTE AS USER = 'User1';

-- ===================================================
-- BÖLÜM 1: SQL INJECTION SALDIRISI ÖRNEĞİ
-- ===================================================

PRINT N'=== SQL INJECTION SALDIRISI DENEMESİ ===';
GO

-- Güvensiz dynamic SQL örneği (KULLANMAYIN!)
DECLARE @UnsafeUserInput NVARCHAR(100) = N''' OR 1=1 --';
DECLARE @UnsafeSQL NVARCHAR(MAX);

-- Bu sorgu artık doğrudan çalışmayacaktır çünkü FullName ile deşifre edilmiş CreditCardNumber karşılaştırması gerekir.
-- SQL Injection'ı sütun şifreleme ile göstermek için sorguyu biraz değiştirmek gerekir.
-- Şimdilik bu bölümü konsept olarak bırakıyoruz, asıl odak şifreleme/deşifreleme.
SET @UnsafeSQL = N'SELECT FullName, CONVERT(NVARCHAR(100), DecryptByKey(CreditCardNumber)) AS Decrypted_CC FROM SensitiveData WHERE FullName = N''' + @UnsafeUserInput + N'''';

PRINT N'Güvensiz SQL sorgusu (Deşifre denemesi ile):';
PRINT @UnsafeSQL;
PRINT N'';

PRINT N'Uyarı: Bu güvensiz sorguyu çalıştırmak için önce anahtarın açılması gerekir.';
PRINT N'SQL Injection demosu için, bu sorgunun tüm kayıtları döndürme potansiyeli vardır.';
-- OPEN SYMMETRIC KEY SecureColumnSymmetricKey DECRYPTION BY CERTIFICATE SecureDB_ColumnEncryption_Cert;
-- EXEC sp_executesql @UnsafeSQL;
-- CLOSE SYMMETRIC KEY SecureColumnSymmetricKey;
GO

-- ===================================================
-- BÖLÜM 2: PARAMETERİZE EDİLMİŞ SORGU (GÜVENLİ)
-- ===================================================

PRINT N'=== PARAMETERİZE EDİLMİŞ SORGU (GÜVENLİ) ===';
GO

PRINT N'Bölüm 2: Stored Procedure testi, SP oluşturulduktan sonra Bölüm 3 içerisinde yapılmaktadır.';
GO

-- ===================================================
-- BÖLÜM 3: STORED PROCEDURE İLE GÜVENLİK (SÜTUN ŞİFRELEMELİ)
-- ===================================================
PRINT N'=== GÜNCELLENMİŞ STORED PROCEDURE''LER ===';
GO

-- Güvenli stored procedure (veri okuma ve deşifreleme)
IF OBJECT_ID('sp_GetUserDataSecure_ColumnEnc', 'P') IS NOT NULL
    DROP PROCEDURE sp_GetUserDataSecure_ColumnEnc;
GO

CREATE PROCEDURE sp_GetUserDataSecure_ColumnEnc
    @FullName NVARCHAR(100)
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    
    PRINT N'sp_GetUserDataSecure_ColumnEnc: SecureColumnSymmetricKey açılıyor...';
    OPEN SYMMETRIC KEY SecureColumnSymmetricKey
    DECRYPTION BY CERTIFICATE SecureDB_ColumnEncryption_Cert;
    
    PRINT N'sp_GetUserDataSecure_ColumnEnc: Veri okunuyor ve deşifre ediliyor...';
    SELECT 
        ID,
        FullName,
        CONVERT(NVARCHAR(100), DecryptByKey(CreditCardNumber)) AS Decrypted_CreditCardNumber,
        ExpiryDate,
        CreatedDate
    FROM SensitiveData 
    WHERE FullName = @FullName;
    
    PRINT N'sp_GetUserDataSecure_ColumnEnc: SecureColumnSymmetricKey kapatılıyor...';
    CLOSE SYMMETRIC KEY SecureColumnSymmetricKey;
END
GO

PRINT N'✓ sp_GetUserDataSecure_ColumnEnc oluşturuldu/güncellendi.';
GO

-- Stored procedure test et
PRINT N'=== sp_GetUserDataSecure_ColumnEnc TEST ===';
PRINT N'''Ahmet Yılmaz'' için veri getiriliyor...';
EXEC sp_GetUserDataSecure_ColumnEnc @FullName = N'Ahmet Yılmaz';

PRINT N'SQL Injection denemesi (basitleştirilmiş test string''i ile) için veri getiriliyor...';
DECLARE @SafeUserInput_ForSP_Test NVARCHAR(100) = N'HarmlessText'' OR 1=1 --'; 
EXEC sp_GetUserDataSecure_ColumnEnc @FullName = @SafeUserInput_ForSP_Test;
PRINT N'Sonuç: Güvenli Stored Procedure (sp_GetUserDataSecure_ColumnEnc) ile hiçbir ilgisiz kayıt döndürülmedi.';
GO

-- ===================================================
-- BÖLÜM 4: INPUT VALİDASYON VE ŞİFRELEME İLE VERİ EKLEME
-- ===================================================
IF OBJECT_ID('sp_InsertUserDataSecure_ColumnEnc', 'P') IS NOT NULL
    DROP PROCEDURE sp_InsertUserDataSecure_ColumnEnc;
GO

CREATE PROCEDURE sp_InsertUserDataSecure_ColumnEnc
    @FullName NVARCHAR(100),
    @CreditCardNumber_Plain NVARCHAR(20) -- Kredi kartı numarasını düz metin olarak al
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    
    PRINT N'sp_InsertUserDataSecure_ColumnEnc: Input validation...';
    IF @FullName IS NULL OR LEN(LTRIM(RTRIM(@FullName))) = 0
    BEGIN
        RAISERROR(N'Ad Soyad alanı boş olamaz.', 16, 1);
        RETURN;
    END
    
    IF @CreditCardNumber_Plain IS NULL OR LEN(REPLACE(@CreditCardNumber_Plain, N'-', N'')) NOT BETWEEN 13 AND 19 -- Basit bir format kontrolü
    BEGIN
        RAISERROR(N'Geçersiz kredi kartı numarası formatı veya uzunluğu.', 16, 1);
        RETURN;
    END
    
    PRINT N'sp_InsertUserDataSecure_ColumnEnc: SecureColumnSymmetricKey açılıyor...';
    OPEN SYMMETRIC KEY SecureColumnSymmetricKey
    DECRYPTION BY CERTIFICATE SecureDB_ColumnEncryption_Cert;

    DECLARE @EncryptedCreditCard VARBINARY(256);
    PRINT N'sp_InsertUserDataSecure_ColumnEnc: Kredi kartı numarası şifreleniyor...';
    SET @EncryptedCreditCard = EncryptByKey(Key_GUID(N'SecureColumnSymmetricKey'), @CreditCardNumber_Plain);
    
    PRINT N'sp_InsertUserDataSecure_ColumnEnc: Veri ekleniyor...';
    INSERT INTO SensitiveData (FullName, CreditCardNumber, ExpiryDate, SecurityCode) 
    VALUES (@FullName, @EncryptedCreditCard, NULL, NULL); 
    
    PRINT N'sp_InsertUserDataSecure_ColumnEnc: SecureColumnSymmetricKey kapatılıyor...';
    CLOSE SYMMETRIC KEY SecureColumnSymmetricKey;
    
    PRINT N'Veri başarıyla (şifrelenerek) eklendi.';
END
GO

PRINT N'✓ sp_InsertUserDataSecure_ColumnEnc oluşturuldu/güncellendi.';
GO

-- Stored procedure test et
PRINT N'=== sp_InsertUserDataSecure_ColumnEnc INPUT VALİDASYON TEST ===';
BEGIN TRY
    PRINT N'Geçerli veri ekleniyor...';
    EXEC sp_InsertUserDataSecure_ColumnEnc @FullName = N'Test Kullanıcı Şifreli', @CreditCardNumber_Plain = N'1234-5678-9012-3456';
END TRY
BEGIN CATCH
    PRINT N'HATA sp_InsertUserDataSecure_ColumnEnc: ' + ERROR_MESSAGE();
END CATCH

BEGIN TRY
    PRINT N'Boş Ad Soyad ile veri ekleme denemesi...';
    EXEC sp_InsertUserDataSecure_ColumnEnc @FullName = N'', @CreditCardNumber_Plain = N'1234-5678-9012-3456'; 
END TRY
BEGIN CATCH
    PRINT N'HATA sp_InsertUserDataSecure_ColumnEnc (Boş Ad Soyad): ' + ERROR_MESSAGE();
END CATCH

BEGIN TRY
    PRINT N'Geçersiz Kredi Kartı ile veri ekleme denemesi...';
    EXEC sp_InsertUserDataSecure_ColumnEnc @FullName = N'Test Kullanıcı Şifreli 2', @CreditCardNumber_Plain = N'123';
END TRY
BEGIN CATCH
    PRINT N'HATA sp_InsertUserDataSecure_ColumnEnc (Geçersiz Kredi Kartı): ' + ERROR_MESSAGE();
END CATCH
GO

PRINT N'=== SÜTUN ŞİFRELEMELİ SQL INJECTION DEMONSTRASYONU TAMAMLANDI ===';
PRINT N'Güvenlik kuralları sütun şifrelemesiyle de geçerlidir:';
PRINT N'1. Hiçbir zaman dynamic SQL ile kullanıcı girişi birleştirmeyin (deşifre edilmiş veriyle bile).';
PRINT N'2. Her zaman parameterized queries ve Stored Procedures kullanın.';
PRINT N'3. Simetrik anahtarları sadece gerektiğinde AÇIK TUTUN ve işiniz bitince KAPATIN.';
PRINT N'4. Input validation yapın (hem düz metin hem de şifreleme öncesi).';
PRINT N'5. En az yetki prensibiyle çalışın (kimin anahtarı açma yetkisi olmalı?).';
GO 