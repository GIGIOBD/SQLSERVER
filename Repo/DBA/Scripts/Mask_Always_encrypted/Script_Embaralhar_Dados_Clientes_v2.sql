

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON

	/* @dv_script   0 - Relatório   1 - script */
	declare 
		@sql varchar(max),
		@dv_script bit = 0 -- INFORMAR 0 ou 1 

	if object_id('tempdb..#altera_tab', 'u') is not null
	begin
		drop table #altera_tab
	end

	if object_id('tempdb..#tb_comando', 'u') is not null
	begin
		drop table #tb_comando
	end

	create table  #altera_tab(
		nm_comando varchar(500),
		id_tabela int,
		nm_schema varchar(200),
		tabela varchar(500),
		coluna_alterar varchar(128),
		tp_coluna_alterar bit,
		coluna_identity varchar(128),
		nm_precision int,
		max_length varchar(30))

	create table #tb_comando(
		comando varchar(max))

	insert into #altera_tab(
		nm_comando,
		id_tabela,
		nm_schema,
		tabela,
		coluna_alterar,
		tp_coluna_alterar,
		max_length)
	select 
		'if exists(select * from dbo.sysobjects where id = object_id(N''['+ss.name+'].[' + so.name + ']'') 
		and OBJECTPROPERTY(id, N''IsTable'') = 1)' + char(10) +
		'begin ' ,
		so.id,
		ss.name,
		so.name,
		sc.name,
		case when sc.precision = 0 then 0 else 1 end
		,sc.max_length
	from sysobjects so
	join sys.objects sso
	on sso.object_id = so.id
	join sys.schemas ss
	on ss.schema_id = sso.schema_id
	join sys.columns sc
	on sc.object_id = so.id
	join sys.types st
	on sc.user_type_id = st.user_type_id
	where so.xtype='u'
	and (
		sc.name like '%pessoa%'
		or sc.name like '%cpf%'		
		or sc.name like '%cnpj%'
		or sc.name like '%razao%'
		or sc.name like '%fantasia%'
		or sc.name like '%nome%'
		or sc.name like '%_rg%'
		or sc.name like '%_inss%'
		or sc.name like '%endere%'
		or sc.name like '%cep%'
		or sc.name like '%telefone%' --add
		or sc.name like '%_banco%'
		or sc.name like '%_agencia%'
		or sc.name like '%_corrente%'
		or sc.name like '%_conta'

		or sc.name like '%comunicacao%' 
		or sc.name like '%mail%' 
		or sc.name like '%e-mail%'
		or sc.name like '%parceiro%'
		or sc.name like '%contato%'
		)
	and (sc.name not like 'id_%'	
		and sc.name not like 'dt_%'	
		and sc.name not like 'pe_%'
		and sc.name not like 'vl_%'
		and sc.name not like 'qt_%'
		and sc.name not like 'cd_%'
		and sc.name not like '%_contabil%')	
	and sc.max_length > 1
	and st.name not in ('bit','tinyint','smallint','int','bigint')
	and so.name not in ('t_pp_layout_comunicacao','AF_meio_comunicacao ','AF_modelo_comunicacao') --vereficar bug !!!
	
	
	if @dv_script = 0
	begin
		update at
			set coluna_identity = sc.name
		from #altera_tab at join sys.columns sc
		on at.id_tabela = sc.object_id
		where sc.column_id = 1

		insert into #tb_comando(comando)
		select nm_comando+char(10)+'update '+nm_schema+'.'+tabela+char(10)+'set '+coluna_alterar+' ='+
			case when tp_coluna_alterar=1 
				then coluna_identity+'+99*2'+char(10)+'end'
				else 'convert(varchar('+ 
				        case when max_length = -1 then '30' else max_length end 
					  +'), convert(varchar(36),newid()))'+char(10)+'end'
			end		
		from #altera_tab

		print ('SET NOCOUNT ON')
		print ('SET ANSI_WARNINGS OFF')
		
		declare cur_tab cursor for select comando from #tb_comando
		open cur_tab

		fetch cur_tab into @sql

		while @@fetch_status = 0
		begin
		
			print (@sql)
			
			fetch next from cur_tab into @sql
			
		end
		close cur_tab 
		deallocate cur_tab
	end
	else
	begin
		select 
			nm_schema,
			tabela,
			coluna_alterar,
			max_length
		from #altera_tab
		--order by nm_schema, tabela
		order by coluna_alterar
	end


