USE Databaseproduct;
GO

IF OBJECT_ID('dbo.Product', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Product (
        ProductID INT IDENTITY(1,1) PRIMARY KEY,
        ProductName NVARCHAR(100),
        Price DECIMAL(10,2),
        Stock INT
    );
    PRINT 'Product tablosu oluþturuldu.';
END
ELSE
BEGIN
    PRINT 'Product tablosu zaten mevcut.';
END
GO
