set nocount on

Declare @strExec varchar(500), @dbName sysname, @sql varchar(4000),@nm_schema varchar(120), @nm_tabela varchar(120)

if object_id ('tempdb..#tabela','u') is not null
drop table #tabela

create table #tabela(nm_schema varchar(120),nm_tabela varchar(120))

Declare Cursor_Bancos cursor LOCAL FAST_FORWARD FOR
Select name From master.sys.databases
Where database_id > 4 and state_desc='online'
and name like '%i4pro%'
order by name

Open Cursor_Bancos
Fetch Next From Cursor_Bancos into @dbName

While @@Fetch_status = 0
Begin
	 truncate table #tabela


	 set @sql='insert into #tabela(nm_schema,nm_tabela) select s.name,t.name from '+@dbname+'.sys.tables t join '+@dbname+'.sys.schemas s
	 on t.schema_id = s.schema_id'
	 
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