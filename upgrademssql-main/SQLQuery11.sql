USE AdventureWorks2019;
GO


CREATE PROCEDURE dbo.GetDatabaseVersionHistory
AS
BEGIN
    SELECT 
        VersionID,
        VersionNumber,
        AppliedDate,
        AppliedBy,
        ScriptName,
        Description
    FROM DatabaseVersionControl
    ORDER BY VersionID DESC;
END;
GO


CREATE PROCEDURE dbo.GetSchemaChangeHistory
AS
BEGIN
    SELECT 
        LogID,
        EventType,
        ObjectName,
        ObjectType,
        SQLCommand,
        LoginName,
        ChangeDate
    FROM SchemaChangeLog
    ORDER BY LogID DESC;
END;
GO


CREATE PROCEDURE dbo.RollbackToVersion
    @TargetVersion VARCHAR(50)
AS
BEGIN
    BEGIN TRANSACTION;
    BEGIN TRY
        
        IF NOT EXISTS (SELECT 1 FROM DatabaseVersionControl WHERE VersionNumber = @TargetVersion)
        BEGIN
            RAISERROR('Target version does not exist!', 16, 1);
            RETURN;
        END

        
        IF @TargetVersion = '1.1.0' AND EXISTS (
            SELECT 1 FROM DatabaseVersionControl WHERE VersionNumber = '1.2.0'
        )
        BEGIN
            
            IF OBJECT_ID('HumanResources.EmployeeTraining', 'U') IS NOT NULL
                DROP TABLE HumanResources.EmployeeTraining;

            
            DELETE FROM DatabaseVersionControl
            WHERE VersionNumber = '1.2.0';
        END

        
        IF @TargetVersion = '1.0.0' AND EXISTS (
            SELECT 1 FROM DatabaseVersionControl WHERE VersionNumber = '1.1.0'
        )
        BEGIN
            
            IF COL_LENGTH('HumanResources.Employee', 'LastPerformanceReviewDate') IS NOT NULL
                ALTER TABLE HumanResources.Employee
                DROP COLUMN LastPerformanceReviewDate;

            
            DELETE FROM DatabaseVersionControl
            WHERE VersionNumber = '1.1.0';
        END

        
        INSERT INTO SchemaChangeLog 
            (EventType, ObjectName, ObjectType, SQLCommand, LoginName)
        VALUES 
            ('ROLLBACK',
             'Database',
             'VERSION',
             'Rolled back to version ' + @TargetVersion,
             SYSTEM_USER);

        COMMIT TRANSACTION;
        PRINT 'Successfully rolled back to version ' + @TargetVersion;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH;
END;
GO
