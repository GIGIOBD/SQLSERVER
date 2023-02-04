/*
Identifica quando backups foram gerados ou restaurados
Utilizando o default trace, conseguimos identificar a ocorrência de comandos de BACKUP e RESTORE na instância. 
*/

DECLARE @path VARCHAR(MAX) = (SELECT [path] FROM sys.traces WHERE is_default = 1)

SELECT
	EventClass,
    TextData,
    Duration,
    StartTime,
    EndTime,
    SPID,
    ApplicationName,
    LoginName
FROM
    sys.fn_trace_gettable(@path, DEFAULT)
WHERE
    EventClass IN ( 115 )
ORDER BY
    StartTime DESC

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