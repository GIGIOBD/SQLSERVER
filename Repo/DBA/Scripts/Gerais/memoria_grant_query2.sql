SELECT 
	 mg.session_id
	,mg.granted_memory_kb
	,mg.requested_memory_kb
	,mg.ideal_memory_kb
	,mg.request_time
	,mg.grant_time
	,mg.query_cost
	,mg.dop
	,st.[TEXT]
	,qp.query_plan
FROM sys.dm_exec_query_memory_grants AS mg
CROSS APPLY sys.dm_exec_sql_text(mg.plan_handle) AS st
CROSS APPLY sys.dm_exec_query_plan(mg.plan_handle) AS qp
where session_id <> @@SPID
ORDER BY mg.required_memory_kb DESC;

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