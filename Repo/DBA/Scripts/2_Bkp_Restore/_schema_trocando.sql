declare @db varchar(100), @sql_principal varchar(4000)


declare cur_db cursor for 
	select 
		a.name
	from sys.databases a
	where a.state_desc = 'ONLINE' 
	and a.name not like 'W%'
	and a.name not like 'D%'

--where a.name in(
--'i4proerp')

open cur_db

fetch cur_db into @db

while @@FETCH_STATUS = 0
begin

	set @sql_principal = 'use '+@db+'
		declare cur_name cursor for
		SELECT name FROM  sys.schemas WHERE principal_id between 5 and 16383
		declare  @name varchar(100),@sql varchar(200)
		open cur_name

		fetch cur_name into @name

		while @@fetch_status = 0
		begin

		set @sql ='' ALTER AUTHORIZATION ON SCHEMA::[''+@name+''] to dbo''

		exec (@sql)
		
		fetch next from cur_name into @name
		end
		close cur_name
		deallocate cur_name
		'

		exec (@sql_principal)

		print @sql_principal

		fetch next from cur_db into @db
end
close cur_db
deallocate cur_db

