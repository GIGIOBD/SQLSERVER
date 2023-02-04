select 
	'grant execute on '+s.name+'.'+o.name +' to [i4proinfo\vsilva]'
from sys.objects o join sys.schemas s
on s.schema_id = o.schema_id
where o.type in ('fn')