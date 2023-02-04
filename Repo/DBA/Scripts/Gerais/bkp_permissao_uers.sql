

SELECT
DB_NAME() AS [database],
A.[name] AS [username],
A.[type_desc] AS LoginType,
C.[name] AS [role],
'EXEC [' + DB_NAME() + '].sys.sp_addrolemember ''' + C.[name] + ''', ''' + a.[name] + ''';' AS GrantCommand,
'EXEC [' + DB_NAME() + '].sys.sp_droprolemember ''' + C.[name] + ''', ''' + a.[name] + ''';' AS RevokeCommand
FROM 
sys.database_principals             A   WITH(NOLOCK)
JOIN sys.database_role_members	    B   WITH(NOLOCK) ON A.principal_id = B.member_principal_id
JOIN sys.database_principals        C   WITH(NOLOCK) ON B.role_principal_id = C.principal_id
WHERE
A.[name] NOT IN (
'TargetServersRole',
'SQLAgentUserRole',
'SQLAgentReaderRole',
'SQLAgentOperatorRole',
'DatabaseMailUserRole',
'db_ssisadmin',
'db_ssisltduser',
'db_ssisoperator',
'dc_operator',
'dc_admin',
'dc_proxy',
'MS_DataCollectorInternalUser',
'PolicyAdministratorRole',
'ServerGroupAdministratorRole',
'ServerGroupReaderRole',
'##MS_PolicyEventProcessingLogin##',
'##MS_PolicyTsqlExecutionLogin##',
'##MS_AgentSigningCertificate##',
'UtilityCMRReader',
'UtilityIMRWriter',
'UtilityIMRReader',
'db_owner',
'db_accessadmin',
'db_securityadmin',
'db_ddladmin',
'db_backupoperator',
'db_datareader',
'db_datawriter',
'db_denydatareader',
'db_denydatawriter',
'sa',
'AUTORIDADE NT\SISTEMA',
'NT AUTHORITY\SYSTEM',
'dbo',
'guest',
'INFORMATION_SCHEMA',
'sys'
)
AND A.[name] NOT LIKE 'NT SERVICE\%'
AND A.[name] NOT LIKE '##MS_%'

return
SELECT DISTINCT
DB_NAME() AS [database],
E.[name] AS [username],
D.[name] AS [Schema],
C.[name] AS [Object],
(CASE WHEN A.state_desc = 'GRANT_WITH_GRANT_OPTION' THEN 'GRANT' ELSE A.state_desc END) AS cmd_state,
A.[permission_name],
(CASE 
WHEN C.[name] IS NULL THEN 'USE [' + DB_NAME() + ']; ' + (CASE WHEN A.state_desc = 'GRANT_WITH_GRANT_OPTION' THEN 'GRANT' ELSE A.state_desc END) + ' ' + A.[permission_name] + ' TO [' + E.[name] + '];'
ELSE 'USE [' + DB_NAME() + ']; ' + (CASE WHEN A.state_desc = 'GRANT_WITH_GRANT_OPTION' THEN 'GRANT' ELSE A.state_desc END) + ' ' + A.[permission_name] + ' ON [' + DB_NAME() + '].[' + d.[name] + '].[' + c.[name] + '] TO [' + E.[name] + '];'
END) COLLATE DATABASE_DEFAULT AS GrantCommand,
(CASE 
WHEN C.[name] IS NULL THEN 'USE [' + DB_NAME() + ']; ' + 'REVOKE ' + A.[permission_name] + ' FROM [' + E.[name] + '];'
ELSE 'USE [' + DB_NAME() + ']; ' + 'REVOKE ' + A.[permission_name] + ' ON [' + DB_NAME() + '].[' + d.[name] + '].[' + c.[name] + '] FROM [' + E.[name] + '];'
END) COLLATE DATABASE_DEFAULT AS RevokeCommand
FROM
sys.database_permissions                            A   WITH(NOLOCK)
LEFT JOIN sys.schemas                               B   WITH(NOLOCK) ON A.major_id = B.[schema_id]
LEFT JOIN sys.all_objects                           C   WITH(NOLOCK)
JOIN sys.schemas                                    D   WITH(NOLOCK) ON C.[schema_id] = D.[schema_id] ON A.major_id = C.[object_id]
JOIN sys.database_principals                        E   WITH(NOLOCK) ON A.grantee_principal_id = E.principal_id
WHERE
E.[name] NOT IN (
'dbo',
'guest',
'INFORMATION_SCHEMA',
'sys'
)
AND E.[name] NOT LIKE 'NT SERVICE\%'
AND E.[name] NOT LIKE '##MS_%'
and E.[name] not like 'public'

