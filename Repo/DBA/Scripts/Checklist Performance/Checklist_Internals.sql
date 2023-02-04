use master; 
/* Versão */
select @@VERSION

/*Target recovery, level compatibility */
select target_recovery_time_in_seconds, compatibility_level, name from sys.databases

/* Quantidade CPU */
select * from sys.dm_os_schedulers
where scheduler_id < 255

/* MIN MAX Memory
sp_configure 'show advanced options', 1;
GO
RECONFIGURE;
GO
sp_configure 'max server memory', 3072;
GO
RECONFIGURE;
GO
*/
SELECT [name], [value], [value_in_use]
FROM sys.configurations
WHERE [name] = 'max server memory (MB)' OR [name] = 'min server memory (MB)';

/* Verifica o PLE de dentro do SQL Server */
SELECT
ple.[Node]
,LTRIM(STR([PageLife_S]/3600))+':'+REPLACE(STR([PageLife_S]%3600/60,2),SPACE(1),'0')+':'+REPLACE(STR([PageLife_S]%60,2),SPACE(1),'0') [PageLife]
,ple.[PageLife_S]
,dp.[DatabasePages] [BufferPool_Pages]
,CONVERT(DECIMAL(15,3),dp.[DatabasePages]*0.0078125) [BufferPool_MiB] ,CONVERT(DECIMAL(15,3),dp.[DatabasePages]*0.0078125/[PageLife_S]) [BufferPool_MiB_S]
FROM
(
SELECT [instance_name] [node],[cntr_value] [PageLife_S] FROM sys.dm_os_performance_counters
WHERE [counter_name] = 'Page life expectancy'
) ple
INNER JOIN
(
SELECT [instance_name] [node],[cntr_value] [DatabasePages] FROM sys.dm_os_performance_counters
WHERE [counter_name] = 'Database pages'
) dp ON ple.[node] = dp.[node]

/*
	Quantidade de páginas e memória alocada por database
*/

SELECT
    CASE database_id WHEN 32767 THEN 'ResourceDb' ELSE DB_NAME(database_id)END AS database_name,
    COUNT(*) AS cached_pages_count,
    COUNT(*) * .0078125 AS cached_megabytes, /* Each page is 8kb, which is .0078125 of an MB */
	replace(convert(varchar(50),COUNT(*) * .0078125),'.',',') AS cached_megabytes
FROM
    sys.dm_os_buffer_descriptors
GROUP BY
    DB_NAME(database_id),
    database_id
ORDER BY
    cached_pages_count DESC;

/* Quantidade alocada no tempdb */

declare @qtd_em_Mb int = 100

SELECT A.session_id,B.host_name, B.Login_Name ,
(user_objects_alloc_page_count + internal_objects_alloc_page_count)*1.0/128 as TotalalocadoMB,
D.Text
FROM sys.dm_db_session_space_usage A
JOIN sys.dm_exec_sessions B  ON A.session_id = B.session_id
JOIN sys.dm_exec_connections C ON C.session_id = B.session_id
CROSS APPLY sys.dm_exec_sql_text(C.most_recent_sql_handle) As D
WHERE A.session_id > 50
and (user_objects_alloc_page_count + internal_objects_alloc_page_count)*1.0/128 > @qtd_em_Mb 
ORDER BY totalalocadoMB desc

/* Statistics */
SELECT
			A.object_id,
			A.name AS [object_name],
			s.name as [statistics_name],
			B.last_user_update as B_last_updated_object,
			datediff(HOUR,B.last_user_update,GETDATE()) as TmpSem_Atualiza_dados			
			,D.last_updated as D_last_updated_statitics
			,datediff(HOUR,B.last_user_update,GETDATE())
			,datediff(HOUR,D.last_updated,GETDATE()) TmpSem_Atualiza_stats
			,d.modification_counter
			,'update statistics '+ sc.name +'.'+A.name + '  ['+ s.name +']' as command
		FROM sys.objects                                 A
		join sys.schemas sc on sc.schema_id = A.schema_id
		LEFT JOIN sys.dm_db_index_usage_stats       B	ON	B.[object_id] = A.[object_id] AND B.[database_id] = DB_ID()	
		JOIN sys.stats s on s.object_id = A.object_id
		OUTER APPLY sys.dm_db_stats_properties(s.object_id, s.stats_id) D
		WHERE A.[type_desc] IN ('VIEW', 'USER_TABLE')
		and A.name not in('corp_lancamento_contabil','t_log_operacao_campo','corp_acompanha_rotina','t_servico_log_chamada','t_ecm_documento','t_documento'
		,'t_documento_conteudo','sdk_processamento_log')		
		and datediff(HOUR,isnull(D.last_updated,'19000101'),GETDATE()) > 3			--ultima atualiza??o de statistics
		--and datediff(HOUR,B.last_user_update,GETDATE()) > 1	
		and d.modification_counter > 20000

/* Tabelas sem compressão */
SELECT
    A.[partition_id],
    A.[object_id],
    object_name(A.[object_id]) AS [object_name],
    data_compression_desc
FROM
    sys.partitions A
    join sys.objects B on A.[object_id] = B.[object_id]
WHERE B.is_ms_shipped = 0 
and data_compression_desc <> 'NONE'

/* Arquivos dos bancos de dados */
select * from sys.sysaltfiles

/* Sessoes tempdb */
use tempdb;
SELECT  distinct
		COALESCE(T1.session_id, T2.session_id) [session_id] ,        T1.request_id ,
        COALESCE(T1.database_id, T2.database_id) [database_id],
        COALESCE(T1.[Total Allocation User Objects], 0)
        + T2.[Total Allocation User Objects] [Total Allocation User Objects] ,
        COALESCE(T1.[Net Allocation User Objects], 0)
        + T2.[Net Allocation User Objects] [Net Allocation User Objects] ,
        COALESCE(T1.[Total Allocation Internal Objects], 0)
        + T2.[Total Allocation Internal Objects] [Total Allocation Internal Objects] ,
        COALESCE(T1.[Net Allocation Internal Objects], 0)
        + T2.[Net Allocation Internal Objects] [Net Allocation Internal Objects] ,
        COALESCE(T1.[Total Allocation], 0) + T2.[Total Allocation] [Total Allocation] ,
        COALESCE(T1.[Net Allocation], 0) + T2.[Net Allocation] [Net Allocation] ,
        COALESCE(T1.[Query Text], T2.[Query Text]) [Query Text]
FROM    ( SELECT    TS.session_id ,
                    TS.request_id ,
                    TS.database_id ,
                    CAST(TS.user_objects_alloc_page_count / 128 AS DECIMAL(15,
                                                              2)) [Total Allocation User Objects] ,
                    CAST(( TS.user_objects_alloc_page_count
                           - TS.user_objects_dealloc_page_count ) / 128 AS DECIMAL(15,
                                                              2)) [Net Allocation User Objects] ,
                    CAST(TS.internal_objects_alloc_page_count / 128 AS DECIMAL(15,
                                                              2)) [Total Allocation Internal Objects] ,
                    CAST(( TS.internal_objects_alloc_page_count
                           - TS.internal_objects_dealloc_page_count ) / 128 AS DECIMAL(15,
                                                              2)) [Net Allocation Internal Objects] ,
                    CAST(( TS.user_objects_alloc_page_count
                           + internal_objects_alloc_page_count ) / 128 AS DECIMAL(15,
                                                              2)) [Total Allocation] ,
                    CAST(( TS.user_objects_alloc_page_count
                           + TS.internal_objects_alloc_page_count
                           - TS.internal_objects_dealloc_page_count
                           - TS.user_objects_dealloc_page_count ) / 128 AS DECIMAL(15,
                                                              2)) [Net Allocation] ,
                    T.text [Query Text]
          FROM      sys.dm_db_task_space_usage TS
                    INNER JOIN sys.dm_exec_requests ER ON ER.request_id = TS.request_id
                                                          AND ER.session_id = TS.session_id
                    OUTER APPLY sys.dm_exec_sql_text(ER.sql_handle) T
        ) T1
        RIGHT JOIN ( SELECT SS.session_id ,
                            SS.database_id ,
                            CAST(SS.user_objects_alloc_page_count / 128 AS DECIMAL(15,
                                                              2)) [Total Allocation User Objects] ,
                            CAST(( SS.user_objects_alloc_page_count
                                   - SS.user_objects_dealloc_page_count )
                            / 128 AS DECIMAL(15, 2)) [Net Allocation User Objects] ,
                            CAST(SS.internal_objects_alloc_page_count / 128 AS DECIMAL(15,
                                                              2)) [Total Allocation Internal Objects] ,
                            CAST(( SS.internal_objects_alloc_page_count
                                   - SS.internal_objects_dealloc_page_count )
                            / 128 AS DECIMAL(15, 2)) [Net Allocation Internal Objects] ,
                            CAST(( SS.user_objects_alloc_page_count
                                   + internal_objects_alloc_page_count ) / 128 AS DECIMAL(15,
                                                              2)) [Total Allocation] ,
                            CAST(( SS.user_objects_alloc_page_count
                                   + SS.internal_objects_alloc_page_count
                                   - SS.internal_objects_dealloc_page_count
                                   - SS.user_objects_dealloc_page_count )
                            / 128 AS DECIMAL(15, 2)) [Net Allocation] ,
                            T.text [Query Text]
                     FROM   sys.dm_db_session_space_usage SS
                            LEFT JOIN sys.dm_exec_connections CN ON CN.session_id = SS.session_id
                            OUTER APPLY sys.dm_exec_sql_text(CN.most_recent_sql_handle) T
                   ) T2 ON T1.session_id = T2.session_id
				   order by [Total Allocation] desc
			   

/* Compression Pages 

set nocount on

Declare @strExec varchar(500), @dbName sysname, 
@sql varchar(4000),@nm_schema varchar(120), @nm_tabela varchar(120),
@nm_indice varchar(500)

 if object_id ('tempdb..#temp','u') is not null
drop table #temp

create table #temp(
		 sch_name sysname,
		 tabela sysname,
		 index_id int,
		 indice sysname null,
		 avg_fragmentation_in_percent float)


Declare Cursor_Bancos cursor LOCAL FAST_FORWARD FOR
Select name From master.sys.databases
Where database_id > 4 and state_desc='online'
and name like '%dev'
order by name

Open Cursor_Bancos
Fetch Next From Cursor_Bancos into @dbName

While @@Fetch_status = 0
Begin
	
	truncate table #temp
	 set @sql=' insert into #temp
	 SELECT s.name sch_name,so.name as tabela, a.index_id, b.name as indice, a.avg_fragmentation_in_percent
	FROM '+@dbname+'.sys.dm_db_index_physical_stats (DB_ID('''+@dbname+'''), NULL, NULL, NULL, NULL) AS a
		inner JOIN '+@dbname+'.sys.indexes AS b 
		ON a.object_id = b.object_id 
		AND a.index_id = b.index_id
	 inner join '+	@dbname+'.sys.objects so 
		 on so.object_id = b.object_id
		 and so.type = ''U''
		 inner join '+	@dbname+'.sys.schemas s
		 on so.schema_id=s.schema_id'
	 
	 exec (@sql) 
	 
	 

	 Declare cursor_reorg cursor LOCAL FAST_FORWARD FOR
	Select sch_name,tabela, indice From #temp 
	where avg_fragmentation_in_percent > 15.
	and indice is not null
	order by tabela, index_id

	Open cursor_reorg
	Fetch Next from cursor_reorg into @nm_schema,@nm_tabela, @nm_indice
	While @@fetch_status = 0
	Begin
		Set @strExec ='use '+@dbname+ ' ALTER INDEX [' + @nm_indice + ']' + char(10) +
		'ON ['+@dbname+'].['+@nm_schema+'].[' + @nm_tabela + ']' + char(10)  

		 if Not exists(select top 1 colid from syscolumns where id = object_id(@nm_tabela) and type in(34,35))
		 Begin 
			  Set @strExec = @strExec + ' REBUILD WITH (DATA_COMPRESSION = PAGE, FILLFACTOR = 80) '	+ char(10)  
		 End
		 Else
		 Begin
			  Set @strExec = @StrExec + ' REBUILD WITH (DATA_COMPRESSION = PAGE, FILLFACTOR = 80)' + char(10)
		 End
		print @strExec
		Exec(@strExec)
		
		Fetch Next from cursor_reorg into @nm_schema,@nm_tabela, @nm_indice
	End

	Close cursor_reorg
	deallocate cursor_reorg

	fetch next from Cursor_Bancos into @dbname

end

Close Cursor_Bancos
Deallocate Cursor_Bancos

*/