SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON

	declare 
		@sql varchar(max),
		@dv_script bit = 1

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
		sc.name like '%nm_pessoa%'
		or sc.name like '%nr_cpf%'
		or sc.name like '%nr_cnpj_cpf%'
		or sc.name like '%nr_cnpj%'
		or sc.name like '%razao%'
		or sc.name like '%nome%'
		or sc.name like '%nr_rg%'
		or sc.name like '%nr_inss%'
		or (sc.name like '%comunicacao%' and sc.name not like 'dt%' and st.name not in ('bit','int','smallint'))
		or (sc.name like '%mail%' and st.name not in ('bit','int','smallint'))
		or (sc.name like '%parceiro%' and st.name not in ('bit','int','smallint'))
		)
	and st.name not in ('bit')

	if @dv_script = 1
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
		order by nm_schema, tabela
	end