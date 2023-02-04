if object_id('tempdb..#tmp_sessions','u') is not null
begin
	drop table #tmp_sessions 
end

create table #tmp_sessions
(
	id_session int
)


DECLARE @user_spid INT
DECLARE CurSPID CURSOR FAST_FORWARD
FOR
	SELECT SPID
	FROM master.dbo.sysprocesses (NOLOCK)
	WHERE spid>50 -- avoid system threads
	AND status='sleeping' -- only sleeping threads
	AND DATEDIFF(HOUR,last_batch,GETDATE())>=24 -- thread sleeping for 24 hours
	AND spid<>@@spid -- ignore current spid
OPEN CurSPID
FETCH NEXT FROM CurSPID INTO @user_spid
WHILE (@@FETCH_STATUS=0)
BEGIN
	PRINT 'Killing '+CONVERT(VARCHAR,@user_spid)
	insert into #tmp_sessions (id_session)
	select @user_spid
FETCH NEXT FROM CurSPID INTO @user_spid
END
CLOSE CurSPID
DEALLOCATE CurSPID
GO

select 
(select text from sys.dm_exec_sql_text(sql_handle)), 
* 

from sys.sysprocesses s
join  #tmp_sessions tmp
on tmp.id_session = s.spid
