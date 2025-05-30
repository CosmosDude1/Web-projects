USE Databaseproduct;
GO

INSERT INTO dbo.Product (ProductName, Price, Stock)
VALUES 
('Laptop', 1500.00, 10),
('Mouse', 25.00, 100),
('Keyboard', 45.00, 50),
('Monitor', 300.00, 20),
('Printer', 200.00, 15);

PRINT 'Örnek veriler eklendi.';
GO
