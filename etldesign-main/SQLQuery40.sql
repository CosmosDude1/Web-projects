IF OBJECT_ID('dwh.FactInternetSales','U') IS NULL
CREATE TABLE dwh.FactInternetSales (
  FactKey     BIGINT IDENTITY PRIMARY KEY,
  OrderID     INT,
  ProductID   INT,
  TerritoryID INT,
  OrderQty    SMALLINT,
  LineTotal   MONEY,
  SaleDate    DATE
);
GO

INSERT INTO dwh.FactInternetSales (OrderID,ProductID,TerritoryID,OrderQty,LineTotal,SaleDate)
SELECT
  h.SalesOrderID,
  d.ProductID,
  h.TerritoryID,
  d.OrderQty,
  d.LineTotal,
  CONVERT(date,h.OrderDate)
FROM ods.SalesOrderHeader h
JOIN ods.SalesOrderDetail d
  ON h.SalesOrderID = d.SalesOrderID
WHERE NOT EXISTS (
  SELECT 1 FROM dwh.FactInternetSales f
   WHERE f.OrderID = h.SalesOrderID AND f.ProductID = d.ProductID
);
GO

SELECT COUNT(*) AS FactCount FROM dwh.FactInternetSales;
