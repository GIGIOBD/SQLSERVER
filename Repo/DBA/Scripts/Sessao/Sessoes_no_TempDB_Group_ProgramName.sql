/* Sessões ativas no Tempdb */
	SELECT
		count(dms.session_id),
	    program_name AS [Program Name]	       
	FROM sys.dm_db_session_space_usage dds
	INNER join sys.dm_exec_sessions dms
	ON dds.session_id = dms.session_id		
	where dms.login_name not in ('sa')
	and dms.is_user_process = 1
	group by program_name
	order by program_name