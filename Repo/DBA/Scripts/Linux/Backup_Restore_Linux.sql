/* Copiar arquivo de bkp para */
RESTORE filelistonly from
disk='/var/opt/mssql/backdup'

/* Fazer restore */
use master
RESTORE DATABASE habitacional_erp_demo
from disk='var/opt/mssql/data/habitacional_erp_demo.bak'
with file=1,recovery,replace, 
move 'i4proerp_data' to '/var/opt/mssql/data/habitacional_erp_poc.mdf',
move 'i4pro_engine_ecm' to '/var/opt/mssql/data/habitacional_erp_poc_ecm.ndf',
move 'i4pro_engine_eng' to '/var/opt/mssql/data/habitacional_erp_poc_eng.ndf',
move 'i4proerp_ind' to '/var/opt/mssql/data/habitacional_erp_poc_ind.ndf',
move 'i4pro_engine_wex' to '/var/opt/mssql/data/habitacional_erp_poc_wex.ndf',
move 'i4pro_ptl' to '/var/opt/mssql/data/habitacional_erp_poc_PTL.ndf',
move 'i4pro_engine_prt' to '/var/opt/mssql/data/habitacional_erp_poc_prt.ndf',
move 'i4pro_engine_sec' to '/var/opt/mssql/data/habitacional_erp_poc_sec.ndf',
move 'i4pro_cad' to '/var/opt/mssql/data/habitacional_erp_poc_cad.ndf',
move 'i4pro_acc' to '/var/opt/mssql/data/habitacional_erp_poc_acc.ndf',
move 'i4pro_EIS' to '/var/opt/mssql/data/habitacional_erp_poc_EIS.ndf',
move 'i4pro_auth' to '/var/opt/mssql/data/habitacional_erp_poc_AUTH.ndf',
move 'i4proerp_log' to '/var/opt/mssql/data/habitacional_erp_poc.ldf'

/* Adicionar BkpDevice */
USE [master]
GO
EXEC master.dbo.sp_addumpdevice  
@devtype = N'disk', 
@logicalname = N'habitacional_erp_demo', 
@physicalname = N'var/opt/mssql/backup/habitacional_erp_demo.bak'
GO

/* Fazer Backpup */
backup database habitacional_erp_demo   
--to disk='var/opt/mssql/data/habitacional_erp_demo.bak'
to habitacional_erp_demo  
with format, 
compression, 
stats = 20;

/* Conferir o bkp */
RESTORE filelistonly from
disk='var/opt/mssql/backup/habitacional_erp_demo.bak'


/* Single user */
USE master;
GO
ALTER DATABASE habitacional_erp_demo
SET SINGLE_USER
WITH ROLLBACK IMMEDIATE;
GO

/* Multi user */
USE master;
GO
ALTER DATABASE habitacional_erp_demo
SET MULTI_USER;
GO

/* Create user */
use habitacional_erp_demo

--ambientes head = homhead
--ambientes demo = demo
create user [suhai] 					-- cria o usuario
exec sp_addrolemember db_owner,[suhai]  