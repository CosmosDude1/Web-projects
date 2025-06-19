
IF EXISTS (SELECT 1 FROM msdb.dbo.sysmail_profileaccount pa
           INNER JOIN msdb.dbo.sysmail_profile p ON pa.profile_id = p.profile_id
           INNER JOIN msdb.dbo.sysmail_account a ON pa.account_id = a.account_id
           WHERE p.name = 'DBAdminMailProfile' AND a.name = 'SMTPAccount')
BEGIN
    EXEC msdb.dbo.sysmail_delete_profileaccount_sp @profile_name = 'DBAdminMailProfile', @account_name = 'SMTPAccount';
END


IF EXISTS (SELECT 1 FROM msdb.dbo.sysmail_account WHERE name = 'SMTPAccount')
BEGIN
    EXEC msdb.dbo.sysmail_delete_account_sp @account_name = 'SMTPAccount';
END

IF EXISTS (SELECT 1 FROM msdb.dbo.sysmail_profile WHERE name = 'DBAdminMailProfile')
BEGIN
    EXEC msdb.dbo.sysmail_delete_profile_sp @profile_name = 'DBAdminMailProfile';
END
GO