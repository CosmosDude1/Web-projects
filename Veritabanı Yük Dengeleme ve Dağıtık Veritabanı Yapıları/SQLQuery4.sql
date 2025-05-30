-- Distributor'ü ayarla
USE master;
GO
EXEC sp_adddistributor @distributor = @@SERVERNAME, @heartbeat_interval = 5;
EXEC sp_adddistributiondb @database = N'distribution', @data_folder = N'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA', @log_folder = N'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA';
GO

-- Publisher ayarla
EXEC sp_adddistpublisher @publisher = @@SERVERNAME, @distribution_db = N'distribution', @security_mode = 1;
GO

PRINT 'Distributor ve Publisher ayarlandý.';
