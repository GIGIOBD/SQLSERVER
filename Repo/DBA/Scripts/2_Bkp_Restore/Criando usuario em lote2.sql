declare @db varchar(100), @sql varchar(500)

declare cur_db cursor for select name from sys.databases where name like'%_head' and state_desc = 'ONLINE'

open cur_db

fetch cur_db into @db

while @@fetch_status = 0
begin

	set @sql='use '+@db+' 
	if  not exists(select 1 from sysusers 
	where name=''I4PROINFO\g-sql-edn_coordenacao'') 
	begin
		create user [I4PROINFO\g-sql-edn_coordenacao] 
		for login [I4PROINFO\g-sql-edn_coordenacao] with default_schema=[dbo]
	end'
	
	print (@sql)
	
	
	set @sql='use '+@db+' exec sp_addrolemember db_owner,[I4PROINFO\g-sql-edn_coordenacao]'
	--db_datareader
	print (@sql)

	fetch next from cur_db into @db


end
close cur_db
deallocate cur_db