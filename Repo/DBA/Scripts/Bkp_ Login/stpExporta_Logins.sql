--DROP PROCEDURE dbo.stpExporta_Logins 
IF (OBJECT_ID('dbo.stpExporta_Logins') IS NULL) EXEC('CREATE PROCEDURE dbo.stpExporta_Logins AS SELECT 1')
GO
ALTER PROCEDURE dbo.stpExporta_Logins (
@Ds_Diretorio_Saida VARCHAR(500),
@Fl_Permissoes_Database BIT = 0,
@Fl_Arquivo_Unico BIT = 0
)
AS BEGIN
SET NOCOUNT ON
DECLARE
@Fl_Ole_Automation_Ativo BIT = (SELECT (CASE WHEN CAST([value] AS VARCHAR(MAX)) = '1' THEN 1 ELSE 0 END) FROM sys.configurations WHERE [name] = 'Ole Automation Procedures')
---------------------------------------------------------------------------------------
-- CRIAÇÃO DE TABELAS
---------------------------------------------------------------------------------------
IF (OBJECT_ID('tempdb..#Permissoes_Database') IS NOT NULL) DROP TABLE #Permissoes_Database
CREATE TABLE [dbo].[#Permissoes_Database] (
[database] [varchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AI NULL,
[username] [sys].[sysname] NOT NULL,
[schema] [sys].[sysname] NULL,
[object] [sys].[sysname] NULL,
[cmd_state] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AI NULL,
[permission_name] [varchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AI NULL,
[grant_command] [varchar] (MAX) COLLATE SQL_Latin1_General_CP1_CI_AI NULL,
[revoke_command] [varchar] (MAX) COLLATE SQL_Latin1_General_CP1_CI_AI NULL
)
IF (OBJECT_ID('tempdb..#Permissoes_Roles') IS NOT NULL) DROP TABLE #Permissoes_Roles
CREATE TABLE [dbo].[#Permissoes_Roles] (
[database] [varchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AI NULL,
[username] [sys].[sysname] NOT NULL,
[login_type] [sys].[sysname] NULL,
[role] [varchar] (MAX) COLLATE SQL_Latin1_General_CP1_CI_AI NULL,
[grant_command] [varchar] (MAX) COLLATE SQL_Latin1_General_CP1_CI_AI NULL,
[revoke_command] [varchar] (MAX) COLLATE SQL_Latin1_General_CP1_CI_AI NULL
)
IF (OBJECT_ID('tempdb..#Permissoes_Servidor') IS NOT NULL) DROP TABLE #Permissoes_Servidor
CREATE TABLE [dbo].[#Permissoes_Servidor] (
[username] [varchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AI NULL,
[type_desc] [sys].[sysname] NOT NULL,
[is_disabled] BIT NOT NULL,
[class_desc] varchar(40) NOT NULL,
[type] varchar(40) NOT NULL,
[permission_name] varchar(50) NOT NULL,
[state_desc] varchar(20) NOT NULL,
[grant_command] [varchar] (MAX) COLLATE SQL_Latin1_General_CP1_CI_AI NULL,
[revoke_command] [varchar] (MAX) COLLATE SQL_Latin1_General_CP1_CI_AI NULL
)
IF (OBJECT_ID('tempdb..#Permissoes_Roles_Servidor') IS NOT NULL) DROP TABLE #Permissoes_Roles_Servidor
CREATE TABLE [dbo].[#Permissoes_Roles_Servidor] (
[username] [varchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AI NULL,
[type_desc] [sys].[sysname] NOT NULL,
[is_disabled] BIT NOT NULL,
[role] [sys].[sysname] NOT NULL,
[grant_command] [varchar] (MAX) COLLATE SQL_Latin1_General_CP1_CI_AI NULL,
[revoke_command] [varchar] (MAX) COLLATE SQL_Latin1_General_CP1_CI_AI NULL
)
IF (OBJECT_ID('tempdb..#Cria_Usuarios') IS NOT NULL) DROP TABLE #Cria_Usuarios
CREATE TABLE [dbo].[#Cria_Usuarios] (
[database] [varchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AI NULL,
[username] [varchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AI NULL,
[type_desc] [sys].[sysname] NOT NULL,
[default_schema_name] [varchar] (128) NULL,
[authentication_type_desc] [varchar] (128) NULL,
[grant_command] [varchar] (MAX) COLLATE SQL_Latin1_General_CP1_CI_AI NULL,
[revoke_command] [varchar] (MAX) COLLATE SQL_Latin1_General_CP1_CI_AI NULL
)
IF (OBJECT_ID('tempdb..#Cria_Logins') IS NOT NULL) DROP TABLE #Cria_Logins
CREATE TABLE [dbo].[#Cria_Logins] (
[username] [varchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AI NULL,
[type_desc] [sys].[sysname] NOT NULL,
[default_database_name] [varchar] (128) NULL,
[default_language_name] [varchar] (128) NULL,
[is_fixed_role] [bit] NULL,
[is_disabled] [BIT] NULL,
[is_policy_checked] [BIT] NULL,
[is_expiration_checked] [BIT] NULL,
[grant_command] [varchar] (MAX) COLLATE SQL_Latin1_General_CP1_CI_AI NULL,
[revoke_command] [varchar] (MAX) COLLATE SQL_Latin1_General_CP1_CI_AI NULL
)
DECLARE
@Query_Permissao_Database VARCHAR(MAX) = '
SELECT DISTINCT
DB_NAME() AS [database],
E.[name] AS [username],
D.[name] AS [Schema],
C.[name] AS [Object],
(CASE WHEN A.state_desc = ''GRANT_WITH_GRANT_OPTION'' THEN ''GRANT'' ELSE A.state_desc END) AS cmd_state,
A.[permission_name],
(CASE 
WHEN C.[name] IS NULL THEN ''USE ['' + DB_NAME() + '']; '' + (CASE WHEN A.state_desc = ''GRANT_WITH_GRANT_OPTION'' THEN ''GRANT'' ELSE A.state_desc END) + '' '' + A.[permission_name] + '' TO ['' + E.[name] + ''];''
ELSE ''USE ['' + DB_NAME() + '']; '' + (CASE WHEN A.state_desc = ''GRANT_WITH_GRANT_OPTION'' THEN ''GRANT'' ELSE A.state_desc END) + '' '' + A.[permission_name] + '' ON ['' + DB_NAME() + ''].['' + d.[name] + ''].['' + c.[name] + ''] TO ['' + E.[name] + ''];''
END) COLLATE DATABASE_DEFAULT AS GrantCommand,
(CASE 
WHEN C.[name] IS NULL THEN ''USE ['' + DB_NAME() + '']; '' + ''REVOKE '' + A.[permission_name] + '' FROM ['' + E.[name] + ''];''
ELSE ''USE ['' + DB_NAME() + '']; '' + ''REVOKE '' + A.[permission_name] + '' ON ['' + DB_NAME() + ''].['' + d.[name] + ''].['' + c.[name] + ''] FROM ['' + E.[name] + ''];''
END) COLLATE DATABASE_DEFAULT AS RevokeCommand
FROM
sys.database_permissions                            A   WITH(NOLOCK)
LEFT JOIN sys.schemas                               B   WITH(NOLOCK) ON A.major_id = B.[schema_id]
LEFT JOIN sys.all_objects                           C   WITH(NOLOCK)
JOIN sys.schemas                                    D   WITH(NOLOCK) ON C.[schema_id] = D.[schema_id] ON A.major_id = C.[object_id]
JOIN sys.database_principals                        E   WITH(NOLOCK) ON A.grantee_principal_id = E.principal_id
WHERE
E.[name] NOT IN (
''dbo'',
''guest'',
''INFORMATION_SCHEMA'',
''sys''
)
AND E.[name] NOT LIKE ''NT SERVICE\%''
AND E.[name] NOT LIKE ''##MS_%'''
DECLARE @Query_Permissoes_Roles VARCHAR(MAX) = '
SELECT
DB_NAME() AS [database],
A.[name] AS [username],
A.[type_desc] AS LoginType,
C.[name] AS [role],
''EXEC ['' + DB_NAME() + ''].sys.sp_addrolemember '''''' + C.[name] + '''''', '''''' + a.[name] + '''''';'' AS GrantCommand,
''EXEC ['' + DB_NAME() + ''].sys.sp_droprolemember '''''' + C.[name] + '''''', '''''' + a.[name] + '''''';'' AS RevokeCommand
FROM 
sys.database_principals             A   WITH(NOLOCK)
JOIN sys.database_role_members	    B   WITH(NOLOCK) ON A.principal_id = B.member_principal_id
JOIN sys.database_principals        C   WITH(NOLOCK) ON B.role_principal_id = C.principal_id
WHERE
A.[name] NOT IN (
''TargetServersRole'',
''SQLAgentUserRole'',
''SQLAgentReaderRole'',
''SQLAgentOperatorRole'',
''DatabaseMailUserRole'',
''db_ssisadmin'',
''db_ssisltduser'',
''db_ssisoperator'',
''dc_operator'',
''dc_admin'',
''dc_proxy'',
''MS_DataCollectorInternalUser'',
''PolicyAdministratorRole'',
''ServerGroupAdministratorRole'',
''ServerGroupReaderRole'',
''##MS_PolicyEventProcessingLogin##'',
''##MS_PolicyTsqlExecutionLogin##'',
''##MS_AgentSigningCertificate##'',
''UtilityCMRReader'',
''UtilityIMRWriter'',
''UtilityIMRReader'',
''db_owner'',
''db_accessadmin'',
''db_securityadmin'',
''db_ddladmin'',
''db_backupoperator'',
''db_datareader'',
''db_datawriter'',
''db_denydatareader'',
''db_denydatawriter'',
''sa'',
''AUTORIDADE NT\SISTEMA'',
''NT AUTHORITY\SYSTEM'',
''dbo'',
''guest'',
''INFORMATION_SCHEMA'',
''sys''
)
AND A.[name] NOT LIKE ''NT SERVICE\%''
AND A.[name] NOT LIKE ''##MS_%'''
IF (@Fl_Permissoes_Database = 1)
BEGIN
DECLARE @Query_Alterada VARCHAR(MAX)
---------------------------------------------------------------------------------------
-- PERMISSÕES DE TODOS OS DATABASES
---------------------------------------------------------------------------------------
SET @Query_Alterada = '
USE [?];
' + @Query_Permissao_Database
INSERT INTO #Permissoes_Database
EXEC master.dbo.sp_MSforeachdb @Query_Alterada
-- Remove usuários padrão do SQL Server (Não removi no WHERE por causa do limite de 2k caracteres do sp_MSforeachdb)
DELETE FROM #Permissoes_Database
WHERE username IN (
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
'NT AUTHORITY\SYSTEM'
)
OR (username = 'public' AND ([schema] = 'sys' OR [database] IN ('msdb', 'master')))
OR ([database] IN ('tempdb', 'model'))
---------------------------------------------------------------------------------------
-- PERMISSÕES EM ROLES DE TODOS OS DATABASES
---------------------------------------------------------------------------------------
SET @Query_Alterada = '
USE [?];
' + @Query_Permissoes_Roles
INSERT INTO #Permissoes_Roles
EXEC master.dbo.sp_MSforeachdb @Query_Alterada
END
---------------------------------------------------------------------------------------
-- CRIAÇÃO DE LOGINS
---------------------------------------------------------------------------------------
INSERT INTO #Cria_Logins
SELECT 
A.[name] AS username,
A.[type_desc],
A.default_database_name,
A.default_language_name,
A.is_fixed_role,
A.is_disabled,
B.is_policy_checked,
B.is_expiration_checked,
'USE [master]; CREATE LOGIN [' + A.[name] + ']' + 
(CASE WHEN A.[type_desc] = 'SQL_LOGIN' THEN ' WITH PASSWORD = ' + COALESCE(UPPER(sys.fn_varbintohexstr(CONVERT(VARBINARY(MAX), password_hash))), '') + ' HASHED,' ELSE ' FROM WINDOWS WITH' END) + 
' DEFAULT_DATABASE=[' + A.default_database_name + ']' +
(CASE WHEN A.default_language_name IS NOT NULL THEN ', DEFAULT_LANGUAGE=[' + A.default_language_name + ']' ELSE '' END) +
(CASE WHEN B.is_policy_checked IS NOT NULL THEN ', CHECK_POLICY=ON' ELSE '' END) +
(CASE WHEN B.is_expiration_checked IS NOT NULL THEN ', CHECK_EXPIRATION=ON' ELSE '' END) +
(CASE WHEN A.is_disabled = 1 THEN '; ALTER LOGIN [' + A.[name] + '] DISABLE' ELSE '' END) + ';'
AS GrantCommand,
'USE [master]; DROP LOGIN [' + A.[name] + '];' AS RevokeCommand
FROM
sys.server_principals               A   WITH(NOLOCK)
LEFT JOIN sys.sql_logins	    B	WITH(NOLOCK)	ON	A.[name] = B.[name]
WHERE
A.is_fixed_role = 0 -- Não precisa recriar roles padrão do SQL Server
AND A.principal_id > 200 -- Não trazer os usuários padrão do SQL Server
AND A.[name] NOT IN (
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
'NT AUTHORITY\SYSTEM'
)
AND A.[name] NOT LIKE 'NT SERVICE\%'
AND A.[name] NOT LIKE '##MS_%'
---------------------------------------------------------------------------------------
-- PERMISSÕES NA INSTÂNCIA
---------------------------------------------------------------------------------------
INSERT INTO #Permissoes_Servidor
SELECT DISTINCT
A.[name],
A.[type_desc],
A.is_disabled,
B.class_desc,
B.[type],
B.[permission_name],
B.state_desc,
'USE [master]; ' + B.state_desc + ' ' + B.[permission_name] + ' TO [' + A.[name] COLLATE SQL_Latin1_General_CP1_CI_AI + '];' AS GrantCommand,
'USE [master]; REVOKE ' + B.[permission_name] + ' FROM [' + A.[name] COLLATE SQL_Latin1_General_CP1_CI_AI + '];' AS RevokeCommand
FROM
sys.server_principals               A   WITH(NOLOCK)
JOIN sys.server_permissions         B   WITH(NOLOCK)    ON  A.principal_id = B.grantee_principal_id
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
'NT AUTHORITY\SYSTEM'
)
AND A.[name] NOT LIKE 'NT SERVICE\%'
AND A.[name] NOT LIKE '##MS_%'
---------------------------------------------------------------------------------------
-- PERMISSÕES EM SERVER ROLES INSTÂNCIA
---------------------------------------------------------------------------------------
INSERT INTO #Permissoes_Roles_Servidor
SELECT
A.[name] AS username,
A.[type_desc],
A.is_disabled,
C.[name] AS [role],
'EXEC [master].[dbo].sp_addsrvrolemember ''' + A.[name] + ''', ''' + C.[name] + ''';' AS GrantCommand,
'EXEC [master].[dbo].sp_dropsrvrolemember ''' + A.[name] + ''', ''' + C.[name] + ''';' AS RevokeCommand
FROM
sys.server_principals               A   WITH(NOLOCK)
JOIN sys.server_role_members        B   WITH(NOLOCK)    ON  A.principal_id = B.member_principal_id
JOIN sys.server_principals          C   WITH(NOLOCK)    ON  B.role_principal_id = C.principal_id
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
'NT AUTHORITY\SYSTEM'
)
AND A.[name] NOT LIKE 'NT SERVICE\%'
AND A.[name] NOT LIKE '##MS_%'
---------------------------------------------------------------------------------------
-- CRIA OS USUÁRIOS DE DATABASE
---------------------------------------------------------------------------------------
DECLARE @Comando VARCHAR(MAX) = ''
IF (@Fl_Permissoes_Database = 1)
BEGIN
DECLARE @Query_Cria_Usuarios VARCHAR(MAX) = '
USE [?];
SELECT 
DB_NAME() AS [database],
A.[name] AS username,
A.[type_desc],
A.default_schema_name,
A.authentication_type_desc,
''USE ['' + DB_NAME() + '']; '' + (CASE WHEN A.[type_desc] LIKE ''%ROLE%'' THEN ''CREATE ROLE ['' + A.[name] + ''];'' ELSE ''CREATE USER ['' + A.[name] + '']'' + (CASE WHEN A.[type_desc] = ''SQL_USER'' AND B.[name] IS NOT NULL THEN '' FOR LOGIN ['' + B.[name] + '']'' WHEN A.[type_desc] = ''SQL_USER'' THEN '''' ELSE '' FOR LOGIN ['' + A.[name] + '']'' END) + '' WITH DEFAULT_SCHEMA=['' + ISNULL(a.default_schema_name, ''dbo'') + ''];'' END) AS GrantCommand,
''USE ['' + DB_NAME() + '']; DROP '' + (CASE WHEN A.[type_desc] LIKE ''%ROLE%'' THEN ''ROLE'' ELSE ''USER'' END) + '' ['' + A.[name] + ''];'' AS RevokeCommand
FROM
sys.database_principals A WITH(NOLOCK)
LEFT JOIN sys.sql_logins B WITH(NOLOCK) ON A.[sid] = B.[sid]
WHERE
A.[name] NOT IN (
''TargetServersRole'',
''SQLAgentUserRole'',
''SQLAgentReaderRole'',
''SQLAgentOperatorRole'',
''DatabaseMailUserRole'',
''db_ssisadmin'',
''db_ssisltduser'',
''db_ssisoperator'',
''dc_operator'',
''dc_admin'',
''dc_proxy'',
''MS_DataCollectorInternalUser'',
''PolicyAdministratorRole'',
''ServerGroupAdministratorRole'',
''ServerGroupReaderRole'',
''##MS_PolicyEventProcessingLogin##'',
''##MS_PolicyTsqlExecutionLogin##'',
''##MS_AgentSigningCertificate##'',
''UtilityCMRReader'',
''UtilityIMRWriter'',
''UtilityIMRReader'',
''db_owner'',
''db_accessadmin'',
''db_securityadmin'',
''db_ddladmin'',
''db_backupoperator'',
''db_datareader'',
''db_datawriter'',
''db_denydatareader'',
''db_denydatawriter'',
''sa'',
''AUTORIDADE NT\SISTEMA'',
''NT AUTHORITY\SYSTEM'',
''dbo'',
''guest'',
''INFORMATION_SCHEMA'',
''sys'',
''public''
)'
INSERT INTO #Cria_Usuarios
EXEC master.dbo.sp_MSforeachdb @Query_Cria_Usuarios
END
---------------------------------------------------------------------------------------
-- GERA OS ARQUIVOS
---------------------------------------------------------------------------------------
-- Ativa o OLE Automation (caso não esteja ativo)
IF (@Fl_Ole_Automation_Ativo = 0)
BEGIN
EXEC sp_configure 'show advanced options', 1
RECONFIGURE;
EXEC sp_configure 'Ole Automation Procedures', 1;
RECONFIGURE;
END
DECLARE
@Nm_Arquivo VARCHAR(1000),
@ConteudoArquivo VARCHAR(MAX) = ''
IF (@Fl_Arquivo_Unico = 1)
BEGIN
SET @Nm_Arquivo = @Ds_Diretorio_Saida + 'sql_logins_' + @@SERVICENAME +'.sql'	

 
SET @ConteudoArquivo += '-- CRIAÇÃO DOS LOGINS
'
SELECT TOP 9999999999 @ConteudoArquivo += grant_command + '
'
FROM #Cria_Logins
ORDER BY username
SET @ConteudoArquivo += '
-- PERMISSÕES NA INSTÂNCIA
'
SELECT TOP 9999999999 @ConteudoArquivo += grant_command + '
'
FROM #Permissoes_Servidor
ORDER BY username
SET @ConteudoArquivo += '
-- PERMISSÕES NAS ROLES DA INSTÂNCIA
'
SELECT TOP 9999999999 @ConteudoArquivo += grant_command + '
'
FROM #Permissoes_Roles_Servidor
ORDER BY username
IF (@Fl_Permissoes_Database = 1)
BEGIN
SET @ConteudoArquivo += '
-- CRIA USUÁRIOS NOS DATABASES' + '
'
SELECT TOP 9999999999 @ConteudoArquivo += grant_command + '
'
FROM #Cria_Usuarios
ORDER BY [database], username
SET @ConteudoArquivo += '
-- PERMISSÕES NOS DATABASES
'
SELECT TOP 9999999999 @ConteudoArquivo += grant_command + '
'
FROM #Permissoes_Database
ORDER BY [database], [username]
SET @ConteudoArquivo += '
-- PERMISSÕES NAS ROLES DOS DATABASES' + '
'
SELECT TOP 9999999999 @ConteudoArquivo += grant_command + '
'
FROM #Permissoes_Roles
ORDER BY [database], [role], [username]
END
EXEC dbo.stpEscreve_Arquivo_FSO
@String = @ConteudoArquivo, -- varchar(max)
@Ds_Arquivo = @Nm_Arquivo -- varchar(1501)
END
ELSE BEGIN
IF (OBJECT_ID('tempdb..#Permissoes_por_Usuario') IS NOT NULL) DROP TABLE #Permissoes_por_Usuario
CREATE TABLE #Permissoes_por_Usuario (
ranking INT IDENTITY(1, 1) NOT NULL,
username VARCHAR(128) NOT NULL
)
INSERT INTO #Permissoes_por_Usuario
SELECT DISTINCT username COLLATE SQL_Latin1_General_CP1_CI_AI
FROM #Cria_Logins
UNION
SELECT DISTINCT username COLLATE SQL_Latin1_General_CP1_CI_AI
FROM #Cria_Usuarios
UNION
SELECT DISTINCT username COLLATE SQL_Latin1_General_CP1_CI_AI
FROM #Permissoes_Database
UNION
SELECT DISTINCT username COLLATE SQL_Latin1_General_CP1_CI_AI
FROM #Permissoes_Roles
DECLARE
@Contador INT = 1,
@Total INT = (SELECT COUNT(*) FROM #Permissoes_por_Usuario),
@Usuario VARCHAR(128)
WHILE(@Contador <= @Total)
BEGIN
SELECT @Usuario = username
FROM #Permissoes_por_Usuario
WHERE ranking = @Contador
SET @Nm_Arquivo = @Ds_Diretorio_Saida + REPLACE(@@SERVERNAME, '\', '-') + '_' + REPLACE(@Usuario, '\', '-') + '.sql'
SET @ConteudoArquivo = '-- CRIAÇÃO DOS LOGINS
'
SELECT TOP 9999999999 @ConteudoArquivo += grant_command + '
'
FROM #Cria_Logins
WHERE username = @Usuario
ORDER BY username
SET @ConteudoArquivo += '
-- PERMISSÕES NA INSTÂNCIA
'
SELECT TOP 9999999999 @ConteudoArquivo += grant_command + '
'
FROM #Permissoes_Servidor
WHERE username = @Usuario
ORDER BY username
SET @ConteudoArquivo += '
-- PERMISSÕES NAS ROLES DA INSTÂNCIA
'
SELECT TOP 9999999999 @ConteudoArquivo += grant_command + '
'
FROM #Permissoes_Roles_Servidor
WHERE username = @Usuario
ORDER BY username
IF (@Fl_Permissoes_Database = 1)
BEGIN
SET @ConteudoArquivo += '
-- CRIA USUÁRIOS NOS DATABASES
'
SELECT TOP 9999999999 @ConteudoArquivo += grant_command + '
'
FROM #Cria_Usuarios
WHERE username = @Usuario
ORDER BY [database], username
SET @ConteudoArquivo += '
-- PERMISSÕES NOS DATABASES
'
SELECT TOP 9999999999 @ConteudoArquivo += grant_command + '
'
FROM #Permissoes_Database
WHERE username = @Usuario
ORDER BY username
SET @ConteudoArquivo += '
-- PERMISSÕES NAS ROLES DOS DATABASES
'
SELECT TOP 9999999999 @ConteudoArquivo += grant_command + '
'
FROM #Permissoes_Roles
WHERE username = @Usuario
ORDER BY username
END
EXEC dbo.stpEscreve_Arquivo_FSO
@String = @ConteudoArquivo, -- varchar(max)
@Ds_Arquivo = @Nm_Arquivo -- varchar(1501)
SET @Contador += 1
END
END
-- Desativa o OLE Automation (Caso esteja desativado antes de executar a SP)
IF (@Fl_Ole_Automation_Ativo = 0)
BEGIN
EXEC sp_configure 'Ole Automation Procedures', 0;
RECONFIGURE;
END
END