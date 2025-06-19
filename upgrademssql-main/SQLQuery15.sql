USE AdventureWorks2019;
GO

BEGIN TRANSACTION;
BEGIN TRY
    
    IF NOT EXISTS (SELECT 1 FROM DatabaseVersionControl WHERE VersionNumber = '1.2.0')
    BEGIN
        
        CREATE TABLE HumanResources.EmployeeTraining
        (
            TrainingID INT IDENTITY(1,1) PRIMARY KEY,
            BusinessEntityID INT NOT NULL,
            TrainingName NVARCHAR(100) NOT NULL,
            TrainingProvider NVARCHAR(100) NULL,
            StartDate DATE NOT NULL,
            CompletionDate DATE NOT NULL,
            CertificationNumber NVARCHAR(50) NULL,
            CertificationExpiry DATE NULL,
            TrainingCost DECIMAL(10,2) NULL,
            Comments NVARCHAR(500) NULL,
            CONSTRAINT FK_EmployeeTraining_Employee FOREIGN KEY (BusinessEntityID)
                REFERENCES HumanResources.Employee (BusinessEntityID)
        );

        
        INSERT INTO HumanResources.EmployeeTraining 
            (BusinessEntityID, TrainingName, TrainingProvider, StartDate, CompletionDate)
        SELECT 
            BusinessEntityID,
            'SQL Server Administration',
            'Microsoft Learning',
            DATEADD(month, -3, GETDATE()),
            DATEADD(month, -2, GETDATE())
        FROM HumanResources.Employee
        WHERE JobTitle LIKE '%Database%';

        
        INSERT INTO DatabaseVersionControl 
            (VersionNumber, AppliedBy, ScriptName, Description)
        VALUES 
            ('1.2.0', 
             SYSTEM_USER, 
             'Add_EmployeeTraining_Table.sql',
             'Added new table for tracking employee training records with sample data');

        PRINT 'Database successfully upgraded to version 1.2.0';
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
         'HumanResources.EmployeeTraining',
         'TABLE',
         @ErrorMessage,
         SYSTEM_USER);
    
    RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
END CATCH;
GO