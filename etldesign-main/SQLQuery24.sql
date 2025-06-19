USE EtlDB;        -- do�ru veritaban�nda oldu�unuzdan emin olun
GO

/*------------------------------------------------------------
  Staging  : stg.Product               -- ham veri
  Hedef    : ods.Product               -- temiz veri
------------------------------------------------------------*/
CREATE OR ALTER PROCEDURE etl.usp_Clean_Product
AS
BEGIN
    SET NOCOUNT ON;

    /* 1) Kaynaktan se� (alt sorguyu WITH/CTE i�inde tutmak okunakl�l�k sa�lar) */
    ;WITH src AS (                      -- <- ba�taki ';' CTE �ncesi gereklidir
        SELECT
            p.ProductID,
            p.Name,
            NULLIF(LTRIM(RTRIM(p.Color)), '')        AS Color,
            ABS(p.StandardCost)                      AS StandardCost,  -- negatifse pozitife �evir
            ABS(p.ListPrice)                         AS ListPrice,
            p.ProductSubcategoryID
        FROM   stg.Product AS p
    )

    /* 2) MERGE ile guncelle/ekle */
    MERGE ods.Product           AS tgt
    USING src                   AS s
          ON tgt.ProductID = s.ProductID
    WHEN MATCHED THEN
        UPDATE SET
            Name                 = s.Name,
            Color                = s.Color,
            StandardCost         = s.StandardCost,
            ListPrice            = s.ListPrice,
            ProductSubcategoryID = s.ProductSubcategoryID,
            RowDtm               = SYSUTCDATETIME()
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (ProductID, Name, Color, StandardCost, ListPrice, ProductSubcategoryID)
        VALUES (s.ProductID, s.Name, s.Color, s.StandardCost, s.ListPrice, s.ProductSubcategoryID)
    ;
END
GO
