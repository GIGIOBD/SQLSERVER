--==========================================================================================
/* Criar chave mestra - Servidor */
create MASTER KEY ENCRYPTION BY PASSWORD = '@GigioTDECertificateMedium';
GO

--==========================================================================================
/* Criar certificado com e sem data de experição */
CREATE CERTIFICATE cert_bkp_tde_medium WITH SUBJECT = 'Cert TDE Medium Linux';
GO

CREATE CERTIFICATE cert_bkp_tde_medium
WITH SUBJECT = 'Cert TDE Medium Linux',
EXPIRY_DATE = '20231231';
GO 

--==========================================================================================
/* Verifica certificados criados */
select * from sys.certificates
GO

--==========================================================================================
/* Backup da MasterKey */
BACKUP MASTER KEY TO FILE = '/var/opt/mssql/backup/masterkey_Medium'
ENCRYPTION BY PASSWORD = '@GigioTDECertificateMedium'
GO

--==========================================================================================
/* Backup dos certificados */
BACKUP CERTIFICATE cert_bkp_tde_medium 
TO FILE = '/var/opt/mssql/backup/cert_bkp_tde_medium.cer'   
	WITH PRIVATE KEY (
	    FILE = N'/var/opt/mssql/backup/cert_bkp_tde_medium.key',   
	    ENCRYPTION BY PASSWORD = '@GigioTDECertificateMedium'
		);

/* Criar database para teste */
create database tde_on_linux
GO

/* Criar data encryption */
use tde_on_linux
GO

CREATE DATABASE ENCRYPTION KEY
WITH ALGORITHM = AES_256
ENCRYPTION BY SERVER CERTIFICATE cert_bkp_tde_medium;
GO

/***************** 02 - Alterar status da criptografia. ************************************/
	
alter database tde_on_linux set encryption on

/***************** 03 - Verifica o status da criptografia **********************************/
/*		Verificar o status da encrypted  
	1 = sem crypto  
	2 = mudando de status 1/3 
	3 = crypto  
	5 = mudando de status 3/1 
*/
    
	SELECT
		@@VERSION,
		A.[name],
		A.is_master_key_encrypted_by_server,
		A.is_encrypted,
		B.percent_complete,
		B.*
	FROM
		sys.databases A
		JOIN sys.dm_database_encryption_keys B ON B.database_id = A.database_id
	where a.name in('tde_on_linux')



/*
--==========================================================================================
/* Importar certificados */
CREATE CERTIFICATE cert_bkp_tde_medium
FROM FILE = '/var/opt/mssql/backup/cert_bkp_tde_medium.cer'   
	WITH PRIVATE KEY (
	    FILE = N'/var/opt/mssql/backup/cert_bkp_tde_medium.key',   
	    DECRYPTION BY PASSWORD = '@GigioTDECertificateMedium'
		);

--==========================================================================================
/* Dropar certificados */
	DROP CERTIFICATE cert_bkp_tde_medium 
--==========================================================================================
/* Drop encryption key */
DROP DATABASE ENCRYPTION KEY
GO

--==========================================================================================
/* Validar thumbprint no arquivo de bkp */
RESTORE filelistonly from
disk='/var/opt/mssql/backdup'
*/

