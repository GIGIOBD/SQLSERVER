
select distinct top 30 s.name,lower(a.name),b.row_count,db_name()
FROM sys.tables a
join sys.dm_db_partition_stats b
on a.object_id = b.object_id
join sys.schemas s
on a.schema_id = s.schema_id
where b.row_count > 0
and a.name like '%_old'
order by 3 desc
