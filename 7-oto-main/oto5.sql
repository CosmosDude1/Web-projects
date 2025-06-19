USE msdb;
GO

EXEC dbo.sp_update_job
    @job_name = N'Weekly Full Backup AdventureWorks2019',
    @notify_level_email = 2, -- 2 
    @notify_email_operator_name = N'DBAdmin';
GO