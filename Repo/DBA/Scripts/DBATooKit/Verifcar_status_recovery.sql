--Arquivo de transaction log, maior que o arquivo de dados.
--Este problema esta diretamente relacionado ao recovery model e a estratégia de backup utilizada.
--basta realizar o backup.
select
	name, 
	recovery_model_desc
from sys.databases 
order by recovery_model_desc 

/*
MSDB é uma base do sistema que armazera informações de tarefas agendadas (jobs)
*/

select
	bs.database_name,
	case 
	when type = 'D' then 'Database'
	when type = 'I' then 'Differential database'
	when type = 'L' then 'Log'
	when type = 'F' then 'File or Filegroup'
	when type = 'G' then 'Differential File'
	when type = 'P' then 'Partial'
	when type = 'Q' then 'Differential partial'
	end as BackupType,
	max(bs.backup_start_date) as backup_start_date
from sys.sysdatabases sd
left join msdb..backupset bs
on bs.database_name = sd.name 
left join msdb..backupmediafamily bmf
on bs.media_set_id = bmf.media_set_id
group by 
	sd.name,
	bs.type,
	bs.database_name
order by
	 backup_start_date desc,
	 bs.database_name
		
