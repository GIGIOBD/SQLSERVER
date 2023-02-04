--Verifica o PLE de dentro do SQL Server
SELECT
ple.[Node]
,LTRIM(STR([PageLife_S]/3600))+':'+REPLACE(STR([PageLife_S]%3600/60,2),SPACE(1),'0')+':'+REPLACE(STR([PageLife_S]%60,2),SPACE(1),'0') [PageLife]
,ple.[PageLife_S]
,dp.[DatabasePages] [BufferPool_Pages]
,CONVERT(DECIMAL(15,3),dp.[DatabasePages]*0.0078125) [BufferPool_MiB] ,CONVERT(DECIMAL(15,3),dp.[DatabasePages]*0.0078125/[PageLife_S]) [BufferPool_MiB_S]
FROM
(
SELECT [instance_name] [node],[cntr_value] [PageLife_S] FROM sys.dm_os_performance_counters
WHERE [counter_name] = 'Page life expectancy'
) ple
INNER JOIN
(
SELECT [instance_name] [node],[cntr_value] [DatabasePages] FROM sys.dm_os_performance_counters
WHERE [counter_name] = 'Database pages'
) dp ON ple.[node] = dp.[node]