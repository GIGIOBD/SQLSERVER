select  object_name(object_id) as table_name
,a.name as stats_name
,stats_date(object_id, stats_id) as last_update
from sys.stats a inner join sysobjects o
on a.object_id = o.id
where objectproperty(object_id, 'IsUserTable') = 1
order by last_update desc