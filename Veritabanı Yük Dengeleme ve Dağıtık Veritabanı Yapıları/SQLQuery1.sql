USE master;
GO

IF DB_ID('Databaseproduct') IS NULL
BEGIN
    CREATE DATABASE Databaseproduct;
    PRINT 'Databaseproduct veritabanı oluşturuldu.';
END
ELSE
BEGIN
    PRINT 'Databaseproduct zaten mevcut.';
END
GO
