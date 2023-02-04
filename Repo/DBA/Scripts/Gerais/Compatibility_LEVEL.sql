select 
	database_id, 
	name,  
	state,
	state_desc,	
	compatibility_level,
	collation_name,	
	recovery_model_desc,
	command = 'ALTER DATABASE '+name+'  
	SET COMPATIBILITY_LEVEL = 150;'  
from sys.databases
where compatibility_level <> 150
order by state desc, database_id 


--alter database teste set OFFLINE