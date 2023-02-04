/*
Identifica a execução de comandos DBCC
Utilizando o default trace, conseguimos identificar a ocorrência de comandos DBCC executados na instância, como CHECKDB
*/
DECLARE @path VARCHAR(MAX) = (SELECT [path] FROM sys.traces WHERE is_default = 1)

SELECT
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
    EventClass IN ( 116 )
ORDER BY
    StartTime DESC