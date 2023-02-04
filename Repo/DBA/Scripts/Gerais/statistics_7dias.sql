/*
Estatísticas há mais de 7 dias sem atualizar
Com a consulta abaixo, faremos algumas consultas nas views relacionada às estatísticas de colunas e índices e poderemos 
visualizar as estatísticas que estão há mais de 7 dias sem atualizações. Estatística desatualizada pode causar muitos 
problemas de performance, mas também não é necessário atualizar a estatística se não houveram atualizações de dados.
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