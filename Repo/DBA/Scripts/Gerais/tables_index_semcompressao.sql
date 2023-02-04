/*
Tabelas e �ndices
Nessa sess�o vou compartilhar alguns scripts relacionados a consultas em tabelas e �ndices, 
como identificar tabelas HEAP, �ndices fragmentados, etc..
Leitura recomendada: S�rie de Performance Tuning

Identificar tabelas e �ndices sem compress�o
Utilizando a consulta abaixo, vamos identificar as tabelas e �ndices no modo RowStore que n�o est�o utilizando 
compress�o de dados. Vale lembrar que at� a vers�o 2016, esse recurso era exclusivo da vers�o Enterprise 
(al�m da Trial e Developer), ent�o se a sua vers�o for inferir ao 2016 e na edi��o Standard, 
esse script n�o ser� �til para voc�.*/

SELECT DISTINCT 
    C.[name] AS [Schema],
    A.[name] AS Tabela,
    NULL AS Indice,
    'ALTER TABLE [' + C.[name] + '].[' + A.[name] + '] REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = PAGE)' AS Comando
FROM 
    sys.tables                   A
    INNER JOIN sys.partitions    B   ON A.[object_id] = B.[object_id]
    INNER JOIN sys.schemas       C   ON A.[schema_id] = C.[schema_id]
WHERE 
    B.data_compression_desc = 'NONE'
    AND B.index_id = 0 -- HEAP
    AND A.[type] = 'U'
    
UNION
 
SELECT DISTINCT 
    C.[name] AS [Schema],
    B.[name] AS Tabela,
    A.[name] AS Indice,
    'ALTER INDEX [' + A.[name] + '] ON [' + C.[name] + '].[' + B.[name] + '] REBUILD PARTITION = ALL WITH ( STATISTICS_NORECOMPUTE = OFF, ONLINE = OFF, SORT_IN_TEMPDB = OFF, DATA_COMPRESSION = PAGE)'
FROM 
    sys.indexes                  A
    INNER JOIN sys.tables        B   ON A.[object_id] = B.[object_id]
    INNER JOIN sys.schemas       C   ON B.[schema_id] = C.[schema_id]
    INNER JOIN sys.partitions    D   ON A.[object_id] = D.[object_id] AND A.index_id = D.index_id
WHERE
    D.data_compression_desc =  'NONE'
    AND D.index_id <> 0
    AND A.[type] IN (1, 2) -- CLUSTERED e NONCLUSTERED (Rowstore)
    AND B.[type] = 'U'
ORDER BY
    Tabela,
    Indice