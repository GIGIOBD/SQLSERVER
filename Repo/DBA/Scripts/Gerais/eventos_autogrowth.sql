/*
Identifica eventos de auto growth
Utilizando o default trace, conseguimos identificar a ocorrência de eventos de autogrowth na instância, isto é, 
quando o SQL Server alocou dinamicamente mais espaço nos arquivos à medida que isso foi necessário para alocar novos dados
*/

DECLARE 
    @Ds_Arquivo_Trace VARCHAR(500) = (SELECT [path] FROM sys.traces WHERE is_default = 1)
    
DECLARE
    @Index INT = PATINDEX('%\%', REVERSE(@Ds_Arquivo_Trace))
 
DECLARE
    @Nm_Arquivo_Trace VARCHAR(500) = LEFT(@Ds_Arquivo_Trace, LEN(@Ds_Arquivo_Trace) - @Index) + '\log.trc'
 
 
SELECT
    A.DatabaseName,
    A.[Filename],
    ( A.Duration / 1000 ) AS 'Duration_ms',
    A.StartTime,
    A.EndTime,
    ( A.IntegerData * 8.0 / 1024 ) AS 'GrowthSize_MB',
    A.ApplicationName,
    A.HostName,
    A.LoginName
FROM
    ::fn_trace_gettable(@Nm_Arquivo_Trace, DEFAULT) A
WHERE
    A.EventClass >= 92
    AND A.EventClass <= 95
    AND A.ServerName = @@servername 
ORDER BY
    A.StartTime DESC