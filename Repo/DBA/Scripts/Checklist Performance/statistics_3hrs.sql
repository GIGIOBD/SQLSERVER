
--select * from atualiza_estatistica
--insert into atualiza_estatistica (nr_valor) values ((select rand()*999))
	
--select object_name(1314103722),D.*  
--from sys.stats s
--OUTER APPLY sys.dm_db_stats_properties(S.[object_id], S.stats_id) D
--where s.object_id = 1314103722


 --update statistics dbo.atualiza_estatistica with fullscan
	SELECT
		--COUNT(1)
		A.object_id,
		A.name AS [object_name],
		s.name as [statistics_name],
		B.last_user_update as B_last_updated_object,
		datediff(HOUR,B.last_user_update,GETDATE()) as TmpSem_Atualiza_dados
		,D.last_updated as D_last_updated_statitics
		,datediff(HOUR,B.last_user_update,GETDATE()),
		datediff(HOUR,D.last_updated,GETDATE()) TmpSem_Atualiza_stats
		,'update statistics '+ sc.name +'.'+A.name + '  ['+ s.name +']'
	FROM
	sys.objects                                 A
	join sys.schemas sc on sc.schema_id = A.schema_id
	LEFT JOIN sys.dm_db_index_usage_stats       B	ON	B.[object_id] = A.[object_id] AND B.[database_id] = DB_ID()	
	JOIN sys.stats s on s.object_id = A.object_id
	OUTER APPLY sys.dm_db_stats_properties(s.object_id, s.stats_id) D
	WHERE A.[type_desc] IN ('VIEW', 'USER_TABLE')
	and A.name not in('corp_lancamento_contabil','t_log_operacao_campo','corp_acompanha_rotina','t_servico_log_chamada','t_ecm_documento')
	--and D.last_updated < GETDATE() - 1
	and datediff(HOUR,D.last_updated,GETDATE()) > 3			--ultima atualização de statistics
	and datediff(HOUR,B.last_user_update,GETDATE()) > 1		--ultima atualização do objecto


return
	--create table atualiza_estatistica
	--(
	--	id	int identity primary key,
	--	nr_valor int
	--)


--use master;
--sp_helpdb core2_erp_dev_rest
--drop database core2_erp_dev_rest;
/*
set nocount on

Declare @strExec varchar(2000), @dbName sysname, @sql varchar(1000),@nm_schema varchar(120), @nm_tabela varchar(120)

if object_id ('tempdb..#tabela','u') is not null
drop table #tabela

create table #tabela(nm_schema varchar(120),nm_tabela varchar(120))

Declare Cursor_Bancos cursor LOCAL FAST_FORWARD FOR
Select name From master.sys.databases
Where database_id > 4 and state_desc='online'
order by name

Open Cursor_Bancos
Fetch Next From Cursor_Bancos into @dbName

While @@Fetch_status = 0
Begin
	 truncate table #tabela


	 set @sql='insert into #tabela(nm_schema,nm_tabela) select s.name,t.name from '+@dbname+'.sys.tables t join '+@dbname+'.sys.schemas s
	 on t.schema_id = s.schema_id where t.name not in(''corp_lancamento_contabil'',''t_log_operacao_campo'',''corp_acompanha_rotina'',''t_servico_log_chamada'''+')'

	 exec (@sql) 
	 
	 

	 declare cur_tabela cursor for select nm_schema,nm_tabela from #tabela

	 open cur_tabela

	 fetch cur_tabela into @nm_schema,@nm_tabela

	 while @@fetch_status = 0
	 begin


	 
	 Set @strExec = 'USE ' + @dbName + ' update statistics ['+@nm_schema+'].['+@nm_tabela+'] with fullscan'

	
	exec(@strExec)

	 fetch next from cur_tabela into @nm_schema,@nm_tabela
	
	end
	close cur_tabela 
	deallocate cur_tabela
	
	 Fetch Next From Cursor_Bancos into @dbName
End

Close Cursor_Bancos
Deallocate Cursor_Bancos
*/