        
        SELECT * FROM OPENROWSET('Microsoft.ACE.OLEDB.12.0',
            'Excel 12.0 Xml;HDR=YES;Database=C:\dosya_yolu\dosyam.xlsx',
            'SELECT * FROM [SayfaAdi$]');

        -- �rnek: CSV dosyas�ndan veri okuma
        SELECT * FROM OPENROWSET('CSV',
            'DATAFILE=C:\dosya_yolu\veri.csv',
            'FORMAT=CSV,FIRSTROW=2,FIELDTERMINATOR='','',ROWTERMINATOR=''\n'''
        ) AS Veriler;