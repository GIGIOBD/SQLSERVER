CREATE PROCEDURE dbo.sp_merge_index
(
	@dv_script				bit,
	@TableName				varchar(500) = null,
	@dv_list_depend			bit	= null,
	@cd_retorno				int = null output,
	@nm_retorno				varchar(500) = null output
)
AS
BEGIN

set transaction isolation level read uncommitted
set nocount on 
	/*
		sp_merge_index @dv_script = 0, @TableName = 'eng.t_tela_coluna_condicao', @dv_list_depend = 1
		sp_merge_index @dv_script = 0, @TableName ='eng.t_tela_coluna_condicao'	
	*/
 
	
	if object_id ('tempdb..#tmp_objects','u') is not null
	begin
		drop table #tmp_objects
	end

	if object_id ('tempdb..#tmp_final','u') is not null
	begin
		drop table #tmp_final
	end

	if object_id ('tempdb..#tmp_indices_duplicados','u') is not null
	begin
		drop table #tmp_indices_duplicados
	end
	
	if object_id ('tempdb..#tmp_indices_duplicados_aux2','u') is not null
	begin
		drop table #tmp_indices_duplicados_aux2
	end
	
	if object_id ('tempdb..#tmp_indices_duplicados_aux3','u') is not null
	begin
		drop table #tmp_indices_duplicados_aux3
	end
	
	if object_id ('tempdb..#tmp_indices_unificados_chave','u') is not null
	begin
		drop table #tmp_indices_unificados_chave
	end

	create table #tmp_indices_unificados_chave
	(
		schemaname varchar(500),
		tablename  varchar(1000),
		nm_columns varchar(5000),
		nm_include varchar(5000)
	)

--BEGIN/* VALIDAÇÔES */
--	if @TableName is not null
--	begin
--		if not exists (select 1 from sys.objects where type_desc in ('u','v'))
--		begin
--			select @cd_retorno = 1,  @nm_retorno = 'Tabela não existe no banco de dados'

--			select @cd_retorno, @nm_retorno 
--			return
--		end
--	end
--END

	;WITH MyDuplicate AS (
	SELECT 
		Sch.[name] AS SchemaName,
		Obj.[name] AS TableName,
		Idx.[name] AS IndexName,
		INDEX_COL(Sch.[name] + '.' + Obj.[name], Idx.index_id, 1) AS Col1,
		INDEX_COL(Sch.[name] + '.' + Obj.[name], Idx.index_id, 2) AS Col2,
		INDEX_COL(Sch.[name] + '.' + Obj.[name], Idx.index_id, 3) AS Col3,
		INDEX_COL(Sch.[name] + '.' + Obj.[name], Idx.index_id, 4) AS Col4,
		INDEX_COL(Sch.[name] + '.' + Obj.[name], Idx.index_id, 5) AS Col5,
		INDEX_COL(Sch.[name] + '.' + Obj.[name], Idx.index_id, 6) AS Col6,
		--INDEX_COL(Sch.[name] + '.' + Obj.[name], Idx.index_id, 7) AS Col7,
		--INDEX_COL(Sch.[name] + '.' + Obj.[name], Idx.index_id, 8) AS Col8,
		--INDEX_COL(Sch.[name] + '.' + Obj.[name], Idx.index_id, 9) AS Col9,
		--INDEX_COL(Sch.[name] + '.' + Obj.[name], Idx.index_id, 10) AS Col10,
		--INDEX_COL(Sch.[name] + '.' + Obj.[name], Idx.index_id, 11) AS Col11,
		--INDEX_COL(Sch.[name] + '.' + Obj.[name], Idx.index_id, 12) AS Col12,
		--INDEX_COL(Sch.[name] + '.' + Obj.[name], Idx.index_id, 13) AS Col13,
		--INDEX_COL(Sch.[name] + '.' + Obj.[name], Idx.index_id, 14) AS Col14,
		--INDEX_COL(Sch.[name] + '.' + Obj.[name], Idx.index_id, 15) AS Col15,
		--INDEX_COL(Sch.[name] + '.' + Obj.[name], Idx.index_id, 16) AS Col16,
		IncCol1 = (SELECT c.name
        FROM sys.index_columns ic
        INNER JOIN sys.columns c
		ON c.object_id = ic.object_id AND c.column_id = ic.column_id
		where ic.object_id = Idx.object_id 
		and ic.index_id = Idx.index_id		
		and ic.index_column_id = (select MAX(ic2.index_column_id) from sys.index_columns ic2 
									where ic2.object_id = ic.object_id and ic2.index_id = ic.index_id
									and ic2.is_included_column = 0)+1)  
		,IncCol2 = (SELECT c.name
        FROM sys.index_columns ic
        INNER JOIN sys.columns c
		ON c.object_id = ic.object_id AND c.column_id = ic.column_id
		where ic.object_id = Idx.object_id 
		and ic.index_id = Idx.index_id		
		and ic.index_column_id = (select MAX(ic2.index_column_id) from sys.index_columns ic2 
									where ic2.object_id = ic.object_id and ic2.index_id = ic.index_id
									and ic2.is_included_column = 0)+2)  
		,IncCol3 = (SELECT c.name
        FROM sys.index_columns ic
        INNER JOIN sys.columns c
		ON c.object_id = ic.object_id AND c.column_id = ic.column_id
		where ic.object_id = Idx.object_id 
		and ic.index_id = Idx.index_id		
		and ic.index_column_id = (select MAX(ic2.index_column_id) from sys.index_columns ic2 
									where ic2.object_id = ic.object_id and ic2.index_id = ic.index_id
									and ic2.is_included_column = 0)+3)  
		,IncCol4 = (SELECT c.name
        FROM sys.index_columns ic
        INNER JOIN sys.columns c
		ON c.object_id = ic.object_id AND c.column_id = ic.column_id
		where ic.object_id = Idx.object_id 
		and ic.index_id = Idx.index_id		
		and ic.index_column_id = (select MAX(ic2.index_column_id) from sys.index_columns ic2 
									where ic2.object_id = ic.object_id and ic2.index_id = ic.index_id
									and ic2.is_included_column = 0)+4) 
		,IncCol5 = (SELECT c.name
        FROM sys.index_columns ic
        INNER JOIN sys.columns c
		ON c.object_id = ic.object_id AND c.column_id = ic.column_id
		where ic.object_id = Idx.object_id 
		and ic.index_id = Idx.index_id		
		and ic.index_column_id = (select MAX(ic2.index_column_id) from sys.index_columns ic2 
									where ic2.object_id = ic.object_id and ic2.index_id = ic.index_id
									and ic2.is_included_column = 0)+6) 	
		,IncCol6 = (SELECT c.name
        FROM sys.index_columns ic
        INNER JOIN sys.columns c
		ON c.object_id = ic.object_id AND c.column_id = ic.column_id
		where ic.object_id = Idx.object_id 
		and ic.index_id = Idx.index_id		
		and ic.index_column_id = (select MAX(ic2.index_column_id) from sys.index_columns ic2 
									where ic2.object_id = ic.object_id and ic2.index_id = ic.index_id
									and ic2.is_included_column = 0)+7) 		

		,IncCol7 = (SELECT c.name
        FROM sys.index_columns ic
        INNER JOIN sys.columns c
		ON c.object_id = ic.object_id AND c.column_id = ic.column_id
		where ic.object_id = Idx.object_id 
		and ic.index_id = Idx.index_id		
		and ic.index_column_id = (select MAX(ic2.index_column_id) from sys.index_columns ic2 
									where ic2.object_id = ic.object_id and ic2.index_id = ic.index_id
									and ic2.is_included_column = 0)+8)  	
	FROM sys.indexes Idx
	INNER JOIN sys.objects Obj 
	ON Idx.[object_id] = Obj.[object_id] 
	INNER JOIN sys.schemas Sch 
	ON Sch.[schema_id] = Obj.[schema_id] 
	WHERE index_id > 0
	and Idx.is_primary_key = 0
	and idx.is_unique = 0
	and idx.is_unique_constraint = 0
	--and sch.name not in ('eng','wex','edn','ecm')
	--and obj.name = 't_tela_coluna_condicao'
	)
	
	--select * from MyDuplicate --where TableName = 'corp_sub_corretor'
	--return
	SELECT 
		MD1.SchemaName, MD1.TableName, 
		--MD1.IndexName,
		MD2.IndexName AS OverLappingIndex,
		MD1.Col1, MD1.Col2, MD1.Col3, MD1.Col4,
		MD1.Col5, MD1.Col6,
		--, MD1.Col7, MD1.Col8,
		--MD1.Col9, MD1.Col10, MD1.Col11, MD1.Col12,
		--MD1.Col13, MD1.Col14, MD1.Col15, MD1.Col16
		MD1.IncCol1, MD1.IncCol2, MD1.IncCol3, MD1.IncCol4, 
		MD1.IncCol5, MD1.IncCol6, MD1.IncCol7
	into #tmp_indices_duplicados
	FROM MyDuplicate MD1
	INNER JOIN MyDuplicate MD2 ON MD1.tablename = MD2.tablename
	AND MD1.SchemaName = MD2.SchemaName
	AND MD1.indexname <> MD2.indexname
	AND MD1.Col1 = MD2.Col1
	AND (MD1.Col2 IS NULL OR MD2.Col2 IS NULL OR MD1.Col2 = MD2.Col2)
	AND (MD1.Col3 IS NULL OR MD2.Col3 IS NULL OR MD1.Col3 = MD2.Col3)
	AND (MD1.Col4 IS NULL OR MD2.Col4 IS NULL OR MD1.Col4 = MD2.Col4)
	AND (MD1.Col5 IS NULL OR MD2.Col5 IS NULL OR MD1.Col5 = MD2.Col5)
	AND (MD1.Col6 IS NULL OR MD2.Col6 IS NULL OR MD1.Col6 = MD2.Col6)
	--AND (MD1.Col7 IS NULL OR MD2.Col7 IS NULL OR MD1.Col7 = MD2.Col7)
	--AND (MD1.Col8 IS NULL OR MD2.Col8 IS NULL OR MD1.Col8 = MD2.Col8)
	--AND (MD1.Col9 IS NULL OR MD2.Col9 IS NULL OR MD1.Col9 = MD2.Col9)
	--AND (MD1.Col10 IS NULL OR MD2.Col10 IS NULL OR MD1.Col10 = MD2.Col10)
	--AND (MD1.Col11 IS NULL OR MD2.Col11 IS NULL OR MD1.Col11 = MD2.Col11)
	--AND (MD1.Col12 IS NULL OR MD2.Col12 IS NULL OR MD1.Col12 = MD2.Col12)
	--AND (MD1.Col13 IS NULL OR MD2.Col13 IS NULL OR MD1.Col13 = MD2.Col13)
	--AND (MD1.Col14 IS NULL OR MD2.Col14 IS NULL OR MD1.Col14 = MD2.Col14)
	--AND (MD1.Col15 IS NULL OR MD2.Col15 IS NULL OR MD1.Col15 = MD2.Col15)
	--AND (MD1.Col16 IS NULL OR MD2.Col16 IS NULL OR MD1.Col16 = MD2.Col16)
	where md1.schemaname+'.'+MD1.TableName = isnull(@TableName,md1.schemaname+'.'+MD1.TableName)
	ORDER BY MD1.SchemaName,MD1.TableName,MD1.IndexName, Col1--, Col2, Col3, Col4, col5 


	select
		id = dense_rank() OVER (  order by tablename, col1) ,*
	into #tmp_indices_duplicados_aux2
	from #tmp_indices_duplicados			
	
	
	declare 
		 @max_indices int = (select MAX(id) from #tmp_indices_duplicados_aux2)
		,@contador int = 1
		,@max_indicestmp3 int
		,@contadortmp3 int = 1
		,@nm_chaves varchar(2000) = ''
		,@nm_includes varchar(2000) = ''

	while @contador <= @max_indices
	begin			
		
		if object_id ('tempdb..#tmp_indices_duplicados_aux3','u') is not null
		begin
			drop table #tmp_indices_duplicados_aux3
		end

		select 
			id = ROW_NUMBER() OVER (  order by col1),
			SCHEMANAME,
			TableName,
			OverLappingIndex,
			Col1,
			Col2,
			Col3,
			col4,
			col5,
			col6,
			IncCol1,
			IncCol2,
			IncCol3,
			IncCol4,
			IncCol5,
			IncCol6,
			IncCol7
			into #tmp_indices_duplicados_aux3
		from #tmp_indices_duplicados_aux2 tmp
		where id = @contador

		
		set @max_indicestmp3 = (select MAX(id) from #tmp_indices_duplicados_aux3)
		set @contadortmp3 = 1
		

		while @contadortmp3 <= @max_indicestmp3
		begin
			select @nm_chaves = isnull(@nm_chaves,'') + Col1 +', ' from #tmp_indices_duplicados_aux3
			where id = @contadortmp3
			and @nm_chaves not like '%'+Col1+'%'
			
			select @nm_chaves = isnull(@nm_chaves,'') + Col2 +', ' from #tmp_indices_duplicados_aux3
			where id = @contadortmp3
			and @nm_chaves not like '%'+Col2+'%'

			select @nm_chaves = isnull(@nm_chaves,'') + Col3 +', ' from #tmp_indices_duplicados_aux3
			where id = @contadortmp3
			and @nm_chaves not like '%'+Col3+'%'

			select @nm_chaves = isnull(@nm_chaves,'') + Col4 +', ' from #tmp_indices_duplicados_aux3
			where id = @contadortmp3
			and @nm_chaves not like '%'+Col4+'%'

			select @nm_chaves = isnull(@nm_chaves,'') + Col5 +', ' from #tmp_indices_duplicados_aux3
			where id = @contadortmp3
			and @nm_chaves not like '%'+Col5+'%'

			select @nm_chaves = isnull(@nm_chaves,'') + Col6 +', ' from #tmp_indices_duplicados_aux3
			where id = @contadortmp3
			and @nm_chaves not like '%'+Col6+'%'
			
			set @contadortmp3 = @contadortmp3 + 1
		end

		--select @nm_chaves, @nm_includes

		set @contadortmp3 = 1
		--Validar os includes
		while @contadortmp3 <= @max_indicestmp3
		begin
			select @nm_includes = isnull(@nm_includes,'') + IncCol1 +', ' from #tmp_indices_duplicados_aux3
			where id = @contadortmp3
			and @nm_chaves not like '%'+IncCol1+'%'
			and @nm_includes not like '%'+IncCol1+'%'									

			select @nm_includes = isnull(@nm_includes,'') + IncCol2 +', ' from #tmp_indices_duplicados_aux3
			where id = @contadortmp3
			and @nm_includes not like '%'+IncCol2+'%'
			and @nm_chaves not like '%'+IncCol2+'%'

			select @nm_includes = isnull(@nm_includes,'') + IncCol3 +', ' from #tmp_indices_duplicados_aux3
			where id = @contadortmp3
			and @nm_includes not like '%'+IncCol3+'%'
			and @nm_chaves not like '%'+IncCol3+'%'

			select @nm_includes = isnull(@nm_includes,'') + IncCol4 +', ' from #tmp_indices_duplicados_aux3
			where id = @contadortmp3
			and @nm_includes not like '%'+IncCol4+'%'
			and @nm_chaves not like '%'+IncCol4+'%'

			select @nm_includes = isnull(@nm_includes,'') + IncCol5 +', ' from #tmp_indices_duplicados_aux3
			where id = @contadortmp3
			and @nm_includes not like '%'+IncCol5+'%'
			and @nm_chaves not like '%'+IncCol5+'%'

			select @nm_includes = isnull(@nm_includes,'') + IncCol6 +', ' from #tmp_indices_duplicados_aux3
			where id = @contadortmp3
			and @nm_includes not like '%'+IncCol6+'%'
			and @nm_chaves not like '%'+IncCol6+'%'
			
			set @contadortmp3 = @contadortmp3 + 1
		end
		
		--select @nm_chaves, @nm_includes
		
		insert into #tmp_indices_unificados_chave (schemaname, tablename, nm_columns, nm_include)
		select distinct
			SchemaName,TableName, nm_key = substring(@nm_chaves,0,LEN(@nm_chaves)), substring(@nm_includes,0,LEN(@nm_includes)) 		
		from #tmp_indices_duplicados_aux2 tmp
		where id = @contador

		--select
		--	SchemaName, TableName, OverLappingIndex		
		--from #tmp_indices_duplicados_aux2
		set @nm_chaves = ''
		set @nm_includes = ''
		set @contador = @contador + 1
	end
			
			
	if @dv_script = 0
	begin
		if @TableName is not null
		begin
			exec sp_helpindex2 @tableName
		end

		--select 
		--	SchemaName, TableName, nm_columns = '',
		--	nm_comando = 'DROP INDEX ['+OverLappingIndex +'] ON '+SchemaName+'.'+TableName+';'
		--from #tmp_indices_duplicados 	
		--union
		--select 
		--	SchemaName, TableName, nm_columns = ''
		--	,nm_comando = '
		--	CREATE NONCLUSTERED INDEX 
		--	ix_'+tablename+'_X_'+ replace(nm_columns,', ','$')+ '
		--	ON '+schemaname+'.'+tablename+' ('+ nm_columns +')'+
		--	case when isnull(nm_include,'') <> '' then 
		--	'
		--	INCLUDE ('+ nm_include +')' else '' end +'
		--	ON INDICES'	
		--from #tmp_indices_unificados_chave
		--order by SchemaName, TableName, nm_comando desc
		
		select
			(
			select 			
				count(1) duplicados
			from #tmp_indices_duplicados) as duplicados,
			(
			select 
				count(1) qtd_final
			from #tmp_indices_unificados_chave) as qtd_final

		select 
			SchemaName, TableName, nm_columns = ' ' ,
			nm_comando = 'DROP INDEX ['+OverLappingIndex +'] ON '+SchemaName+'.'+TableName+';'
		from #tmp_indices_duplicados 
		union
		select 
			SchemaName, TableName, nm_columns,
			nm_comando = '
			CREATE NONCLUSTERED INDEX 
			'+ '[ix_'+ convert(varchar(120),tablename+'_X_'+ replace(nm_columns,', ','$')) +']'+ CHAR(10) +
			'ON '+schemaname+'.'+tablename+' ('+ nm_columns +')'+
			case when isnull(nm_include,'') <> '' then 
			'
			INCLUDE ('+ nm_include +')' else '' end +'
			ON INDICES'	
		from #tmp_indices_unificados_chave
		order by SchemaName, TableName desc 
	end
	else
	begin
		select 			
			[--nm_comando] = 
			'if exists (select 1 from sys.indexes where name = '''+OverLappingIndex +''' and object_id = object_id('''+SchemaName+'.'+TableName+''')) '+ CHAR(10) +
			'begin' + CHAR(10) +
			'	DROP INDEX ['+OverLappingIndex +'] ON '+SchemaName+'.'+TableName+';' + CHAR(10) + 
			'end'+ CHAR(10) 
		from #tmp_indices_duplicados 	
		union
		select 
			[--nm_comando] = 
			'/* ------------------------------------------------------------ Drop and create ------------------------------------------------------------------------ */'+ char(10) +
			'if exists (select 1 from sys.indexes where name = '''+'ix_'+ convert(varchar(120),tablename+'_X_'+ replace(nm_columns,', ','$'))+''' and object_id = object_id('''+SchemaName+'.'+TableName+''')) '+ CHAR(10) +
			'begin' + CHAR(10) +
			'	DROP INDEX ['+'ix_'+ convert(varchar(120),tablename+'_X_'+ replace(nm_columns,', ','$'))+'] ON '+SchemaName+'.'+TableName+';' + CHAR(10) + 
			'end'+ CHAR(10) + CHAR(10) + 

			'if not exists (select 1 from sys.indexes where name = '''+'ix_'+ convert(varchar(120),tablename+'_X_'+ replace(nm_columns,', ','$'))+''' and object_id = object_id('''+SchemaName+'.'+TableName+''')) '+ CHAR(10) +
			'begin' + CHAR(10) +
			'	CREATE NONCLUSTERED INDEX '+ '[ix_'+ convert(varchar(120),tablename+'_X_'+ replace(nm_columns,', ','$')) +']'+ CHAR(10) +
			'	ON '+schemaname+'.'+tablename+' ('+ nm_columns +')'+  CHAR(10) +
			case when isnull(nm_include,'') <> '' then 			
			'	INCLUDE ('+ nm_include +')' else '' end +CHAR(10)+ 
			'	ON INDICES'	+ CHAR(10) + 
			'end'+ CHAR(10) 
			
		from #tmp_indices_unificados_chave
		order by [--nm_comando] desc
	end

	if isnull(@dv_list_depend,0) = 1
	begin
	
		select 
			so.name, sc.text
		into #tmp_objects
		from sys.objects so 
		join sys.schemas s on s.schema_id = so.schema_id
		join sys.syscomments sc	on sc.id = so.object_id
		where so.type in ('P','V')
		and exists (select SchemaName from #tmp_indices_duplicados where SchemaName = s.name)
		and sc.text is not null
		
		select o.name, tmp.OverLappingIndex
		into #tmp_final
		from #tmp_indices_duplicados tmp 
		cross join #tmp_objects o
		where patindex('%'+OverLappingIndex+'%', o.text ) > 0 
		
		select name as 'Object', OverLappingIndex 'FixedIndex' from #tmp_final		
	end
	
END
GO
