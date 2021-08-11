declare 
	@user varchar(100), 
	@sql varchar(500),
	@nm_db varchar(100) = '[nome do banco]'

declare cur_db cursor for 
	select name 
	from sysusers 
	where name not like 'db_%'
	and name not like 'sys'

open cur_db

fetch cur_db into @user

while @@fetch_status = 0
begin
	
	set @sql='use '+@nm_db+' exec sp_addrolemember db_datareader,['+@user+']'
	--db_datareader
	print (@sql)

	fetch next from cur_db into @user


end
close cur_db
deallocate cur_db