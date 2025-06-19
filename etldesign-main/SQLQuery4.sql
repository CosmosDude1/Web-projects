    EXEC master.dbo.sp_dropserver 'MyLinked', 'droplogins'; -- Önce varsa silin
    GO
    EXEC master.dbo.sp_addlinkedserver
        @server = N'MyLinked',
        @srvproduct = N'',
        @provider = N'MSOLEDBSQL',
        @datasrc = N'UZAK_SUNUCUNUN_IP_ADRESI'; -- Veya UZAK_SUNUCUNUN_IP_ADRESI,PORT_NUMARASI veya UZAK_SUNUCUNUN_IP_ADRESI\INSTANCE_ADI
    GO
    EXEC master.dbo.sp_addlinkedsrvlogin
        @rmtsrvname = N'MyLinked',
        @useself = N'False',
        @locallogin = NULL,
        @rmtuser = N'uzak_kullanici_adi',
        @rmtpassword = N'uzak_sifre';
    GO