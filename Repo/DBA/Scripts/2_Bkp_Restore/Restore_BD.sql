backup database suhai_erp_dev   to suhai_erp_dev  with format


RESTORE filelistonly from
disk='\\venom\BACKUP_SQL\CYBORG\SQL2019\NaoExcluir\habitacional_erp_demo.bak'

select @@SERVERNAME;
go

/* caminhos do arquivo do banco a ser restaurado */
sp_helpdb habitacional_erp_demo;
go

select * from sys.sysaltfiles
where dbid = 12

select * from sys.databases 



/*to  informar o caminho do banco a ser restaurado. */
use master
RESTORE DATABASE habitacional_erp_demo
from disk='\\venom\BACKUP_SQL\CYBORG\SQL2019\habitacional_erp_demo.bak'
with file=1,recovery,replace, 
move 'i4proerp_data' to 'D:\SQL2019\habitacional\habitacional_erp_demo.mdf',
move 'i4proerp_log' to 'E:\SQL2019\habitacional\habitacional_erp_demo.ldf',
move 'i4pro_engine_ecm' to 'D:\SQL2019\habitacional\habitacional_erp_demo_ecm.ndf',
move 'i4pro_engine_eng' to 'D:\SQL2019\habitacional\habitacional_erp_demo_eng.ndf',
move 'i4proerp_ind' to 'D:\SQL2019\habitacional\habitacional_erp_demo_ind.ndf',
move 'i4pro_engine_wex' to 'D:\SQL2019\habitacional\habitacional_erp_demo_wex.ndf',
move 'i4pro_ptl' to 'D:\SQL2019\habitacional\habitacional_erp_demo_PTL.ndf',
move 'i4pro_engine_prt' to 'D:\SQL2019\habitacional\habitacional_erp_demo_prt.ndf',
move 'i4pro_engine_sec' to 'D:\SQL2019\habitacional\habitacional_erp_demo_sec.ndf',
move 'i4pro_cad' to 'D:\SQL2019\habitacional\habitacional_erp_demo_cad.ndf',
move 'i4pro_acc' to 'D:\SQL2019\habitacional\habitacional_erp_demo_acc.ndf',
move 'i4pro_EIS' to 'D:\SQL2019\habitacional\habitacional_erp_demo_EIS.ndf',
move 'i4pro_auth' to 'D:\SQL2019\habitacional\habitacional_erp_demo_AUTH.ndf'


ALTER USER [homhead] WITH LOGIN = [homhead]

use suhai_erp_dev


--C:\Microsoft\SQL\DATA\bd_i4pro_interface.mdf
--C:\Microsoft\SQL\LOG\bd_i4pro_interface_log.ldf



restore database suhai_erp_dev with recovery

USE master;
GO
ALTER DATABASE habitacional_erp_demo
SET SINGLE_USER
WITH ROLLBACK IMMEDIATE;
GO

USE master;
GO
ALTER DATABASE habitacional_erp_demo
SET MULTI_USER;
GO


use suhai_erp_dev

--ambientes head = homhead
--ambientes demo = demo
create user [suhai] 					-- cria o usuario
exec sp_addrolemember db_owner,[suhai]  -- inclui o usuario na role de db_owner

create user [I4PROINFO\azago]						-- cria o usuario
exec sp_addrolemember db_owner,[I4PROINFO\azago]

create user [I4PROINFO\g-sql-prev]						-- cria o usuario
exec sp_addrolemember db_owner,[I4PROINFO\g-sql-prev]



