
SELECT 
    DB_NAME(dbid) as DBName,
    COUNT(dbid) as NumberOfConnections,
    loginame as LoginName
FROM
    sys.sysprocesses
WHERE 
    DB_NAME(dbid) = 'AdventureWorks2019'
GROUP BY 
    dbid, loginame;
