/*Migrar banco de dados
Tirar criptografia
	alter database itau_poc_head set encryption off

dentro da base que vc quer tirar o certificado atrelado execute esse comando

Verificar o status da encrypted  1 = sem crypto  3 = crypto  5 = mudando de status

SELECT
	@@SERVERNAME,
    A.[name],
    A.is_master_key_encrypted_by_server,
    A.is_encrypted,
    b.percent_complete,
	B.*
FROM
    sys.databases A
    JOIN sys.dm_database_encryption_keys B ON B.database_id = A.database_id
where a.name in('itau_poc_head ')

--rodar dentro do banco selecionado.
drop DATABASE ENCRYPTION KEY

cria cryptografia
use itau_poc_head 

create DATABASE ENCRYPTION KEY  
WITH ALGORITHM = AES_256  
ENCRYPTION BY SERVER CERTIFICATE cert_backup_flash;  
GO

alter database db_i4pro_interface set encryption on

Gerar script create database - origem;
Escolher a pasta unida para os arquivos fisicos (escolher o disco com menos espaço);

Atualizar dispositivo de backup:
*/
BACKUP DATABASE itau_poc_head to itau_poc_head with format
GO

select @@SERVERNAME

BACKUP DATABASE alba_erp_head_rest to disk = '\\venom\BACKUP_SQL\CICLOPE\SQL2019\i4pro_apoio2_hom.bak'
GO


RESTORE filelistonly from
disk='\\venom\BACKUP_SQL\CICLOPE\SQL2019\i4pro_apoio2_hom.bak'

/*
Pode dar erro de certificado;
Importar certificado;
*/
--CRIAR DATABASE

-- Criar chave mestra
/*
use master
	create MASTER KEY ENCRYPTION BY PASSWORD = '@I4proSqlPocHead';
*/

CREATE CERTIFICATE cert_backup_ciclope
FROM FILE = 'C:\temp\cert\cert_backup_ciclope.cer'   
WITH PRIVATE KEY (
    FILE = N'C:\temp\cert\cert_backup_ciclope.key',   
    DECRYPTION BY PASSWORD = '@I4proSqlCiclope'
	)


	
sp_helpdb i4pro_apoio2_hom
go
--Script restore

/* Restore database */

use master
RESTORE DATABASE i4pro_apoio2_hom
from disk='\\venom\BACKUP_SQL\CICLOPE\SQL2019\i4pro_apoio2_hom.bak'     
with file=1,recovery,replace, 
move	'apoio_erp_hom'		to  'C:\Microsoft\SQL\DATA\i4pro_apoio2_hom.mdf',
move	'apoio_erp_hom_log'	to  'C:\Microsoft\SQL\LOG\i4pro_apoio2_hom.ldf',
move	'i4pro_engine_ecm'	to  'C:\Microsoft\SQL\DATA\i4pro_apoio2_hom_ecm.ndf',
move	'i4pro_engine_eng'	to  'C:\Microsoft\SQL\DATA\i4pro_apoio2_hom_eng.ndf',
move	'i4pro_engine_ims'	to  'C:\Microsoft\SQL\DATA\i4pro_apoio2_hom_ims.ndf',
move	'i4pro_engine_prt'	to  'C:\Microsoft\SQL\DATA\i4pro_apoio2_hom_prt.ndf',
move	'i4pro_engine_sec'	to  'C:\Microsoft\SQL\DATA\i4pro_apoio2_hom_sec.ndf',
move	'i4pro_engine_wex'	to  'C:\Microsoft\SQL\DATA\i4pro_apoio2_hom_wex.ndf'



/* Criar use do site */
--ambientes head = homhead, ambientes cyborg = demo


use i4pro_apoio2_hom
create user [homhead] -- cria o usuario
exec sp_addrolemember db_owner,[homhead]  -- inclui o usuario na role de db_owner


DROP USER INFORMATION_SCHEMA;  
GO  
