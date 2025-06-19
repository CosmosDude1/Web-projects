USE AdventureWorks2019;
GO

CREATE TRIGGER TR_TrackSchemaChanges
ON DATABASE
FOR DDL_DATABASE_LEVEL_EVENTS
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @EventData XML = EVENTDATA();
    
    INSERT INTO SchemaChangeLog (
        EventType,
        ObjectName,
        ObjectType,
        SQLCommand,
        LoginName
    )
    VALUES (
        @EventData.value('(/EVENT_INSTANCE/EventType)[1]', 'nvarchar(100)'),
        @EventData.value('(/EVENT_INSTANCE/ObjectName)[1]', 'nvarchar(100)'),
        @EventData.value('(/EVENT_INSTANCE/ObjectType)[1]', 'nvarchar(100)'),
        @EventData.value('(/EVENT_INSTANCE/TSQLCommand/CommandText)[1]', 'nvarchar(max)'),
        @EventData.value('(/EVENT_INSTANCE/LoginName)[1]', 'nvarchar(100)')
    );
END;
GO