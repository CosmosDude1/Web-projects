        -- �rnek: Son Y�kleme Tarihine G�re Art�ml� Veri �ekme
        DECLARE @SonYuklemeTarihi DATETIME = '2023-01-01'; -- Bu de�er bir kontrol tablosundan okunabilir
        SELECT *
        FROM KaynakTablo
        WHERE GuncellenmeTarihi > @SonYuklemeTarihi;