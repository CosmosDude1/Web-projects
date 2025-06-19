USE master;
GO

-- DW_AdventureWorks'e baðlý tüm SPID'leri öldür
DECLARE @kill varchar(max)= '';
SELECT @kill += 'KILL ' + CAST(spid AS varchar) + ';'
FROM sys.sysprocesses
WHERE dbid = DB_ID('DW_AdventureWorks')
  AND spid <> @@SPID;  -- kendi oturumunuzu atlamýþ olursunuz

EXEC(@kill);

-- Artýk Multi-User moduna alabiliriz
ALTER DATABASE DW_AdventureWorks
  SET MULTI_USER
  WITH ROLLBACK IMMEDIATE;
GO
