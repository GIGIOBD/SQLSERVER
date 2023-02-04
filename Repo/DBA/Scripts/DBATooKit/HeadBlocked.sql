if object_id('tempdb..#temp_table','u') is not null
	begin
		drop table #temp_table
	end
else
set nocount on
go

select 
	spid, blocked, replace( replace( t.text, char(10), ' '), char(13), ' ') as batch
into #temp_table
from sys.sysprocesses r
cross apply sys.dm_exec_sql_text(R.sql_handle) t
GO

with blockers (spid, blocked, level, batch)
as
(select
	spid,
	blocked,
	cast(replicate('0', 4- len(cast (SPID as varchar))) + cast(spid as varchar) as varchar(1000)) as level,
	batch 
from #temp_table R
where (blocked = 0 or blocked = spid)
and exists (select * from #temp_table R2 where R2.blocked = r.spid and R2.blocked <> R2.spid)
union all

select
	R.spid,
	R.blocked,
	cast(blockers.level + right(cast ((1000 + R.SPID) as varchar(100)), 4) as varchar(1000)) as level,
	R.batch 
from #temp_table R
inner join blockers 
on r.blocked = blockers.spid where r.blocked > 0 and r.blocked <> R.spid
)

select
	N' ' + replicate(N'| ', len(level)/4 -1) +
	case when (len(level)/4 - 1) = 0
	then 'HEAD - '
	else '|------' END
	+ cast(spid as nvarchar(10)) + N' '+ batch as blocking_tree
from blockers 
order by level asc
GO