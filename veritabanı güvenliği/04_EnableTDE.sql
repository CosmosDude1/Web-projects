-- ===================================================
-- SQL Güvenlik ve Erişim Kontrolü Projesi
-- Adım 4: Sütun Düzeyinde Şifreleme için Anahtar Kurulumu
-- ===================================================

-- Master veritabanında Database Master Key oluştur (SecureDB contexto'nda olmalı)
USE SecureDB; -- Anahtarların veritabanı özelinde olması için contexte geçiyoruz
GO

IF NOT EXISTS (SELECT * FROM sys.symmetric_keys WHERE name = '##MS_DatabaseMasterKey##')
BEGIN
    PRINT N'SecureDB için Veritabanı Ana Anahtarı oluşturuluyor...';
    CREATE MASTER KEY ENCRYPTION BY PASSWORD = N'ColumnMasterKeyP@sswOrd1!';
    PRINT N'✓ SecureDB için Veritabanı Ana Anahtarı oluşturuldu.';
END
ELSE
    PRINT N'SecureDB Veritabanı Ana Anahtarı zaten mevcut.';
GO

-- Sütun Şifrelemesi için Certificate oluştur
IF NOT EXISTS (SELECT * FROM sys.certificates WHERE name = N'SecureDB_ColumnEncryption_Cert')
BEGIN
    PRINT N'Sütun şifrelemesi için sertifika oluşturuluyor (SecureDB_ColumnEncryption_Cert)...';
    CREATE CERTIFICATE SecureDB_ColumnEncryption_Cert
    WITH SUBJECT = N'SecureDB Column Encryption Certificate',
         EXPIRY_DATE = N'2035-12-31';
    PRINT N'✓ SecureDB_ColumnEncryption_Cert sertifikası oluşturuldu.';
END
ELSE
    PRINT N'SecureDB_ColumnEncryption_Cert sertifikası zaten mevcut.';
GO

-- Certificate'i yedekle (önemli!)
-- !!! ÖNEMLİ: SQL Server servis hesabının 'C:\Temp' dizinine YAZMA İZNİ olduğundan emin olun. Dizin yoksa oluşturun. !!!
BEGIN TRY
    PRINT N'SecureDB_ColumnEncryption_Cert sertifikası yedekleniyor...';
    BACKUP CERTIFICATE SecureDB_ColumnEncryption_Cert
    TO FILE = N'C:\Temp\SecureDB_ColumnEncryption_Cert.cer'
    WITH PRIVATE KEY 
    (
        FILE = N'C:\Temp\SecureDB_ColumnEncryption_Cert.pvk',
        ENCRYPTION BY PASSWORD = N'CertBackupP@sswOrd1!'
    );
    PRINT N'✓ SecureDB_ColumnEncryption_Cert başarıyla yedeklendi. Dosyaları güvenli bir yerde saklayın!';
END TRY
BEGIN CATCH
    PRINT N'HATA: SecureDB_ColumnEncryption_Cert yedeklenemedi. ' + ERROR_MESSAGE();
    PRINT N'Lütfen C:\Temp dizininin var olduğundan ve SQL Server servis hesabının yazma izni olduğundan emin olun.';
END CATCH
GO

-- Sütun Şifrelemesi için Symmetric Key oluştur
IF NOT EXISTS (SELECT * FROM sys.symmetric_keys WHERE name = N'SecureColumnSymmetricKey')
BEGIN
    PRINT N'Simetrik anahtar (SecureColumnSymmetricKey) oluşturuluyor...';
    CREATE SYMMETRIC KEY SecureColumnSymmetricKey
    WITH ALGORITHM = AES_256
    ENCRYPTION BY CERTIFICATE SecureDB_ColumnEncryption_Cert;
    PRINT N'✓ SecureColumnSymmetricKey simetrik anahtarı, SecureDB_ColumnEncryption_Cert ile şifrelenerek oluşturuldu.';
END
ELSE
    PRINT N'SecureColumnSymmetricKey simetrik anahtarı zaten mevcut.';
GO

PRINT N'Sütun düzeyinde şifreleme için anahtar kurulumu tamamlandı.';
GO

-- Oluşturulan anahtarları ve sertifikayı kontrol et
PRINT N'--- Oluşturulan Sertifika Bilgileri ---';
SELECT name, subject, expiry_date, pvt_key_last_backup_date FROM sys.certificates WHERE name = N'SecureDB_ColumnEncryption_Cert';
GO

PRINT N'--- Oluşturulan Simetrik Anahtar Bilgileri ---';
SELECT name, algorithm_desc, key_length, create_date FROM sys.symmetric_keys WHERE name = N'SecureColumnSymmetricKey';
GO 