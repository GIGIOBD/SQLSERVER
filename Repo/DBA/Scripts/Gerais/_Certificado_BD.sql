use master

/* Verifica bancos com certificado */
select 
	database_name = db.name,
	dek.encryptor_type, 
	cert_name = mycert.name
from sys.dm_database_encryption_keys dek
left join sys.certificates mycert on dek.encryptor_thumbprint = mycert.thumbprint
inner join sys.databases db on dek.database_id = db.database_id
where mycert.name is not null

/* Retirar criptografia do banco */    
alter database i4pro_erp_dev set encryption off

/* Dropar certificado do banco: dentro da base que vc quer tirar o certificado atrelado
    execute esse comando */

drop DATABASE ENCRYPTION KEY


