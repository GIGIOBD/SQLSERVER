
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
		'EXEC sp_recompile ['+ s.name + '.' + o.name + ']'	
	FROM sys.objects o
	join sys.schemas s on s.schema_id = o.schema_id
	WHERE o.type = 'p'
	and s.name not like 'UTS_%'
	and s.name not like 'UTS_%'

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