/*
Utilização dos índices
Com a query abaixo, você poderá identificar se os índices criados estão sendo utilizados da forma correta. 
Também é útil para identificar índices que podem ser bons candidatos para serem excluídos, pois estão apenas 
ocupando espaço e ainda te ajuda a identificar tabelas que são muito acessadas e as que não são acessadas há bastante tempo.
*/

declare 
	@table		varchar(500) = 'corp_parc_movto',
	@schema		char(4)		 = 'dbo.'

SELECT
    D.[name] + '.' + C.[name] AS ObjectName,
    A.[name] AS IndexName,
    (CASE WHEN A.is_unique = 1 THEN 'UNIQUE ' ELSE '' END) + A.[type_desc] AS IndexType,
    MAX(B.last_user_seek) AS last_user_seek,
    MAX(COALESCE(B.last_user_seek, B.last_user_scan)) AS last_read,
    SUM(B.user_seeks) AS User_Seeks,
    SUM(B.user_scans) AS User_Scans,
    SUM(B.user_seeks) + SUM(B.user_scans) AS User_Reads,
    SUM(B.user_lookups) AS User_Lookups,
    SUM(B.user_updates) AS User_Updates,
    SUM(E.[rows]) AS [row_count],
    CAST(ROUND(((SUM(F.total_pages) * 8) / 1024.00), 2) AS NUMERIC(36, 2)) AS [size_mb],
    CAST(ROUND(((SUM(F.used_pages) * 8) / 1024.00), 2) AS NUMERIC(36, 2)) AS [used_mb], 
    CAST(ROUND(((SUM(F.total_pages) - SUM(F.used_pages)) * 8) / 1024.00, 2) AS NUMERIC(36, 2)) AS [unused_mb]
FROM
    sys.indexes A
    LEFT JOIN sys.dm_db_index_usage_stats B ON A.[object_id] = B.[object_id] AND A.index_id = B.index_id AND B.database_id = DB_ID()
    JOIN sys.objects C ON A.[object_id] = C.[object_id]
    JOIN sys.schemas D ON C.[schema_id] = D.[schema_id]
    JOIN sys.partitions E ON A.[object_id] = E.[object_id] AND A.index_id = E.index_id
    JOIN sys.allocation_units F ON E.[partition_id] = F.container_id
WHERE
    C.is_ms_shipped = 0
	and c.name like @table
GROUP BY
    D.[name] + '.' + C.[name],
    A.[name],
    (CASE WHEN A.is_unique = 1 THEN 'UNIQUE ' ELSE '' END) + A.[type_desc]
ORDER BY
    1, 2
	
set @table = replace(@table,'%','')
	--sp_consulta 'idx_corp_ress_item_modalidade_movto(dt_movimento)'
	--idx_corp_ress_item_modalidade_movto(cd_evento&dt_movimento)
	--idx_corp_ress_item_modalidade_movto(cd_evento)
	--idx_corp_ress_item_modalidade_movto(dt_movimento)

	
if exists (SELECT 1 FROM sys.indexes 
			WHERE name='IX_corp_parc_movto(cd_evento)' AND object_id = OBJECT_ID('dbo.corp_parc_movto'))
begin
	print '-- drop index
		drop index IX_corp_parc_movto(cd_evento) on dbo.corp_parc_movto;'
end

if exists (SELECT 1 FROM sys.indexes 
			WHERE name='IX_corp_parc_movto(cd_forma_pagamento)' AND object_id = OBJECT_ID('dbo.corp_parc_movto'))
begin
	print '-- drop index
		drop index IX_corp_parc_movto(cd_forma_pagamento) on dbo.corp_parc_movto;'
end


if exists (SELECT 1 FROM sys.indexes 
			WHERE name='IX_corp_parc_movto(dt_envio_banco)' AND object_id = OBJECT_ID('dbo.corp_parc_movto'))
begin
	print '-- drop index
		drop index IX_corp_parc_movto(dt_envio_banco) on dbo.corp_parc_movto;'
end

if exists (SELECT 1 FROM sys.indexes 
			WHERE name='IX_corp_parc_movto(dt_sistema$cd_evento)' AND object_id = OBJECT_ID('dbo.corp_parc_movto'))
begin
	print '-- drop index
		drop index IX_corp_parc_movto(dt_sistema$cd_evento) on dbo.corp_parc_movto;'
end

if exists (SELECT 1 FROM sys.indexes 
			WHERE name='IX_corp_parc_movto_X_Cd_evento' AND object_id = OBJECT_ID('dbo.corp_parc_movto'))
begin
	print '-- drop index
		drop index IX_corp_parc_movto_X_Cd_evento on dbo.corp_parc_movto;'
end

if exists (SELECT 1 FROM sys.indexes 
			WHERE name='IX_corp_parc_movto_X_Dt_sistema$Cd_evento' AND object_id = OBJECT_ID('dbo.corp_parc_movto'))
begin
	print '-- drop index
		drop index IX_corp_parc_movto_X_Dt_sistema$Cd_evento on dbo.corp_parc_movto;'
end

print '-- Criar indice
create nonclustered index ix_corp_parc_movto_X_Cd_forma_pagamento$Dt_envio_banco$Cd_evento$dt_sistema
 on dbo.corp_parc_movto (Cd_forma_pagamento,Dt_envio_banco,Cd_evento,dt_sistema) ;' 
 
print '-- Criar indice
create nonclustered index ix_corp_parc_movto_X_id_bandeira
 on dbo.corp_parc_movto (id_bandeira) ;' 


if exists (SELECT 1 FROM sys.indexes 
			WHERE name='idx_corp_parc_movto_id_pagamento_include_id_parcela' AND object_id = OBJECT_ID('dbo.corp_parc_movto'))
begin
	print '-- drop index
		drop index idx_corp_parc_movto_id_pagamento_include_id_parcela on dbo.corp_parc_movto;'
end

if exists (SELECT 1 FROM sys.indexes 
			WHERE name='ix_corp_parc_movto(id_pagamento)' AND object_id = OBJECT_ID('dbo.corp_parc_movto'))
begin
	print '-- drop index
		drop index ix_corp_parc_movto(id_pagamento) on dbo.corp_parc_movto;'
end

if exists (SELECT 1 FROM sys.indexes 
			WHERE name='IX_corp_parc_movto(id_parcela$cd_evento)' AND object_id = OBJECT_ID('dbo.corp_parc_movto'))
begin
	print '-- drop index
		drop index IX_corp_parc_movto(id_parcela$cd_evento) on dbo.corp_parc_movto;'
end

if exists (SELECT 1 FROM sys.indexes 
			WHERE name='IX_corp_parc_movto_X_Id_pagamento' AND object_id = OBJECT_ID('dbo.corp_parc_movto'))
begin
	print '-- drop index
		drop index IX_corp_parc_movto_X_Id_pagamento on dbo.corp_parc_movto;'
end

if exists (SELECT 1 FROM sys.indexes 
			WHERE name='IX_corp_parc_movto_X_Id_parcela$Cd_evento' AND object_id = OBJECT_ID('dbo.corp_parc_movto'))
begin
	print '-- drop index
		drop index IX_corp_parc_movto_X_Id_parcela$Cd_evento on dbo.corp_parc_movto;'
end
 
print '-- Criar indice
create nonclustered index ix_corp_parc_movto_X_Id_pagamento$id_parcela$cd_evento$dv_gera_pagamento
 on dbo.corp_parc_movto (Id_pagamento,id_parcela, cd_evento, dv_gera_pagamento) 
 INCLUDE (Id_parcela_movimentacao, Dt_movimento, id_parcela_movimentacao_ref);' 
 
 return

