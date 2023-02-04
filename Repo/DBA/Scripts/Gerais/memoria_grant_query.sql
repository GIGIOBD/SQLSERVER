select
	session_id,
	sp.dbid,
	sp.loginame,
	sp.program_name,
	sp.sql_handle,
	granted_memory_kb,
	granted_memory_kb / 1024 as granted_memory_mb,
	used_memory_kb,
	used_memory_kb / 1024 as used_memory_mb,
	ideal_memory_kb,
	ideal_memory_kb / 1024 as ideal_memory_mb
from sys.dm_exec_query_memory_grants deq
join sys.sysprocesses sp on sp.spid = deq.session_id

--declare @i  int = 1
--while @i < 1000000
--begin
--	set @i = @i + 1
--	select nr_endosso from corp_endosso 
--	where cd_tipo_endosso = 0
--	order by id_endosso desc
--	option (maxdop 1)
--end

--sp_whoisactive
----@get_outer_command = 1,
----@get_transaction_info = 1,
----@get_task_info = 1,
----@get_locks = 1,
----@get_avg_time = 1,
--@get_additional_info = 1
