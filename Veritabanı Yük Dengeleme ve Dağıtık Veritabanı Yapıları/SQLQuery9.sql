-- ============================================
-- SQL Monitoring Script (Replication + Always On)
-- DÜZENLENMÝÞ SÜRÜM (Hata almayan yapý)
-- ============================================

-- 1. Distribution veritabanýný Multi-User yap
PRINT '1. Distribution DB Multi-User yapýlýyor...';
ALTER DATABASE distribution SET MULTI_USER WITH ROLLBACK IMMEDIATE;
GO

-- 2. Distribution veritabanýna geç
PRINT '2. Distribution veritabanýna geçiliyor...';
USE distribution;
GO

-- 3. Replikasyon ajanlarý bilgisi
PRINT '3. MSdistribution_agents tablosundan ajan listesi:';
SELECT 
    id,
    name AS AgentName,
    profile_id,
    subscriber_id,
    publisher_id,
    publication
    -- publication_type kaldýrýldý
FROM MSdistribution_agents;
GO

-- 4. Ajan geçmiþi
PRINT '4. MSdistribution_history tablosundan ajan geçmiþi:';
SELECT 
    TOP 10
    agent_id,
    runstatus,       -- 2 = Baþarýlý, 3 = Hatalý
    time, 
    comments
FROM MSdistribution_history
ORDER BY time DESC;
GO

-- 5. Hatalar (MSrepl_errors)
PRINT '5. MSrepl_errors tablosu:';
SELECT 
    TOP 10
    id,              -- error_id yerine varsayýlan id kullanýldý
    error_code,
    error_text
FROM MSrepl_errors
ORDER BY time DESC;
GO

-- 6. Abonelik bilgileri (Yalnýzca yayýn tanýmlýysa çalýþýr)
PRINT '6. sp_helpsubscription (varsa yayýn tanýmý):';
BEGIN TRY
    EXEC sp_helpsubscription;
END TRY
BEGIN CATCH
    PRINT 'sp_helpsubscription çalýþtýrýlamadý. Yayýn tanýmý yapýlmamýþ olabilir.';
END CATCH;
GO

-- 7. Replikasyon izleme (opsiyonel - yalnýzca monitor kurulmuþsa çalýþýr)
PRINT '7. sp_replmonitorhelpsubscription (repl. monitor varsa):';
BEGIN TRY
    EXEC sp_replmonitorhelpsubscription;
END TRY
BEGIN CATCH
    PRINT 'sp_replmonitorhelpsubscription çalýþtýrýlamadý. Muhtemelen monitor tanýmlý deðil.';
END CATCH;
GO

-- 8. Always On bilgisi (yalnýzca aktifse çalýþýr)
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
    PRINT 'Always On görünmüyor ya da sistemde tanýmlý deðil.';
END CATCH;
GO

PRINT 'Monitoring tamamlandý.';
-- ============================================

