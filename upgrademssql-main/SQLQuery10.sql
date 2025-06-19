USE AdventureWorks2019;
GO


IF NOT EXISTS (SELECT 1 FROM DatabaseVersionControl WHERE VersionNumber = '1.1.0')
BEGIN
    ALTER TABLE HumanResources.Employee
    ADD LastPerformanceReviewDate DATE NULL;
END
GO


BEGIN TRANSACTION;
BEGIN TRY
    IF NOT EXISTS (SELECT 1 FROM DatabaseVersionControl WHERE VersionNumber = '1.1.0')
    BEGIN
        
        UPDATE HumanResources.Employee
        SET LastPerformanceReviewDate = DATEADD(month, -6, GETDATE());

        
        INSERT INTO DatabaseVersionControl 
            (VersionNumber, AppliedBy, ScriptName, Description)
        VALUES 
            ('1.1.0', 
             SYSTEM_USER, 
             'Add_PerformanceReview_Column.sql',
             'Added LastPerformanceReviewDate column to Employee table');

        PRINT 'Database successfully upgraded to version 1.1.0';
    END
    
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
    
    DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
    DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
    DECLARE @ErrorState INT = ERROR_STATE();
    
    
    INSERT INTO SchemaChangeLog 
        (EventType, ObjectName, ObjectType, SQLCommand, LoginName)
    VALUES 
        ('ERROR',
         'HumanResources.Employee',
         'TABLE',
         @ErrorMessage,
         SYSTEM_USER);
    
    RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
END CATCH;
GO
