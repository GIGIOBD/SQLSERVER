set transaction isolation level read uncommitted

DECLARE
	@where				varchar(4000) = null,
	@orderby			varchar(50) = null,	
	@cd_usuario			varchar(50) = null,
	@cd_retorno			int			= null ,
	@nm_retorno			varchar(50)	= null ,
	@nr_versao_proc		varchar(50)	= null

	set transaction isolation level read uncommitted
	set nocount on 

	set @nr_versao_proc = LTRIM(RTRIM(REPLACE(REPLACE('$Revision: 1.1 $','Revision:',''),'$','')))

	declare @nm_proc			varchar(50) = '[dba].[p_cons_fk_sem_indice]'

	if @where like '%1=2%' 
	begin
		select
			nm_schema_name			= convert(varchar(500),null),
			nm_tabela_filha			= convert(varchar(500),null),
			nm_coluna_filha			= convert(varchar(500),null),
			nm_constraint_indice	= convert(varchar(500),null),
			nm_tabela_pai			= convert(varchar(500),null),
			nm_coluna				= convert(varchar(500),null),
			nm_esquema				= convert(varchar(500),null)					
		where 1=2
		return
	end

	declare
		@nm_tabela_filha		varchar(500),	
		@nm_coluna_filha		varchar(500),
		@nm_constraint_indice	varchar(3000)
	
	set @where = replace(@where,'nm_tabela_filha='		,'nm_tabela_filha like ')
	set @where = replace(@where,'nm_coluna_filha='		,'nm_coluna_filha like ')
	set @where = replace(@where,'nm_constraint_indice='	,'nm_constraint_indice like ')
	set @where = replace(@where,''' and','%'' and ')
	
	set @nm_tabela_filha		= Convert(varchar(500), dbo.corpfc_extrai_valor_where_like(@where, 'nm_tabela_filha'))
	set @nm_coluna_filha		= Convert(varchar(500), dbo.corpfc_extrai_valor_where_like(@where, 'nm_coluna_filha'))
	set @nm_constraint_indice	= Convert(varchar(500), dbo.corpfc_extrai_valor_where_like(@where, 'nm_constraint_indice'))
	
	--retirar aspas simples do ultimo caracter
	set @nm_tabela_filha		= SUBSTRING(@nm_tabela_filha,1,len(@nm_tabela_filha)-1)
	set @nm_coluna_filha		= SUBSTRING(@nm_coluna_filha,1,len(@nm_coluna_filha)-1)
	set @nm_constraint_indice	= SUBSTRING(@nm_constraint_indice,1,len(@nm_constraint_indice)-1)

	-- Montando as fks
	declare 
		@tab_atu	varchar(255),
		@tab_ant	varchar(255),
		@ind_ant	varchar(255),
		@ind_atu	varchar(255),
		@col		varchar(255),
		@idx		varchar(500),
		@cmd		varchar(700),
		@base_dados	varchar(255),
		@sql		varchar(max)


	IF OBJECT_ID('TEMPDB..#fk', 'U') IS NOT NULL
	begin
		drop table #fk		
	end
	create table #fk
	(
		nm_schema_name			varchar(500),
		nm_tabela_filha			varchar(500),
		nm_coluna_filha			varchar(500),
		nm_constraint_indice	varchar(500),
		nm_tabela_pai			varchar(500),
		nm_coluna				varchar(500),
		nm_esquema				varchar(500)
	)

	insert into #fk (
		nm_schema_name			,
		nm_tabela_filha		,
		nm_coluna_filha		,
		nm_constraint_indice	,
		nm_tabela_pai			,
		nm_coluna				,
		nm_esquema				)
	select distinct 
		s.name as schema_name,
		fil.name tabela_filha,
		col.name as coluna_filha,
		obj.name constraint_indice,
		pai.name tabela_pai,
		REPLICATE(' ',500) coluna,
		s.name as esquema	
	from sys.tables fil 
	inner join sys.columns col		
		on col.object_id = fil.object_id	
	inner join 	sys.foreign_key_columns fkc
		on fil.object_id = fkc.parent_object_id		
	and col.column_id = fkc.parent_column_id	
	inner join sys.tables pai
		on 	pai.object_id = fkc.referenced_object_id
	inner join sysobjects obj
		on fkc.constraint_object_id = obj.id	
	inner join sys.schemas s
		on fil.schema_id = s.schema_id
	where fil.name = 'corp_auto_itens'

	declare cur_fk cursor for 
	
		select 
			f.nm_tabela_filha,
			f.nm_constraint_indice,
			col.name 
		from sys.tables fil 
		inner join sys.columns col		
			on col.object_id = fil.object_id	
		inner join sys.types typ
			on col.user_type_id = typ.user_type_id
		inner join 	sys.foreign_key_columns fkc
			on fil.object_id = fkc.parent_object_id		
			and col.column_id = fkc.parent_column_id	
		inner join sysobjects obj
			on fkc.constraint_object_id = obj.id
		inner join #fk f
			on f.nm_tabela_filha = fil.name
			and f.nm_constraint_indice = obj.name 		
			
	open cur_fk
	fetch cur_fk into @tab_atu, @ind_atu, @col

	while @@FETCH_STATUS = 0	
	begin 
	
		if @tab_atu = @tab_ant and @ind_atu = @ind_ant 
		begin			
			set @idx = @idx+','+@col		
		end
		else
		begin		
			set @idx = @col		
		end
		
		select 
			@tab_ant = @tab_atu,
			@ind_ant = @ind_atu
			
		update #fk
			set nm_coluna = @idx
		where nm_tabela_filha = @tab_atu
		and nm_constraint_indice = @ind_atu
		
		fetch next from cur_fk into @tab_atu, @ind_atu, @col
			
	end
		
	close  cur_fk
	deallocate cur_fk

	-- Indices
	-- tabela para armazenarmos os indices

	IF OBJECT_ID('TEMPDB..#ind', 'U') IS NOT NULL
	begin
		drop table #ind
	end

	create table #ind
	(
		base_dados			varchar(255),
		tabela				varchar(255),
		constraint_indice	varchar(255),
		coluna				varchar(510)
	)
	
	IF OBJECT_ID('TEMPDB..#ind_full', 'U') IS NOT NULL
	begin
		drop table #ind_full
	end

	create table #ind_full
	(
		base_dados			varchar(255),
		tabela				varchar(255),
		constraint_indice	varchar(255),
		coluna				varchar(510)
	)

	declare cur_base cursor for 		
		select 
			name
		from sys.databases 
		where name = DB_NAME()
						
	open cur_base

	fetch cur_base into @base_dados

	while @@fetch_status = 0 
	begin 	
		-- Inserindo as colunas dos indices	
		set @cmd = 'select distinct '+''''+@base_dados+''', ob.name tabela,ix.name Constraint_indice
					from ' +@base_dados+'.'+'sys.tables ob 
						inner join '+@base_dados+'.'+'sys.indexes ix
							on ob.object_id = ix.object_id
						inner join '+@base_dados+'.'+'sys.index_columns ic
							on	ob.object_id = ic.object_id
							and	ix.index_id = ic.index_id
						inner join '+@base_dados+'.'+'sys.columns c
							on	ob.object_id = c.object_id'
			
		insert into #ind(base_dados,tabela,constraint_indice)
		exec (@cmd)
		
		-- Verificando quais colunas pertencem ao indice	
		declare cur_ind cursor for		
		select 
			ob.name tabela,
			ix.name Constraint_indice, 
			c.name coluna
		from sys.tables ob 
		inner join sys.indexes ix
			on ob.object_id = ix.object_id
		inner join sys.index_columns ic
			on	ob.object_id = ic.object_id
			and	ix.index_id = ic.index_id
		inner join sys.columns c
			on	ob.object_id = c.object_id
			and ic.column_id = c.column_id
		inner join #ind ind
			on ob.name = ind.tabela
			and ix.name = ind.Constraint_indice
				
		open cur_ind
	
		fetch cur_ind into @tab_atu, @ind_atu, @col
	
		while @@FETCH_STATUS = 0	
		begin 	
			if @tab_atu = @tab_ant and @ind_atu = @ind_ant 
			begin				
				set @idx = @idx+','+@col							
			end
			else
			begin			
				set @idx = @col							
			end
			
			select 
				@tab_ant = @tab_atu,
				@ind_ant = @ind_atu
			
			update #ind
			set coluna = @idx
			where tabela = @tab_atu
			and constraint_indice = @ind_atu
			and base_dados = @base_dados
			
			fetch next from cur_ind into @tab_atu, @ind_atu, @col						
		end
			
		close  cur_ind
		deallocate cur_ind
		
		fetch next from cur_base into @base_dados
		
		insert into #ind_full
		(
			base_dados,
			tabela,
			constraint_indice,
			coluna
		)
		select 
			base_dados,
			tabela,
			constraint_indice,
			coluna 
		from #ind		
		truncate table #ind				
	end
	
	close cur_base
	deallocate cur_base

	-- Mostrando as fks que n�o est�o indexadas
	select 
		a.nm_schema_name		,
		a.nm_tabela_filha		,
		a.nm_coluna_filha		,
		a.nm_constraint_indice	,
		a.nm_tabela_pai		,
		a.nm_coluna			,
		a.nm_esquema				
	from #fk a
	where not exists(select 1 from #ind_full b
					where a.nm_tabela_filha = b.tabela
					and a.nm_coluna = b.coluna)
	and nm_tabela_filha			like	isnull(@nm_tabela_filha,		nm_tabela_filha)
	and nm_coluna_filha			like	isnull(@nm_coluna_filha,		nm_coluna_filha)
	and nm_constraint_indice	like	isnull(@nm_constraint_indice,	nm_constraint_indice)


