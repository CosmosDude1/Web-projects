USE master;
GO

IF DB_ID('Databaseproduct') IS NULL
BEGIN
    CREATE DATABASE Databaseproduct;
    PRINT 'Databaseproduct veritabaný oluþturuldu.';
END
ELSE
BEGIN
    PRINT 'Databaseproduct zaten mevcut.';
END
GO
