
--Instancia original
use master
go
BACKUP CERTIFICATE cert_backup_colossus_2014
TO FILE = '\\venom\BACKUP_SQL\certificados\cert_backup_colossus_2014.cer'
WITH PRIVATE KEY (
FILE = '\\venom\BACKUP_SQL\certificados\cert_backup_colossus_2014.key',
ENCRYPTION BY PASSWORD = '@I4proSqlColossus2014')

-- instancia que vai receber o restore
use master
go
CREATE CERTIFICATE cert_backup_sro
FROM FILE = N'\\batman\departamentos$\TI\BD\Restrito\Certificados_Backups\certificados\cert_backup_sro.cer'
WITH PRIVATE KEY ( 
FILE = N'\\batman\departamentos$\TI\BD\Restrito\Certificados_Backups\certificados\cert_backup_sro.key',
DECRYPTION BY PASSWORD = '@I4proSqlSroLegiao') 

-- depois é só seguir com o restore normalmente