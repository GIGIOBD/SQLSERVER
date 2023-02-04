select s.name sch_name,so.name as tabela,  b.name as indice,a.*
into #temp
FROM sys.dm_db_index_physical_stats (DB_ID(), NULL, NULL, NULL, NULL) AS a
inner JOIN sys.indexes AS b 
ON a.object_id = b.object_id 
AND a.index_id = b.index_id
	inner join sysobjects so 
	on so.id = b.object_id
	and so.type = 'U'
	inner join sys.schemas s
	on so.uid=s.schema_id
where so.name not in('corp_lancamento_contabil','t_log_operacao_campo','corp_acompanha_rotina','t_servico_log_chamada')

-- page count tem que ser maior que 1500 para considerarmos a fragmentação
select sch_name,tabela,indice,avg_fragmentation_in_percent,page_count
from #temp
where avg_fragmentation_in_percent > 15
order by page_count desc


