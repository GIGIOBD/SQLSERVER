select
	des.session_id as [Session_ID],
	db_name(des.database_id) as [Database],
	HOST_NAME as [System name],
	program_name,
	login_name,
	status,
	cpu_time as [CPU time (in milisec)],
	total_scheduled_time as [Total scheduled TIME (in milisec)],
	total_elapsed_time as [Total Elapsed Time (in milisec)],
	(memory_usage * 8) as [Memomry USAGE (in kb)],
	(user_objects_alloc_page_count * 8) as [Space allocated FOr User Objects (in Kb)],
	(user_objects_dealloc_page_count * 8) as [Space Deallocated FOr User Objects (in Kb)],
	(internal_objects_alloc_page_count * 8) as [Space allocated FOr Internal Objects (in Kb)],
	(internal_objects_dealloc_page_count * 8) as [Space Deallocated FOr Internal Objects (in Kb)],
	case is_user_process 
		when 1 then 'use session'
		when 0 then 'system session'
	end as [Session_type],
	row_count as [Row count]
from sys.dm_db_session_space_usage ddsu
inner join sys.dm_exec_sessions des
on ddsu.session_id = des.session_id
where des.session_id >40
order by user_objects_alloc_page_count desc