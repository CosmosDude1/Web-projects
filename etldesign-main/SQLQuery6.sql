-- 1. Geliþmiþ seçenekleri göstermeyi etkinleþtir (eðer zaten etkin deðilse)
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
GO

-- 2. 'Ad Hoc Distributed Queries' özelliðini etkinleþtir
EXEC sp_configure 'Ad Hoc Distributed Queries', 1;
RECONFIGURE;
GO

-- Ýsteðe baðlý: Geliþmiþ seçenekleri tekrar gizle (varsayýlan ayara dönmek için)
-- EXEC sp_configure 'show advanced options', 0;
-- RECONFIGURE;
-- GO

-- Ayarýn etkin olup olmadýðýný kontrol etmek için:
EXEC sp_configure 'Ad Hoc Distributed Queries';
-- Bu sorgunun sonucunda config_value ve run_value sütunlarýnda 1 görmelisiniz.