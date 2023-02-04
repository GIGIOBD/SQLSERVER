
SELECT
[s].[name] AS [Schema],
  [o].[name] AS [Object],
  [p].[index_id],
  [i].[name] AS [Index],
  [i].[type_desc] AS [Type],
  (DPCount + CPCount) * 8 / 1024 AS [TotalMB],
  ([DPFreeSpace] + [CPFreeSpace]) / 1024 / 1024 AS [FreeSpaceMB],
  CAST (ROUND (100.0 * (([DPFreeSpace] + [CPFreeSpace]) / 1024) /
(([DPCount] + [CPCount]) * 8), 1) AS DECIMAL (4, 1)) AS [FreeSpacePC]
FROM
  (SELECT
    allocation_unit_id,
    SUM (CASE WHEN ([is_modified] = 1)
      THEN 1 ELSE 0 END) AS [DPCount], 
    SUM (CASE WHEN ([is_modified] = 1)
      THEN 0 ELSE 1 END) AS [CPCount],
    SUM (CASE WHEN ([is_modified] = 1)
      THEN CAST ([free_space_in_bytes] AS BIGINT) ELSE 0 END) AS [DPFreeSpace], 
    SUM (CASE WHEN ([is_modified] = 1)
      THEN 0 ELSE CAST ([free_space_in_bytes] AS BIGINT) END) AS [CPFreeSpace]
  FROM sys.dm_os_buffer_descriptors
  WHERE [database_id] = DB_ID ()
  GROUP BY [allocation_unit_id]) AS [buffers]
INNER JOIN sys.allocation_units AS [au]
  ON [au].[allocation_unit_id] = [buffers].[allocation_unit_id]
INNER JOIN sys.partitions AS [p]
  ON [au].[container_id] = [p].[partition_id]
INNER JOIN sys.indexes AS [i]
  ON [i].[index_id] = [p].[index_id] AND [p].[object_id] = [i].[object_id]
INNER JOIN sys.objects AS [o]
  ON [o].[object_id] = [i].[object_id]
INNER JOIN sys.schemas AS [s]
  ON [s].[schema_id] = [o].[schema_id]
WHERE [o].[is_ms_shipped] = 0
--AND [p].[object_id] > 100 AND ([DPCount] + [CPCount]) > 12800 -- Taking up more than 100MB
ORDER BY [FreeSpaceMB] DESC;
