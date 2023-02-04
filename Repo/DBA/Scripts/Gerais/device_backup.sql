
select 
	bk.name,
	db.name,
	bk.*
	,'EXEC sp_dropdevice '''+bk.name+''' , ''delfile'';'
from msdb.sys.backup_devices bk
left join master.sys.databases db
on db.name = bk.name
where db.name is null
order by db.name 





select 
	bk.name,
	db.name
	--bk.*
from master.sys.databases db
left join msdb.sys.backup_devices bk
on bk.name = db.name 
where bk.name is null
order by db.database_id 
return

--EXEC sp_dropdevice 'alfa_erp_head'		, '\\venom\BACKUP_SQL\fenix\SQL2019\alfa_erp_head.bak';
--EXEC sp_dropdevice 'austral_erp_head'		, '\\venom\BACKUP_SQL\fenix\SQL2019\austral_erp_head.bak';
--EXEC sp_dropdevice 'berkley_erp_head'		, '\\venom\BACKUP_SQL\fenix\SQL2019\berkley_erp_head.bak';
--EXEC sp_dropdevice 'cesce_erp_head'		, '\\venom\BACKUP_SQL\fenix\SQL2019\cesce_erp_head.bak';
--EXEC sp_dropdevice 'ezze_erp_head'		, '\\venom\BACKUP_SQL\fenix\SQL2019\ezze_erp_head.bak';
--EXEC sp_dropdevice 'fator_erp_head'		, '\\venom\BACKUP_SQL\fenix\SQL2019\fator_erp_head.bak';
--EXEC sp_dropdevice 'hdi_erp_head'			, '\\venom\BACKUP_SQL\fenix\SQL2019\hdi_erp_head.bak';
--EXEC sp_dropdevice 'i4pro_b4_head'		, '\\venom\BACKUP_SQL\fenix\SQL2019\i4pro_b4_head.bak';
--EXEC sp_dropdevice 'i4pro_clp_head'		, '\\venom\BACKUP_SQL\fenix\SQL2019\i4pro_clp_head.bak';
--EXEC sp_dropdevice 'liberty_erp_head'		, '\\venom\BACKUP_SQL\fenix\SQL2019\liberty_erp_head.bak';
--EXEC sp_dropdevice 'markel_erp_head'		, '\\venom\BACKUP_SQL\fenix\SQL2019\markel_erp_head.bak';
--EXEC sp_dropdevice 'onme_erp_head'		, '\\venom\BACKUP_SQL\fenix\SQL2019\onme_erp_head.bak';
--EXEC sp_dropdevice 'previsul_erp_head'	, '\\venom\BACKUP_SQL\fenix\SQL2019\previsul_erp_head.bak';
--EXEC sp_dropdevice 'prudential_erp_head'	, '\\venom\BACKUP_SQL\fenix\SQL2019\prudential_erp_head.bak';
--EXEC sp_dropdevice 'sabemi_erp_head'		, '\\venom\BACKUP_SQL\fenix\SQL2019\sabemi_erp_head.bak';
--EXEC sp_dropdevice 'sancorre_erp_head'	, '\\venom\BACKUP_SQL\fenix\SQL2019\sancorre_erp_head.bak';
--EXEC sp_dropdevice 'santander_cloud_head' , '\\venom\BACKUP_SQL\fenix\SQL2019\santander_cloud_head.bak';
--EXEC sp_dropdevice 'santander_erp_head'	, '\\venom\BACKUP_SQL\fenix\SQL2019\santander_erp_head.bak';
--EXEC sp_dropdevice 'usebens_erp_head'		, '\\venom\BACKUP_SQL\fenix\SQL2019\usebens_erp_head.bak';
--EXEC sp_dropdevice 'sura_erp_head'		, '\\venom\BACKUP_SQL\FENIX\SQL2019\sura_erp_head.bak';
--EXEC sp_dropdevice 'brasilprev_erp_head'	, '\\venom\BACKUP_SQL\FENIX\SQL2019\brasilprev_erp_head.bak';
--EXEC sp_dropdevice 'alba_erp_head'		, '\\venom\BACKUP_SQL\FENIX\SQL2019\alba_erp_head.bak';
--EXEC sp_dropdevice 'enova_erp_head'		, '\\venom\BACKUP_SQL\FENIX\SQL2019\enova_erp_head.bak';

----Delete the backup device and the physical name.  
--USE AdventureWorks2012 ;  
--GO  
--EXEC sp_dropdevice ' mybackupdisk ', 'delfile' ;  
--GO  


select 
	bk.name,
	db.name
	--bk.*
from master.sys.databases db
left join msdb.sys.backup_devices bk
on bk.name = db.name 
where bk.name is null
order by db.database_id 

--select count(database_id) from sys.databases 
--where database_id > 0