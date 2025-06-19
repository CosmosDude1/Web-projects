USE msdb;
GO

SELECT
    bs.database_name AS [Veritabaný Adý],
    CASE bs.type
        WHEN 'D' THEN 'Tam Yedek (Full)'
        WHEN 'I' THEN 'Diferansiyel Yedek (Differential)'
        WHEN 'L' THEN 'Log Yedeði (Transaction Log)'
        WHEN 'F' THEN 'Dosya veya Dosya Grubu Yedeði'
        WHEN 'G' THEN 'Diferansiyel Dosya Yedeði'
        WHEN 'P' THEN 'Kýsmi Yedek (Partial)'
        WHEN 'Q' THEN 'Diferansiyel Kýsmi Yedek'
        ELSE 'Diðer (' + bs.type + ')'
    END AS [Yedekleme Türü],
    bs.backup_start_date AS [Yedekleme Baþlangýç Zamaný],
    bs.backup_finish_date AS [Yedekleme Bitiþ Zamaný],
    CAST(bs.backup_size / 1024.0 / 1024.0 AS DECIMAL(10, 2)) AS [Yedekleme Boyutu (MB)],
    bmf.physical_device_name AS [Fiziksel Cihaz Adý (Dosya Yolu)],
    bs.name AS [Yedekleme Seti Adý],
    bs.description AS [Yedekleme Seti Açýklamasý]
FROM
    dbo.backupset bs
INNER JOIN
    dbo.backupmediafamily bmf ON bs.media_set_id = bmf.media_set_id
WHERE
    bs.database_name = 'AdventureWorks2019'
ORDER BY
    bs.backup_start_date DESC;
GO