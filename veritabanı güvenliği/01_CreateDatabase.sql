-- ===================================================
-- SQL Güvenlik ve Erişim Kontrolü Projesi
-- Adım 1: SecureDB Veritabanı Oluşturma
-- ===================================================

USE master;
GO

-- Eğer veritabanı mevcutsa sil
IF DB_ID('SecureDB') IS NOT NULL
BEGIN
    ALTER DATABASE SecureDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE SecureDB;
END
GO

-- SecureDB veritabanını oluştur
CREATE DATABASE SecureDB
ON 
(
    NAME = 'SecureDB_Data',
    FILENAME = 'C:\Program Files\Microsoft SQL Server\MSSQL16.SQLEXPRESS\MSSQL\DATA\SecureDB.mdf',
    SIZE = 100MB,
    MAXSIZE = 1GB,
    FILEGROWTH = 10MB
)
LOG ON 
(
    NAME = 'SecureDB_Log',
    FILENAME = 'C:\Program Files\Microsoft SQL Server\MSSQL16.SQLEXPRESS\MSSQL\DATA\SecureDB.ldf',
    SIZE = 10MB,
    MAXSIZE = 100MB,
    FILEGROWTH = 5MB
);
GO

PRINT 'SecureDB veritabanı başarıyla oluşturuldu.';
GO 