
	set nocount on

	if OBJECT_ID('tempdb..#comando','u') is not null
	begin
		drop table #comando 
	end

	create table #comando 
	(
		id			int identity primary key,
		nm_comando	varchar(5000)
	)

	insert into #comando (nm_comando)
	SELECT 
		'print ''Refreshing --> '+ s.name + '.' + o.name +''''+ CHAR(10) +
		'EXEC sp_refreshview ['+ s.name + '.' + o.name + ']'	
	FROM sys.objects o
	join sys.schemas s on s.schema_id = o.schema_id
	WHERE o.type = 'V'
	and o.name not in ('t_elemento'  --prt
	, 't_elemento_pagina' --prt
	, 't_parceiro' --prt
	, 'corpvw_pessoas'
	, 't_parceiro_produto'
	, 'corpvw_crm_combined'
	, 'v_pessoas_meio_comunicacao'
	)
	--and o.name = 'v_pessoas_meio_comunicacao'

	declare 
		@qtd		int = (select MAX(id) from #comando),
		@contador	int = 0,
		@nm_comando varchar(5000)

	while @contador <= @qtd
	begin
		select 
			@nm_comando = nm_comando
		from #comando
		where id = @contador

		print(@nm_comando)
		exec(@nm_comando)

		set @nm_comando = ''
		set @contador = @contador + 1
	end
	
	SELECT 
		s.name,
		o.name,
		c.name,	
		o.type_desc,
		c.name, 
		c.collation_name 
	FROM sys.columns c
	join sys.objects o
	on o.object_id = c.object_id
	join sys.schemas s
	on s.schema_id = o.schema_id
	WHERE collation_name <> N'Latin1_General_CI_AS'
	and o.type = 'v'  

	/*
	Refreshing --> dbo.t_elemento
	Msg 208, Level 16, State 1, Procedure sys.sp_refreshsqlmodule_internal, Line 85 [Batch Start Line 0]
	Invalid object name 'prt.t_elemento'.

	Refreshing --> dbo.t_elemento_pagina
	Msg 208, Level 16, State 1, Procedure sys.sp_refreshsqlmodule_internal, Line 85 [Batch Start Line 0]
	Invalid object name 'prt.t_elemento_pagina'.

	Refreshing --> dbo.t_parceiro
	Msg 208, Level 16, State 1, Procedure sys.sp_refreshsqlmodule_internal, Line 85 [Batch Start Line 0]
	Invalid object name 'prt.t_parceiro'.


	Refreshing --> dbo.corpvw_pessoas
	Msg 207, Level 16, State 1, Procedure sys.sp_refreshsqlmodule_internal, Line 85 [Batch Start Line 0]
	Invalid column name 'Nr_ccm'.

	Refreshing --> dbo.t_parceiro_produto
	Msg 208, Level 16, State 1, Procedure sys.sp_refreshsqlmodule_internal, Line 85 [Batch Start Line 0]
	Invalid object name 'prt.t_parceiro_produto'.

	Refreshing --> dbo.corpvw_crm_combined
	Msg 207, Level 16, State 1, Procedure sys.sp_refreshsqlmodule_internal, Line 85 [Batch Start Line 0]
	Invalid column name 'nr_rg'.

	sp_helptext 'rse.v_pessoas_meio_comunicacao'
	View compilada com linked server para o bd xpinvest_erp_head 

	from [xpinvest_erp_head].cad.t_pessoas cp  
	left join [xpinvest_erp_head].cad.t_pessoas_meio_comunicacao cpmc  
	on cpmc.id_pessoa = cp.id_pessoa 
	*/