/*
Identificar tabelas HEAP (sem índice clustered)
Utilizando a consulta abaixo, você poderá identificar as tabelas que não possuem índice clustered criado, 
o que quase sempre, pode representar um possível problema de performance nas consultas, uma vez que os dados 
não estarão ordenados e a utilização de apenas índices Non-Clustered podem acabar gerando muitos eventos de Key Lookup.
*/

SELECT
    B.[name] + '.' + A.[name] AS table_name,
	p.[rows] AS [row_count],
    CAST(ROUND(((SUM(au.total_pages) * 8) / 1024.00), 2) AS NUMERIC(36, 2)) AS [size_mb],
    CAST(ROUND(((SUM(au.used_pages) * 8) / 1024.00), 2) AS NUMERIC(36, 2)) AS [used_mb], 
    CAST(ROUND(((SUM(au.total_pages) - SUM(au.used_pages)) * 8) / 1024.00, 2) AS NUMERIC(36, 2)) AS [unused_mb]
FROM
    sys.tables A
    JOIN sys.schemas B ON A.[schema_id] = B.[schema_id]
    JOIN sys.indexes C ON A.[object_id] = C.[object_id]
	JOIN sys.partitions p 
	ON p.[object_id]  = c.[object_id] 
	AND p.index_id = C.index_id 
    JOIN sys.allocation_units au
	ON au.container_id = p.[partition_id]  
WHERE
    C.[type] = 0 -- = Heap 
GROUP BY 
	B.[name],
	A.[name],
	p.[rows]
ORDER BY    
	row_count desc

	
	