USE master;
GO


DECLARE @kill varchar(8000) = '';
SELECT @kill = @kill + 'kill ' + CONVERT(varchar(5), spid) + ';'
FROM sys.sysprocesses 
WHERE db_name(dbid) = 'AdventureWorks2019'
AND spid != @@SPID;
EXEC(@kill);
GO

ALTER DATABASE AdventureWorks2019 SET MULTI_USER;
GO
