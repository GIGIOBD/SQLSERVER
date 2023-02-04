if OBJECT_ID('tempdb..#tmp_principais_procedures_consumo_memoria','u') is not null
begin
	drop table #tmp_principais_procedures_consumo_memoria
end 
SELECT TOP 50 *
--into #tmp_principais_procedures_consumo_memoria
				FROM
		(
		    SELECT DatabaseName = DB_NAME(qt.dbid), 
		           QueryText = qt.text, 
		           DiskReads = SUM(qs.total_physical_reads),   -- The worst reads, disk reads 
		           MemoryReads = SUM(qs.total_logical_reads),    --Logical Reads are memory reads 
		           Total_IO_Reads = SUM(qs.total_physical_reads + qs.total_logical_reads), 
		           Executions = SUM(qs.execution_count), 
		           IO_Per_Execution = SUM((qs.total_physical_reads + qs.total_logical_reads) / qs.execution_count), 
		           CPUTime = SUM(qs.total_worker_time), 
		           DiskWaitAndCPUTime = SUM(qs.total_elapsed_time), 
		           MemoryWrites = SUM(qs.max_logical_writes), 
		           DateLastExecuted = MAX(qs.last_execution_time)
		    FROM sys.dm_exec_query_stats AS qs
		         CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS qt
		    WHERE OBJECT_SCHEMA_NAME(qt.objectid, dbid) + '.' + OBJECT_NAME(qt.objectid, qt.dbid) IS NULL
			AND qt.dbid = DB_ID() -- Filter by current database
		    GROUP BY DB_NAME(qt.dbid), 
		             qt.text, 
		             OBJECT_SCHEMA_NAME(qt.objectid, dbid) + '.' + OBJECT_NAME(qt.objectid, qt.dbid)
		) T
		ORDER BY IO_Per_Execution DESC;

	select 1, 'create table #tmp_principais_procedures_consumo_memoria ('+CHAR(10) union
	select 		
		2,
		'['+c.name + ']		' +t.name + ','+CHAR(10)--, c.precision, c.scale, c.max_length
	from tempdb.sys.columns c 
	join sys.types t
	on t.user_type_id = c.user_type_id
	where object_id = (select object_id('tempdb..#tmp_principais_procedures_consumo_memoria')) union
	select 3, ')'+CHAR(10) 


	            
	--if OBJECT_ID('tempdb..#tmp_principais_procedures_consumo_memoria','u') is not null
	--begin
	--	drop table #tmp_principais_procedures_consumo_memoria
	--end 

	--create table #tmp_principais_procedures_consumo_memoria 
	--(
	--	[CPUTime]		bigint,
	--	[DatabaseName]		nvarchar,
	--	[DateLastExecuted]		datetime,
	--	[DiskReads]		bigint,
	--	[DiskWaitAndCPUTime]		bigint,
	--	[Executions]		bigint,
	--	[IO_Per_Execution]		bigint,
	--	[MemoryReads]		bigint,
	--	[MemoryWrites]		bigint,
	--	[ObjectName]		nvarchar
	--)

