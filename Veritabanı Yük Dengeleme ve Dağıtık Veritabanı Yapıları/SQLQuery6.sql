-- Instance2 sunucu adý
DECLARE @subscriber NVARCHAR(128) = N'INSTANCE2';

-- Subscription ekle
EXEC sp_addsubscription 
    @publication = N'DatabaseproductPub', 
    @subscriber = @subscriber, 
    @destination_db = N'Databaseproduct', 
    @subscription_type = N'Push', 
    @sync_type = N'automatic', 
    @article = N'all', 
    @update_mode = N'read only', 
    @subscriber_type = 0;
GO

PRINT 'Subscription baþarýyla eklendi.';
