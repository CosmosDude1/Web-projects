-- AdventureWorks2019’dan CSV olarak çýkar
EXEC master.dbo.xp_cmdshell
  'bcp "SELECT *, GETDATE() AS ExtractDtm FROM AdventureWorks2019.Production.ProductDescription"
   queryout "D:\ETL\Land\Product_$(date:yyyyMMdd).csv" -c -t, -T -S (local)';
