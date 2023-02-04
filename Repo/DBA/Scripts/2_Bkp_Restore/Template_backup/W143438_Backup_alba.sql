/* Executar este primeiro comando, que irá criar um Backup Device, para visualizar vá no 
Object Explorer / Server Objects / Backup Devices
*/

/* INFORME O NOME DO BANCO */
declare 
	@nome_banco varchar(30) = 'backup_alba',
	@caminho_backup varchar(5000) = '\\PASTADAREDE\BACKUP_SQL\'
	
,@comand varchar(5000)

set @comand = '
USE [master]

/****** Object:  BackupDevice [XXXX]    Script Date: 06/01/2022 15:25:45 ******/
EXEC master.dbo.sp_addumpdevice  
	@devtype = N''disk'', 
	@logicalname = N'''+@nome_banco+''',  --alterar o nome do banco
	@physicalname = N'''+@caminho_backup+@nome_banco+'.bak'' --caminho do backup

'

exec (@comand)


USE [msdb]


set @comand = N'
declare c_lista insensitive cursor for   
	select 
		a.name 
	from msdb.sys.backup_devices a join sys.databases b   
	on a.name = b.name  
	where a.name like ''%'+@nome_banco+'%'' 
	and state_desc =''online''
declare @db sysname  
open c_lista  
fetch c_lista into @db  
declare @sql varchar(2550)  
while (@@fetch_status=0)  
begin  
  set @sql = ''BACKUP DATABASE [''+@db+''] TO [''+@db+''] WITH FORMAT, compression,  NAME = N''''''+@db+'' - Full Database Backup'''' ''  
  
 exec(@sql)  
 fetch c_lista into @db  
end  
deallocate c_lista'

/****** Object:  Job [Backup Diario Alba]    Script Date: 06/01/2022 15:35:12 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 06/01/2022 15:35:12 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16), @schedule_uid BINARY(100)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Backup Diario Alba - template', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Backup Diario]    Script Date: 06/01/2022 15:35:13 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Backup Diario', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=@comand, 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Backup Diario', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20201003, 
		@active_end_date=99991231, 
		@active_start_time=220000, 
		@active_end_time=235959, 
		@schedule_uid= @schedule_uid output
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO
