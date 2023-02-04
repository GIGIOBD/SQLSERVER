SELECT a.session_id,start_time,
       (total_elapsed_time/1000/60) AS MinutesRunning,
       percent_complete,
       command,
       b.name AS DatabaseName,
              -- MASTER will appear here because the database is not accesible yet.
       DATEADD(ms,estimated_completion_time,GETDATE()) AS StimatedCompletionTime,
      (estimated_completion_time/1000/60) AS MinutesToFinish
FROM  sys.dm_exec_requests a
          INNER JOIN sys.DATABASES b ON a.database_id = b.database_id
WHERE command LIKE '%restore%'
          OR command LIKE '%backup%'
          AND estimated_completion_time > 0

SELECT
session_id as SPID,
command, s.text AS Query,
start_time,
percent_complete,
dateadd(second,estimated_completion_time/1000, getdate()) as estimated_completion_time
FROM sys.dm_exec_requests r
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) s
WHERE r.command in ('BACKUP DATABASE','RESTORE DATABASE')
GO