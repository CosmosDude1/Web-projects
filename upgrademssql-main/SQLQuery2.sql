USE AdventureWorks2019;
GO

-- Versiyon takip tablosu
CREATE TABLE DatabaseVersionControl
(
    VersionID INT IDENTITY(1,1) PRIMARY KEY,
    VersionNumber VARCHAR(50) NOT NULL,
    AppliedDate DATETIME DEFAULT GETDATE(),
    AppliedBy NVARCHAR(100),
    ScriptName NVARCHAR(255),
    Description NVARCHAR(MAX)
);
GO

-- Þema deðiþikliklerini izlemek için log tablosu
CREATE TABLE SchemaChangeLog
(
    LogID INT IDENTITY(1,1) PRIMARY KEY,
    EventType NVARCHAR(100),
    ObjectName NVARCHAR(100),
    ObjectType NVARCHAR(100),
    SQLCommand NVARCHAR(MAX),
    LoginName NVARCHAR(100),
    ChangeDate DATETIME DEFAULT GETDATE()
);
GO