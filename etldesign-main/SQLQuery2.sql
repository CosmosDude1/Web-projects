
IF NOT EXISTS (SELECT srv.name FROM sys.servers srv WHERE srv.server_id != 0 AND srv.name = N'MyLinked')
BEGIN
    
    EXEC master.dbo.sp_addlinkedserver
        @server = N'MyLinked',
        @srvproduct = N'', 
        @provider = N'SQLNCLI', 
        @datasrc = N'UZAK_SUNUCU_ADI\INSTANCE_ADI'; 

    PRINT N'MyLinked adl� ba�l� sunucu olu�turuldu.';
END


EXEC master.dbo.sp_addlinkedsrvlogin
    @rmtsrvname = N'MyLinked',
    @useself = N'False', 
    @locallogin = NULL, 
    @rmtuser = N'uzak_sunucu_kullanici_adi',
    @rmtpassword = N'uzak_sunucu_sifresi';

PRINT N'MyLinked i�in uzak sunucu giri� bilgileri yap�land�r�ld�.';
GO

