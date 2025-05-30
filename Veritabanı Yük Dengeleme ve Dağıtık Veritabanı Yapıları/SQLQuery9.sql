-- ============================================
-- SQL Monitoring Script (Replication + Always On)
-- D�ZENLENM�� S�R�M (Hata almayan yap�)
-- ============================================

-- 1. Distribution veritaban�n� Multi-User yap
PRINT '1. Distribution DB Multi-User yap�l�yor...';
ALTER DATABASE distribution SET MULTI_USER WITH ROLLBACK IMMEDIATE;
GO

-- 2. Distribution veritaban�na ge�
PRINT '2. Distribution veritaban�na ge�iliyor...';
USE distribution;
GO

-- 3. Replikasyon ajanlar� bilgisi
PRINT '3. MSdistribution_agents tablosundan ajan listesi:';
SELECT 
    id,
    name AS AgentName,
    profile_id,
    subscriber_id,
    publisher_id,
    publication
    -- publication_type kald�r�ld�
FROM MSdistribution_agents;
GO

-- 4. Ajan ge�mi�i
PRINT '4. MSdistribution_history tablosundan ajan ge�mi�i:';
SELECT 
    TOP 10
    agent_id,
    runstatus,       -- 2 = Ba�ar�l�, 3 = Hatal�
    time, 
    comments
FROM MSdistribution_history
ORDER BY time DESC;
GO

-- 5. Hatalar (MSrepl_errors)
PRINT '5. MSrepl_errors tablosu:';
SELECT 
    TOP 10
    id,              -- error_id yerine varsay�lan id kullan�ld�
    error_code,
    error_text
FROM MSrepl_errors
ORDER BY time DESC;
GO

-- 6. Abonelik bilgileri (Yaln�zca yay�n tan�ml�ysa �al���r)
PRINT '6. sp_helpsubscription (varsa yay�n tan�m�):';
BEGIN TRY
    EXEC sp_helpsubscription;
END TRY
BEGIN CATCH
    PRINT 'sp_helpsubscription �al��t�r�lamad�. Yay�n tan�m� yap�lmam�� olabilir.';
END CATCH;
GO

-- 7. Replikasyon izleme (opsiyonel - yaln�zca monitor kurulmu�sa �al���r)
PRINT '7. sp_replmonitorhelpsubscription (repl. monitor varsa):';
BEGIN TRY
    EXEC sp_replmonitorhelpsubscription;
END TRY
BEGIN CATCH
    PRINT 'sp_replmonitorhelpsubscription �al��t�r�lamad�. Muhtemelen monitor tan�ml� de�il.';
END CATCH;
GO

-- 8. Always On bilgisi (yaln�zca aktifse �al���r)
PRINT '8. Always On Durumu (sys.availability_replicas):';
USE master;
GO

BEGIN TRY
    SELECT 
        ar.replica_server_name,
        rs.role_desc,
        rs.connected_state_desc,
        rs.synchronization_health_desc
    FROM sys.availability_replicas ar
    JOIN sys.dm_hadr_availability_replica_states rs
        ON ar.replica_id = rs.replica_id;
END TRY
BEGIN CATCH
    PRINT 'Always On g�r�nm�yor ya da sistemde tan�ml� de�il.';
END CATCH;
GO

PRINT 'Monitoring tamamland�.';
-- ============================================

