USE Databaseproduct;
GO

EXEC sp_replicationdboption 
    @dbname = N'Databaseproduct', 
    @optname = N'publish', 
    @value = N'true';
GO

-- Publication oluþtur
EXEC sp_addpublication 
    @publication = N'DatabaseproductPub', 
    @status = N'active';
GO

-- Article ekle (Product tablosu)
EXEC sp_addarticle 
    @publication = N'DatabaseproductPub', 
    @article = N'Product', 
    @source_object = N'Product', 
    @type = N'logbased';
GO

PRINT 'Publication ve article tanýmlandý.';
