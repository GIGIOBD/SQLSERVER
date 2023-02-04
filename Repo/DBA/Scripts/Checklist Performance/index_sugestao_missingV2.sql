/*
Sugestões de Missing Index
Com a consulta abaixo, você poderá visualizar as sugestões de índices do SQL Server baseado nas estatísticas de Missing Index. 
Muito cuidado com essas sugestões, pois nem sempre elas são a melhor opção para a criação de um índice. 
Analise as sugestões antes de criar no banco.
*/
set transaction isolation level read uncommitted
SELECT
	s.name + '.' + o.name as tabela,
	--'CREATE NONCLUSTERED INDEX [IX_' + OBJECT_NAME(id.[object_id], db.[database_id]) + '_X_' + REPLACE(REPLACE(REPLACE(ISNULL(id.[equality_columns], ''), ', ', '_'), '[', ''), ']', '') + CASE WHEN id.[equality_columns] IS NOT NULL AND id.[inequality_columns] IS NOT NULL THEN '_' ELSE '' END + REPLACE(REPLACE(REPLACE(ISNULL(id.[inequality_columns], ''), ', ', '_'), '[', ''), ']', '') + '_' + LEFT(CAST(NEWID() AS [NVARCHAR](64)), 5) + ']' + ' ON ' + id.[statement] + ' (' + ISNULL(id.[equality_columns], '') + CASE WHEN id.[equality_columns] IS NOT NULL AND id.[inequality_columns] IS NOT NULL THEN ',' ELSE '' END + ISNULL(id.[inequality_columns], '') + ')' + ISNULL(' INCLUDE (' + id.[included_columns] + ')', '') AS [ProposedIndex],
    gs.[avg_user_impact] AS [AvgUserImpact],
	gs.[user_seeks] AS [UserSeeks],
	gs.[unique_compiles] AS [UniqueCompiles],    
    gs.[user_scans] AS [UserScans],
	CAST(CURRENT_TIMESTAMP AS [SMALLDATETIME]) AS [CollectionDate],
    db.[name] AS [DatabaseName],
    id.[object_id] AS [ObjectID],
    OBJECT_NAME(id.[object_id], db.[database_id]) AS [ObjectName],
    id.[statement] AS [FullyQualifiedObjectName],
    id.[equality_columns] AS [EqualityColumns],
    id.[inequality_columns] AS [InEqualityColumns],
    id.[included_columns] AS [IncludedColumns],
    gs.[last_user_seek] AS [LastUserSeekTime],
    gs.[last_user_scan] AS [LastUserScanTime],
    gs.[avg_total_user_cost] AS [AvgTotalUserCost],    
    gs.[user_seeks] * gs.[avg_total_user_cost] * ( gs.[avg_user_impact] * 0.01 ) AS [IndexAdvantage],
    gs.[system_seeks] AS [SystemSeeks],
    gs.[system_scans] AS [SystemScans],
    gs.[last_system_seek] AS [LastSystemSeekTime],
    gs.[last_system_scan] AS [LastSystemScanTime],
    gs.[avg_total_system_cost] AS [AvgTotalSystemCost],
    gs.[avg_system_impact] AS [AvgSystemImpact]	
	into #tmp
FROM
    [sys].[dm_db_missing_index_group_stats] gs WITH ( NOLOCK )
    JOIN [sys].[dm_db_missing_index_groups] ig WITH ( NOLOCK ) ON gs.[group_handle] = ig.[index_group_handle]
    JOIN [sys].[dm_db_missing_index_details] id WITH ( NOLOCK ) ON ig.[index_handle] = id.[index_handle]
    JOIN [sys].[databases] db WITH ( NOLOCK ) ON db.[database_id] = id.[database_id]
	join sys.objects o on o.object_id = id.[object_id]
	join sys.schemas s on s.schema_id = o.schema_id
WHERE
    db.[database_id] = DB_ID()
	--and s.name = 'sro'
	and avg_user_impact > 30.00	
	and user_seeks > 500
	--and s.name + '.' + o.name = 'sro.t_objeto_cobertura'
    --AND gs.avg_total_user_cost * ( gs.avg_user_impact / 100.0 ) * ( gs.user_seeks + gs.user_scans ) > 10
ORDER BY
    o.name asc
OPTION ( RECOMPILE );

select * from #tmp

select distinct
	tabela, keys = isnull(EqualityColumns, InEqualityColumns),
	--charindex(',',EqualityColumns) ,
	principal_key = case when charindex(',',EqualityColumns) > 0 then
		SUBSTRING(isnull(EqualityColumns, InEqualityColumns),0,charindex(',',EqualityColumns))
		else isnull(EqualityColumns, InEqualityColumns) end
	into #tmp_final
from #tmp

select distinct 
	tabela, 
	principal_key 
from #tmp_final

	select distinct
		t2.tabela,
		t2.principal_key
		--,t1.IncludedColumns
	from #tmp t1
	join #tmp_final t2
	on t2.tabela = t1.tabela
	and t2.principal_key = case when charindex(',',t1.EqualityColumns) > 0 then
		SUBSTRING(isnull(t1.EqualityColumns, t1.InEqualityColumns),0,charindex(',',t1.EqualityColumns))
		else isnull(t1.EqualityColumns, t1.InEqualityColumns) end
	
	


drop table #tmp
drop table #tmp_final


