SELECT 
A.job_id,
A.[name] AS job_name,
B.[name] AS [user_name],
B.[sid]
FROM
msdb.dbo.sysjobs A
LEFT JOIN sys.server_principals B ON A.owner_sid = B.[sid]

select A.database_id, A.name, A.owner_sid, B.name, B.sid from sys.databases A
LEFT JOIN sys.server_principals B ON A.owner_sid = B.[sid]
where database_id > 4 and state_desc='online' 
and b.name = 'I4PROINFO\ashinoda'


GO

declare @sql varchar(200), @db varchar(200)

declare cur_db cursor for select A.name from sys.databases A
									LEFT JOIN sys.server_principals B ON A.owner_sid = B.[sid]
									where database_id > 4 and state_desc='online' 
									and b.name = 'I4PROINFO\ashinoda'

open cur_db

fetch cur_db into @db

while @@fetch_status = 0
begin

--set @sql='use master alter database '+@db+' set trustworthy on'
--exec (@sql)

--set @sql ='use '+@db+' exec sp_configure ''clr enabled'',1;reconfigure'

--exec (@sql)

set @sql ='use '+@db+' exec sp_changedbowner ''sa'''
exec (@sql)

--set @sql='use '+@db+' alter database '+@db+'  set trustworthy on'

exec (@sql)





fetch next from cur_db into @db

end
close cur_db
deallocate cur_db



DECLARE 
    @CmdUpdateJob VARCHAR(MAX) = '',
    @LoginDestino VARCHAR(100) = 'sa'
 
 
SELECT @CmdUpdateJob += '
EXEC msdb.dbo.sp_update_job @job_id = ''' + CAST(A.job_id AS VARCHAR(50)) + ''', @owner_login_name = ''' + @LoginDestino + ''';'
FROM
    msdb.dbo.sysjobs A
 
 --select @CmdUpdateJob
 EXEC(@CmdUpdateJob)

 GO

 SELECT 
A.job_id,
A.[name] AS job_name,
B.[name] AS [user_name],
B.[sid]
FROM
msdb.dbo.sysjobs A
LEFT JOIN sys.server_principals B ON A.owner_sid = B.[sid]

select A.database_id, A.name, B.name, B.sid from sys.databases A
LEFT JOIN sys.server_principals B ON A.owner_sid = B.[sid]
where database_id > 4 and state_desc='online'


--kill_all null,'i4proinfo\ashinoda'
--drop login [i4proinfo\ashinoda];
