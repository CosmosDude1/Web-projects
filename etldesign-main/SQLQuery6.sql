-- 1. Geli�mi� se�enekleri g�stermeyi etkinle�tir (e�er zaten etkin de�ilse)
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
GO

-- 2. 'Ad Hoc Distributed Queries' �zelli�ini etkinle�tir
EXEC sp_configure 'Ad Hoc Distributed Queries', 1;
RECONFIGURE;
GO

-- �ste�e ba�l�: Geli�mi� se�enekleri tekrar gizle (varsay�lan ayara d�nmek i�in)
-- EXEC sp_configure 'show advanced options', 0;
-- RECONFIGURE;
-- GO

-- Ayar�n etkin olup olmad���n� kontrol etmek i�in:
EXEC sp_configure 'Ad Hoc Distributed Queries';
-- Bu sorgunun sonucunda config_value ve run_value s�tunlar�nda 1 g�rmelisiniz.