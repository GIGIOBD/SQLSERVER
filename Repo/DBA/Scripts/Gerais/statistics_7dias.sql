/*
Estat�sticas h� mais de 7 dias sem atualizar
Com a consulta abaixo, faremos algumas consultas nas views relacionada �s estat�sticas de colunas e �ndices e poderemos 
visualizar as estat�sticas que est�o h� mais de 7 dias sem atualiza��es. Estat�stica desatualizada pode causar muitos 
problemas de performance, mas tamb�m n�o � necess�rio atualizar a estat�stica se n�o houveram atualiza��es de dados.
*/

SELECT
    D.last_updated AS [LastUpdate],
    B.[name] AS [Table],
    A.[name] AS [Statistic],
    D.modification_counter AS ModificationCounter,
    'UPDATE STATISTICS [' + E.[name] + '].[' + B.[name] + '] [' + A.[name] + '] WITH FULLSCAN' AS UpdateStatisticsCommand
FROM
    sys.stats A
    JOIN sys.objects B ON A.[object_id] = B.[object_id]
    JOIN sys.indexes C ON C.[object_id] = B.[object_id] AND A.[name] = C.[name]
    OUTER APPLY sys.dm_db_stats_properties(A.[object_id], A.stats_id) D
    JOIN sys.schemas E ON B.[schema_id] = E.[schema_id]
WHERE
    D.last_updated < GETDATE() - 7
    AND E.[name] NOT IN ( 'sys', 'dtp' )
    AND B.[name] NOT LIKE '[_]%'
    AND D.modification_counter > 1000
ORDER BY
    D.modification_counter DESC