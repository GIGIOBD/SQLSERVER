
if object_id ('tempdb..#tmp_permissoes','u') is not null
begin
	drop table #tmp_permissoes 
end

create table #tmp_permissoes
(
	nm_database			varchar(50),
	nm_owner			varchar(50),
	nm_object			varchar(500),
	nm_grantee			varchar(50),
	nm_grantor			varchar(50),
	nm_protecttype		varchar(50),
	nm_action			varchar(50),
	nm_column			varchar(50)
)

declare @db varchar(100), @sql_principal varchar(4000)

declare cur_db cursor for 
	select 
		a.name
	from sys.databases a
	where a.state_desc = 'ONLINE' 
	and a.name not like 'W%'
	and a.name not like 'D%'
	--and a.name = 'dba_relatorio'

--where a.name in(
--'i4proerp')

open cur_db

fetch cur_db into @db

while @@FETCH_STATUS = 0
begin

	set @sql_principal = 'use '+@db+'
		insert into #tmp_permissoes (nm_owner, nm_object, nm_grantee, nm_grantor, nm_protecttype, nm_action, nm_column)
		EXEC dbo.sp_helprotect 

		update tmp
			set tmp.nm_database = '''+@db+'''
		from #tmp_permissoes tmp
		where tmp.nm_database is null
		'

		exec (@sql_principal)

		print @sql_principal

		fetch next from cur_db into @db
end
close cur_db
deallocate cur_db



select  * from #tmp_permissoes