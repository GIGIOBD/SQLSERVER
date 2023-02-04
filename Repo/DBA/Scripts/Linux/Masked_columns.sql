/* Mascarar coluna */
if not exists (
SELECT s.name,c.name, t.name as table_name, c.is_masked, c.masking_function  
FROM sys.masked_columns AS c  
JOIN sys.tables AS t   
    ON c.[object_id] = t.[object_id]  
join sys.schemas s
on s.schema_id = t.schema_id
WHERE is_masked = 1
and t.name = 't_pessoas' and s.name = 'cad')
begin
	alter table cad.t_pessoas
	alter column nm_pessoa add masked with(function='partial(0,"xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",0)')
end

/* verificar colunas mascaradas */
SELECT s.name,c.name, t.name as table_name, c.is_masked, c.masking_function  
FROM sys.masked_columns AS c  
JOIN sys.tables AS t   
    ON c.[object_id] = t.[object_id]  
join sys.schemas s
on s.schema_id = t.schema_id
WHERE is_masked = 1; 

/* Cria usuario para testar mask */
USE [master]
GO
if not exists (select 1 from sys.syslogins where name = 'usuario')
begin
	CREATE LOGIN [usuario] WITH PASSWORD=N'usuario', DEFAULT_DATABASE=[master], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
end

USE [habitacional_erp_demo]
GO

if not exists (select 1 from sys.sysusers where name = 'usuario')
begin
	CREATE USER [usuario] FOR LOGIN [usuario]
end

USE [habitacional_erp_demo]
GO
ALTER ROLE [db_datareader] ADD  MEMBER [usuario]
GO

execute as user = 'usuario'

	select nm_pessoa, * from cad.t_pessoas
revert;
