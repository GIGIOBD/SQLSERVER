	declare 
		@nm_procedure varchar(500) = 'dbo.p_emissao_resseguro_cancelamento'

	if object_id('tempdb..#tmp_tables','u') is not null
	begin
		drop table #tmp_tables
	end

	create table #tmp_tables
	(
		[nm_schema]	varchar(500),
		[nm_object] varchar(500),
		[nm_type]	varchar(500)
	)

	insert into #tmp_tables (nm_schema, nm_object, nm_type)
	SELECT DISTINCT 
		SCHEMA_NAME(o.[schema_id]),
		o.name,
		o.type_desc
	FROM sys.dm_sql_referenced_entities(@nm_procedure,'OBJECT') d
	     JOIN sys.objects o
		 ON d.referenced_id = o.[object_id]
	WHERE o.[type] IN ('U','V');

	select 
		nm_schema,
		nm_object,
		nm_type
	from #tmp_tables
	order by nm_schema, nm_object
	-- gera update statistics
	select distinct
		nm_schema		=	ss.name ,
		nm_table		=	sta.name,
	    nm_statistic	=	st.[name],
	    rowns			=	stp.rows,
		rows_sampled	=	stp.rows_sampled,
		d.last_updated,
	    command			= ' update statistics ' + '[' + ss.name + ']' + '.[' + object_name(st.object_id) + ']' + ' ' + '[' + st.name + ']'
	       + ' with fullscan'
	from sys.stats as st
	    cross apply sys.dm_db_stats_properties(st.object_id, st.stats_id) as stp
	    join sys.tables sta
	        on st.[object_id] = sta.object_id
	    join sys.schemas ss
	        on ss.schema_id = sta.schema_id
		join #tmp_tables t
			on t.nm_object = sta.name
		outer apply sys.dm_db_stats_properties(st.[object_id], st.stats_id) d
	order by stp.[rows] desc;