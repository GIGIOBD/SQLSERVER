/* Criar certificado na base */ 

/***************** 01 - Criar e excluir certificado. ************************************/

	create DATABASE ENCRYPTION KEY  
		WITH ALGORITHM = AES_256  
		ENCRYPTION BY SERVER CERTIFICATE cert_backup_ciclope;  
	GO

	drop DATABASE ENCRYPTION KEY
	GO

/***************** 02 - Alterar status da criptografia. ************************************/
	
	alter database i4pro_next_dev set encryption on

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
	where a.name in('i4pro_next_dev')
	
/***************** Importar certificados **********************************/
/* Consultar senhas na planilha eu nao sei a senha */

	CREATE CERTIFICATE cert_backup_sro
	FROM FILE = 'C:\temp\certificado\cert_backup_sro.cer'   
	WITH PRIVATE KEY (
	    FILE = N'C:\temp\certificado\cert_backup_sro.key',   
	    DECRYPTION BY PASSWORD = '@I4ProSqlLegiao'
		)

use master 
CREATE CERTIFICATE cert_backup_ciclope
FROM FILE = '\\venom\BACKUP_SQL\certificados\cert_backup_ciclope.cer'   
WITH PRIVATE KEY (
    FILE = N'\\venom\BACKUP_SQL\certificados\cert_backup_ciclope.key',   
    DECRYPTION BY PASSWORD = '@I4proSqlCiclope'
	)