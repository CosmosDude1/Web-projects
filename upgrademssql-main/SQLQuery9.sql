USE AdventureWorks2019;
GO

INSERT INTO DatabaseVersionControl (VersionNumber, AppliedBy, ScriptName, Description)
VALUES ('1.0.0', SYSTEM_USER, 'InitialSetup.sql', 'Initial version control setup');
GO