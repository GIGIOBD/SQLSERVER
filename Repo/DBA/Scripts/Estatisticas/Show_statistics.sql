dbcc show_statistics ('t_table_heap','_WA_Sys_00000001_5AEE82B9')
with histogram

select * from sys.stats
where object_id = object_id('dbo.t_table_heap')


