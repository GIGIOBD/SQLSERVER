SELECT
	DM_ES.Session_ID,
	DM_ES.Login_time,
	DM_ES.Host_Name,
	DM_ES.Program_Name,
	DM_ES.Login_name,
	DM_ES.Status,
	DM_ES.CPU_Time,
	DM_ES.Memory_usage,
	DM_ES.Total_Elapsed_Time,
	DM_ES.Reads,
	DM_ES.Writes,
	DM_ES.Logical_Reads,
	DM_ES.Transaction_Isolation_Level ,
	DM_EX1.Num_Reads AS NumPckReadCnx, --Number of packet reads that have occurred over this connection. Is nullable
	DM_EX1.Num_Writes AS NumPckWritCNX,--Number of data packet writes that have occurred over this connection. Is nullable.
	DM_EX1.Net_Transport,
	DM_EX1.Net_Packet_Size,
	DM_EX1.Last_Read, 
	DM_EX1.Last_Write,
	DM_EX1.Client_Net_Address,
	db_name (DM_ES.Database_Id) as DbName,
	DM_EX1.Local_Net_Address,
	(CASE DM_ES.transaction_isolation_level  
	WHEN 0 THEN 'Unspecified'
	WHEN 1 THEN 'ReadUncomitted'
	WHEN 2 THEN 'ReadCommitted'
	WHEN 3 THEN 'Repeatable'
	WHEN 4 THEN 'Serializable'
	WHEN 5 THEN 'Snapshot' END)AS Transaction_Isolation_Level,
	  DM_Er.Row_Count as NumRowsMoment,
	DM_ES.UnsuccessFul_Logons,
	DM_ER.lock_timeout,
	(SELECT [Text] FROM master.sys.dm_exec_sql_text(DM_EX1.most_recent_sql_handle )) as sqlscript

FROM  sys.dm_exec_connections AS DM_EX1 
LEFT JOIN  sys.dm_exec_connections AS DM_EX2 ON DM_EX1.parent_connection_id = DM_EX2.connection_id 
LEFT JOIN  sys.dm_exec_sessions AS DM_ES ON DM_ES.session_id   = DM_EX1.session_id 
LEFT JOIN  sys.dm_exec_requests AS DM_ER ON DM_EX1.connection_id   = DM_ER.connection_id
LEFT JOIN  sys.dm_broker_connections AS DM_BC ON DM_EX1.connection_id   = DM_BC.connection_id
OUTER APPLY  sys.dm_exec_sql_text(sql_handle)AS st
order by DM_ES.Total_Elapsed_Time desc, NumPckWritCNX desc,NumPckReadCnx desc