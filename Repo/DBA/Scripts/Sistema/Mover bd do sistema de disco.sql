/* Mover bancos de dados do sistema 
Verificar path atual do arquivos
*/
select name, physical_name from sys.master_files where database_id = db_id('model')
GO
 
select name, physical_name from sys.master_files where database_id = db_id('msdb')
GO

/* Comando de alter referenciando os novos paths */
--------------MODEL-----------------------------
alter database model modify file 
    (name = modeldev, filename = 'C:\Microsoft\SQLServer\Data\model.mdf')
go
 
alter database model modify file 
    (name = modellog, filename = 'C:\Microsoft\SQLServer\Data\modellog.ldf')
go
 
-------------MSDB--------------------------------
alter database msdb modify file 
    (name = MSDBData, filename = 'C:\Microsoft\SQLServer\Data\MSDBData.mdf')
go
 
alter database msdb modify file 
    (name = MSDBLog, filename = 'C:\Microsoft\SQLServer\Data\MSDBLog.ldf')
go

/* Parar a instancia e mover manualmente os arquivos e iniciar a instancia novamente */ 
/* Rodar a query novamente para conferir os paths atuais */
select name, physical_name from sys.master_files where database_id = db_id('model')
GO
 
select name, physical_name from sys.master_files where database_id = db_id('msdb')
GO

/* Verificar o path atual do banco de dados Master */
select name, physical_name from sys.master_files where database_id = db_id('master')
GO

/* 
Para o banco de dados master, o procedimento é o mesmo, porém um jeito mais facil :

Para a isntancia
Abrir o Configuration Managar
Startup Parameters
Atualizar os path do master, e não retirar os prefixo -d e -l
Mover os arquivos
Iniciar a instancia
*/

/* Mover o Tempdb */
/* Consulta paths atuais */
select name, physical_name from sys.master_files where database_id = db_id('tempdb')
GO

alter database tempdb modify file 
    (name = tempdev, filename = 'C:\Microsoft\SQLServer\tempdb\tempdb.mdf')
go
 
alter database tempdb modify file 
    (name = templog, filename = 'C:\Microsoft\SQLServer\tempdb\templog.ldf')
go

alter database tempdb modify file 
    (name = temp2, filename = 'C:\Microsoft\SQLServer\tempdb\temp2.ldf')
go