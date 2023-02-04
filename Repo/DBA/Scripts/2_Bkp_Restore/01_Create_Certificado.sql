/*
 Este procedimento deve ser realizado para restaurar bases em novos servidores que não possue o certificado. 
*/

/* Para servidores novos, deve-se primeiro criar a MasterKey */
use master
	create MASTER KEY ENCRYPTION BY PASSWORD = '@I4proSqlWolverine';

	
/* Em seguida deve-se copiar para o servidor em questão, os arquivos dos certificados, no casos dos servers de origem da base */
--copy Z:\TI\BD\Restrito\certificados
--paste C:\temp\cert\


/* Criar os certificados */
CREATE CERTIFICATE cert_backup_cyborg
FROM FILE = '\\venom\BACKUP_SQL\certificados\cert_backup_cyborg.cer'   
WITH PRIVATE KEY (
    FILE = N'\\venom\BACKUP_SQL\certificados\cert_backup_cyborg.key',   
    DECRYPTION BY PASSWORD = '@I4proSqlCyborg'
	)

/* Senhas e certificados */
-- Z:\TI\BD\Restrito\certificados



select tamanho_senha = len(nm_senha), * from eng.t_usuario 
/* Criar certificado na base */ 
/***************** 01 - Criar e excluir certificado. ************************************/



USE i4pro_apoio2_hom
GO
CREATE DATABASE ENCRYPTION KEY
WITH ALGORITHM = AES_256
ENCRYPTION BY SERVER CERTIFICATE cert_bkp_wolv_22;
GO

	drop DATABASE ENCRYPTION KEY
	GO
	
	
	use i4pro_next_pro
/***************** 02 - Alterar status da criptografia. ************************************/
	
	alter database i4pro_apoio2_hom set encryption on

/***************** 03 - Verifica o status da criptografia **********************************/
/*		Verificar o status da encrypted  
	1 = sem crypto  
	2 = mudando de status 1/3 
	3 = crypto  
	5 = mudando de status 3/1 */
    
	SELECT
		@@SERVERNAME,
		A.[name],
		A.is_master_key_encrypted_by_server,
		A.is_encrypted,
		B.percent_complete,
		B.*
	FROM
		sys.databases A
		JOIN sys.dm_database_encryption_keys B ON B.database_id = A.database_id
	where a.name in('i4pro_apoio2_hom')
	


	select * from sys.dm_database_encryption_keys
	select * from sys.databases

/***************** Importar certificados **********************************/
/* Consultar senhas na planilha eu nao sei a senha */

	CREATE CERTIFICATE cert_bkp_wolv_22
	FROM FILE = 'C:\temp\cert_backup_wolverine.cer'   
	WITH PRIVATE KEY (
	    FILE = N'C:\temp\cert_backup_wolverine.key',   
	    DECRYPTION BY PASSWORD = '@I4proSqlWolverine'
		)


/* Alterar senha de certificado. */

ALTER CERTIFICATE cert_criptografia   
    WITH PRIVATE KEY (DECRYPTION BY PASSWORD = '@I4procert',  
    ENCRYPTION BY PASSWORD = 'I4procert@9m91H9tuaTwOFsPY');  
GO  


--==========================================================================================
/* PASSO A PASSO */
RESTORE filelistonly from
disk='E:\Microsoft\SQL\BACKUP\i4pro_inshare_pro.bak'

--==========================================================================================
/* Criar chave mestra - Servidor */
create MASTER KEY ENCRYPTION BY PASSWORD = '@I4proSqlWolverine';

--==========================================================================================
/* Criar certificado com e sem data de experição */
CREATE CERTIFICATE cert_bkp_wolv_22 WITH SUBJECT = 'Cert Wolverine SQL02';
GO

CREATE CERTIFICATE cert_bkp_wolv_22
WITH SUBJECT = 'Certificado de backup Wolverine 2022',
EXPIRY_DATE = '20221231';
GO 

--==========================================================================================
/* Verifica certificados criados */
select * from sys.certificates

--==========================================================================================
/* Backup dos certificados */
BACKUP CERTIFICATE cert_backup_wolverine_22 
TO FILE = '\\venom\BACKUP_SQL\certificados\cert_backup_wolverine_22.cer'   
	WITH PRIVATE KEY (
	    FILE = N'\\venom\BACKUP_SQL\certificados\cert_backup_wolverine_22.key',   
	    ENCRYPTION BY PASSWORD = '@I4proSqlWolverine'
		);

--==========================================================================================
/* Importar certificados */
CREATE CERTIFICATE cert_bkp_wolv_22
FROM FILE = '\\venom\BACKUP_SQL\certificados\cert_backup_wolverine_22.cer'   
	WITH PRIVATE KEY (
	    FILE = N'\\venom\BACKUP_SQL\certificados\cert_backup_wolverine_22.key',   
	    DECRYPTION BY PASSWORD = '@I4proSqlWolverine'
		);
--==========================================================================================

--==========================================================================================
/* Dropar certificados */
	DROP CERTIFICATE cert_backup_wolverine_22 
--==========================================================================================
		