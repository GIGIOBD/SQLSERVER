/*
Identificar fragmenta��o dos �ndices
Para identificar o n�vel de fragmenta��o dos �ndices e avaliar se � necess�rio realizar um REORGANIZE ou REBUILD, 
utilize o script abaixo. 
*/

SELECT
    C.[name] AS TableName,
    B.[name] AS IndexName,
    A.index_type_desc AS IndexType,
    A.avg_fragmentation_in_percent,
	A.page_count,
    'ALTER INDEX [' + B.[name] + '] ON [' + D.[name] + '].[' + C.[name] + '] REBUILD' AS CmdRebuild
FROM
    sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED')	A
    JOIN sys.indexes B ON B.[object_id] = A.[object_id] AND B.index_id = A.index_id
    JOIN sys.objects C ON B.[object_id] = C.[object_id]
    JOIN sys.schemas D ON D.[schema_id] = C.[schema_id]
WHERE
    A.page_count > 1200
	AND A.avg_fragmentation_in_percent > 30
    AND OBJECT_NAME(B.[object_id]) NOT LIKE '[_]%'
    AND A.index_type_desc != 'HEAP'
ORDER BY
    A.avg_fragmentation_in_percent DESC