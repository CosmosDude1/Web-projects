USE msdb;
GO

EXEC dbo.sp_add_operator
    @name = N'DBAdmin',
    @enabled = 1,
    @email_address = N'yonetici@hesabim.com'; -- Bildirim alacak e-posta adresi
GO