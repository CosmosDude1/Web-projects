USE msdb;
GO

SELECT
    bs.database_name AS [Veritaban� Ad�],
    CASE bs.type
        WHEN 'D' THEN 'Tam Yedek (Full)'
        WHEN 'I' THEN 'Diferansiyel Yedek (Differential)'
        WHEN 'L' THEN 'Log Yede�i (Transaction Log)'
        WHEN 'F' THEN 'Dosya veya Dosya Grubu Yede�i'
        WHEN 'G' THEN 'Diferansiyel Dosya Yede�i'
        WHEN 'P' THEN 'K�smi Yedek (Partial)'
        WHEN 'Q' THEN 'Diferansiyel K�smi Yedek'
        ELSE 'Di�er (' + bs.type + ')'
    END AS [Yedekleme T�r�],
    bs.backup_start_date AS [Yedekleme Ba�lang�� Zaman�],
    bs.backup_finish_date AS [Yedekleme Biti� Zaman�],
    CAST(bs.backup_size / 1024.0 / 1024.0 AS DECIMAL(10, 2)) AS [Yedekleme Boyutu (MB)],
    bmf.physical_device_name AS [Fiziksel Cihaz Ad� (Dosya Yolu)],
    bs.name AS [Yedekleme Seti Ad�],
    bs.description AS [Yedekleme Seti A��klamas�]
FROM
    dbo.backupset bs
INNER JOIN
    dbo.backupmediafamily bmf ON bs.media_set_id = bmf.media_set_id
WHERE
    bs.database_name = 'AdventureWorks2019'
ORDER BY
    bs.backup_start_date DESC;
GO