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
and name like '%i4pro%'
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
			  Set @strExec = @strExec + ' REBUILD WITH (FILLFACTOR = 80) '	+ char(10)  
		 End
		 Else
		 Begin
			  Set @strExec = @StrExec + ' REBUILD WITH (FILLFACTOR = 80)' + char(10)
		 End
		
		Exec(@strExec)
		
		Fetch Next from cursor_reorg into @nm_schema,@nm_tabela, @nm_indice
	End

	Close cursor_reorg
	deallocate cursor_reorg

	fetch next from Cursor_Bancos into @dbname

end

Close Cursor_Bancos
Deallocate Cursor_Bancos