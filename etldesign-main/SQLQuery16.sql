USE master;
GO

-- DW_AdventureWorks'e ba�l� t�m SPID'leri �ld�r
DECLARE @kill varchar(max)= '';
SELECT @kill += 'KILL ' + CAST(spid AS varchar) + ';'
FROM sys.sysprocesses
WHERE dbid = DB_ID('DW_AdventureWorks')
  AND spid <> @@SPID;  -- kendi oturumunuzu atlam�� olursunuz

EXEC(@kill);

-- Art�k Multi-User moduna alabiliriz
ALTER DATABASE DW_AdventureWorks
  SET MULTI_USER
  WITH ROLLBACK IMMEDIATE;
GO
