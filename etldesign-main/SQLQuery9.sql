        -- Örnek: Son Yükleme Tarihine Göre Artýmlý Veri Çekme
        DECLARE @SonYuklemeTarihi DATETIME = '2023-01-01'; -- Bu deðer bir kontrol tablosundan okunabilir
        SELECT *
        FROM KaynakTablo
        WHERE GuncellenmeTarihi > @SonYuklemeTarihi;