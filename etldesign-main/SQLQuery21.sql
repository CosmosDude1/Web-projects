-- Eðer henüz yoksa
IF OBJECT_ID('dwh.FactInternetSales','U') IS NULL
CREATE TABLE dwh.FactInternetSales (
  FactKey       bigint IDENTITY PRIMARY KEY,
  OrderID       int,
  ProductID     int,
  TerritoryID   int,
  OrderQty      smallint,
  LineTotal     money,
  SaleDate      date
);

-- Basit yükleme
INSERT INTO dwh.FactInternetSales (OrderID,ProductID,TerritoryID,OrderQty,LineTotal,SaleDate)
SELECT 
  h.SalesOrderID,
  d.ProductID,
  h.TerritoryID,
  d.OrderQty,
  d.LineTotal,
  CONVERT(date,h.OrderDate)
FROM AdventureWorks2019.Sales.SalesOrderHeader h
JOIN AdventureWorks2019.Sales.SalesOrderDetail d
  ON h.SalesOrderID = d.SalesOrderID
WHERE NOT EXISTS (
  SELECT 1 FROM dwh.FactInternetSales f WHERE f.OrderID = h.SalesOrderID AND f.ProductID = d.ProductID
);
GO

SELECT TOP 5 * FROM dwh.FactInternetSales;
