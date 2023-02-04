SELECT [object_name]
    ,[counter_name]
    ,[cntr_value] 
FROM sys.dm_os_performance_counters
WHERE [object_name] LIKE '%Manager%'
AND [counter_name] = 'Page life expectancy'
GO

WITH 
    tm_cte AS (
        SELECT CONVERT(int, value_in_use) / 1024. [memory_gb],
            CONVERT(int, value_in_use) / 1024. / 4. * 300 [counter_by_memory]
        FROM sys.configurations
        WHERE name like 'max server memory%'
    ),
    cached_cte AS (
        SELECT 
        COUNT(*) * 8. / 1024. / 1024. [cached_gb],
            COUNT(*) * 8. / 1024. / 1024.  / 4. * 300 [counter_by_cache]
        FROM [sys].[dm_os_buffer_descriptors]
)
SELECT CEILING(counter_by_memory) [Limite 1],
    CEILING(counter_by_cache) [Limite 2]
FROM tm_cte, cached_cte;