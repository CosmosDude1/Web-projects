-- Erişim Yönetimi Scripti
-- AdventureWorks2019 için güvenlik ve erişim yönetimi

-- 1. Mevcut Rolleri ve Üyeleri Listele
SELECT 
    r.name AS RoleName,
    r.type_desc AS RoleType,
    m.name AS MemberName,
    m.type_desc AS MemberType
FROM sys.database_role_members rm
INNER JOIN sys.database_principals r ON rm.role_principal_id = r.principal_id
INNER JOIN sys.database_principals m ON rm.member_principal_id = m.principal_id
WHERE r.type IN ('R', 'G')
ORDER BY r.name, m.name;

-- 2. Kullanıcı İzinlerini Listele
SELECT 
    dp.name AS DatabasePrincipal,
    dp.type_desc AS PrincipalType,
    o.name AS ObjectName,
    o.type_desc AS ObjectType,
    p.permission_name AS Permission,
    p.state_desc AS PermissionState
FROM sys.database_permissions p
INNER JOIN sys.database_principals dp ON p.grantee_principal_id = dp.principal_id
LEFT JOIN sys.objects o ON p.major_id = o.object_id
WHERE dp.type IN ('S', 'U', 'G')
ORDER BY dp.name, o.name, p.permission_name;

-- 3. Yeni Rol Oluşturma ve Yetkilendirme Örneği
-- ReadOnly rolü oluştur
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'AdventureWorks_ReadOnly')
BEGIN
    CREATE ROLE AdventureWorks_ReadOnly;
END

-- Rol için SELECT izinlerini ver
GRANT SELECT ON SCHEMA::Sales TO AdventureWorks_ReadOnly;
GRANT SELECT ON SCHEMA::Production TO AdventureWorks_ReadOnly;
GRANT SELECT ON SCHEMA::Person TO AdventureWorks_ReadOnly;

-- 4. Örnek Kullanıcı Oluşturma
-- ReadOnly kullanıcısı oluştur
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'AdventureWorks_ReadOnly_User')
BEGIN
    CREATE USER AdventureWorks_ReadOnly_User WITHOUT LOGIN;
END

-- Kullanıcıyı role ekle
IF NOT EXISTS (
    SELECT * FROM sys.database_role_members rm
    INNER JOIN sys.database_principals r ON rm.role_principal_id = r.principal_id
    INNER JOIN sys.database_principals m ON rm.member_principal_id = m.principal_id
    WHERE r.name = 'AdventureWorks_ReadOnly' AND m.name = 'AdventureWorks_ReadOnly_User'
)
BEGIN
    ALTER ROLE AdventureWorks_ReadOnly ADD MEMBER AdventureWorks_ReadOnly_User;
END

-- 5. Güvenlik Ayarlarını Kontrol Et
SELECT 
    dp.name AS DatabasePrincipal,
    dp.type_desc AS PrincipalType,
    CASE WHEN rm.role_principal_id IS NOT NULL THEN 'Yes' ELSE 'No' END AS IsInReadOnlyRole
FROM sys.database_principals dp
LEFT JOIN sys.database_role_members rm ON dp.principal_id = rm.member_principal_id
LEFT JOIN sys.database_principals r ON rm.role_principal_id = r.principal_id
WHERE dp.type IN ('S', 'U')
    AND (r.name = 'AdventureWorks_ReadOnly' OR r.name IS NULL)
ORDER BY dp.name;

-- 6. Şema İzinlerini Listele
SELECT 
    s.name AS SchemaName,
    dp.name AS DatabasePrincipal,
    dp.type_desc AS PrincipalType,
    p.permission_name AS Permission,
    p.state_desc AS PermissionState
FROM sys.database_permissions p
INNER JOIN sys.database_principals dp ON p.grantee_principal_id = dp.principal_id
INNER JOIN sys.schemas s ON p.major_id = s.schema_id
WHERE p.class = 3 -- SCHEMA
ORDER BY s.name, dp.name, p.permission_name; 