/*
Identifica a execu��o de comandos DBCC
Utilizando o default trace, conseguimos identificar a ocorr�ncia de comandos DBCC executados na inst�ncia, como CHECKDB
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