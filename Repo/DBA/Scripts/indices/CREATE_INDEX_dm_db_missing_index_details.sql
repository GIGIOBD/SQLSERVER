declare 
	@db_id int		= null,
	@object_id bigint	= null,
	@sql	varchar(max)
exec sp_executesql @stmt=N'
          select 					
			gs.avg_user_impact ,
			d.database_id, 
			d.object_id, 
			d.index_handle, 
			d.equality_columns, 
			d.inequality_columns, 
			d.included_columns, 
			d.statement as fully_qualified_object,          
		  FLOOR((CONVERT(NUMERIC(19,3), gs.user_seeks) + CONVERT(NUMERIC(19,3), gs.user_scans)) * CONVERT(NUMERIC(19,3), gs.avg_total_user_cost) * CONVERT(NUMERIC(19,3), gs.avg_user_impact)) AS Score,
		  command = ''CREATE NONCLUSTERED INDEX ix_''+ 
			replace(replace(replace(statement,''['',''''),'']'',''''),''.'',''_'')						  +''_X_''+ 				 
			replace(replace(replace(isnull(d.equality_columns,''''),''['',''''),'']'',''''),'', '',''$'')			+ 
			replace(replace(isnull(d.inequality_columns,''''),''['',''''),'']'','''')	+ CHAR(10)				+
			''ON ''+statement+'' (''+ isnull(d.equality_columns,'''')										+ 
				case when isnull(d.equality_columns,'''') = '''' 
					then isnull(d.inequality_columns,'''') 
					else isnull('',''+d.inequality_columns,'''') end +'')''									+ 
				case when isnull(d.included_columns,'''') = '''' 
					then '''' 
					else CHAR(10)+ ''INCLUDE (''+ isnull(included_columns,'''') +'')'' end + CHAR(13)
          from sys.dm_db_missing_index_groups g
          join sys.dm_db_missing_index_group_stats gs on gs.group_handle = g.index_group_handle
          join sys.dm_db_missing_index_details d on g.index_handle = d.index_handle
          where d.database_id = isnull(@DatabaseID , d.database_id) and d.object_id = isnull(@ObjectID, d.object_id)
		  order by [score] desc
        ',@params=N'@DatabaseID NVarChar(max), @ObjectID NVarChar(max)',
		  @DatabaseID=@db_id,
		  @ObjectID=@object_id
