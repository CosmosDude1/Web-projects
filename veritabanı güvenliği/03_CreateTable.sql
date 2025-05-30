-- ===================================================
-- SQL Güvenlik ve Erişim Kontrolü Projesi
-- Adım 3: SensitiveData Tablosu Oluşturma ve İzinler (Sütun Şifrelemeli)
-- ===================================================

USE SecureDB;
GO

-- SensitiveData tablosunu oluştur
IF OBJECT_ID('dbo.SensitiveData', 'U') IS NOT NULL
    DROP TABLE dbo.SensitiveData;
GO

CREATE TABLE dbo.SensitiveData
(
    ID INT IDENTITY(1,1) PRIMARY KEY,
    FullName NVARCHAR(100) NOT NULL,
    CreditCardNumber VARBINARY(256) NULL, -- Şifreli veri için VARBINARY
    ExpiryDate DATE,
    SecurityCode NVARCHAR(4), -- Bu sütun da şifrelenebilir, şimdilik açık bırakıldı
    CreatedDate DATETIME2 DEFAULT GETDATE(),
    CreatedBy NVARCHAR(50) DEFAULT SUSER_NAME()
);
GO

PRINT N'SensitiveData tablosu (CreditCardNumber VARBINARY) oluşturuldu.';
GO

-- Simetrik anahtarı aç (veri ekleme ve okuma işlemleri için gerekli)
-- Bu anahtarın her sessionda veya gerektiğinde açılması gerekir.
-- Güvenlik nedeniyle, sadece gerektiğinde açıp hemen kapatılmalıdır.
BEGIN TRY
    PRINT N'SecureColumnSymmetricKey açılıyor...';
    OPEN SYMMETRIC KEY SecureColumnSymmetricKey
    DECRYPTION BY CERTIFICATE SecureDB_ColumnEncryption_Cert;
    PRINT N'✓ SecureColumnSymmetricKey başarıyla açıldı.';
END TRY
BEGIN CATCH
    PRINT N'HATA: SecureColumnSymmetricKey açılamadı. ' + ERROR_MESSAGE();
    PRINT N'Lütfen 04 numaralı scriptin doğru çalıştığından ve anahtarların mevcut olduğundan emin olun.';
    -- Eğer hata oluşursa, devam eden INSERT işlemleri başarısız olabilir.
END CATCH
GO

-- Örnek hassas veri ekle (CreditCardNumber şifrelenerek)
PRINT N'Örnek şifreli veriler ekleniyor...';
BEGIN TRY
    INSERT INTO dbo.SensitiveData (FullName, CreditCardNumber, ExpiryDate, SecurityCode)
    VALUES 
        (N'Ahmet Yılmaz', EncryptByKey(Key_GUID(N'SecureColumnSymmetricKey'), N'4532-1234-5678-9012'), N'2025-12-31', N'123'),
        (N'Ayşe Demir', EncryptByKey(Key_GUID(N'SecureColumnSymmetricKey'), N'5555-4444-3333-2222'), N'2026-06-30', N'456'),
        (N'Mehmet Kaya', EncryptByKey(Key_GUID(N'SecureColumnSymmetricKey'), N'4111-1111-1111-1111'), N'2025-08-15', N'789');
    PRINT N'✓ Örnek şifreli veriler başarıyla eklendi.';
END TRY
BEGIN CATCH
    PRINT N'HATA: Örnek şifreli veri eklenemedi. ' + ERROR_MESSAGE();
    PRINT N'SecureColumnSymmetricKey''in açık olduğundan emin olun.';
END CATCH
GO

-- Veri ekleme işlemi bittikten sonra anahtarı kapat (iyi bir pratiktir)
-- Ancak, bu scriptten sonra başka scriptler bu anahtarı kullanacaksa açık bırakılabilir.
-- Şimdilik bu scriptin sonunda kapatmıyoruz, diğer scriptler de kullanabilsin diye.
-- CLOSE SYMMETRIC KEY SecureColumnSymmetricKey;
-- PRINT N'SecureColumnSymmetricKey kapatıldı.';
-- GO

PRINT N'SensitiveData tablosu oluşturuldu ve örnek şifreli veriler eklendi.';
GO

-- User1'e SELECT ve INSERT izinlerini ver
GRANT SELECT, INSERT ON dbo.SensitiveData TO User1;
GO

PRINT N'User1''e SensitiveData tablosunda SELECT ve INSERT izinleri verildi.';
GO

-- User2'ye sadece SELECT izni ver (karşılaştırma için)
-- User2 şifreli veriyi okuyabilir ama deşifre edemez (anahtarı açma yetkisi yoksa).
GRANT SELECT ON dbo.SensitiveData TO User2;
GO

PRINT N'User2''ye SensitiveData tablosunda SELECT izni verildi.';
GO

-- İzinleri kontrol et
SELECT 
    p.state_desc,
    p.permission_name,
    s.name AS principal_name,
    o.name AS object_name
FROM sys.database_permissions p
    LEFT JOIN sys.objects o ON p.major_id = o.object_id
    LEFT JOIN sys.database_principals s ON p.grantee_principal_id = s.principal_id
WHERE o.name = N'SensitiveData'
    AND s.name IN (N'User1', N'User2')
ORDER BY s.name, p.permission_name;
GO

-- Şifreli veriyi test amaçlı okuma (DEŞİFRE EDİLMEDEN)
PRINT N'--- CreditCardNumber (ŞİFRELİ - VARBINARY) ---';
SELECT TOP 1 FullName, CreditCardNumber FROM dbo.SensitiveData;
GO

-- Şifreli veriyi test amaçlı okuma (DEŞİFRE EDİLEREK)
-- Bu sorgunun çalışması için SecureColumnSymmetricKey'in AÇIK olması gerekir.
PRINT N'--- CreditCardNumber (DEŞİFRE EDİLMİŞ - Eğer anahtar açıksa) ---';
SELECT TOP 1 
    FullName, 
    CreditCardNumber AS Encrypted_CC,
    CONVERT(NVARCHAR(100), DecryptByKey(CreditCardNumber)) AS Decrypted_CC 
FROM dbo.SensitiveData;
GO

-- ÖNEMLİ: Uygulama katmanında veya Stored Procedure'lerde veri okunurken
-- OPEN SYMMETRIC KEY ... ve CLOSE SYMMETRIC KEY ... komutlarının
-- doğru bir şekilde yönetilmesi (sadece gerektiğinde açıp kapatma) çok önemlidir. 