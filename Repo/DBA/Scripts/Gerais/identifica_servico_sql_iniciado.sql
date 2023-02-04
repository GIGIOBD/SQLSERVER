/*
Identifica quando o servi�o do SQL Server foi iniciado
Utilizando a DMV sys.dm_os_sys_info conseguimos identificar a data em que o servi�o do SQL Server foi iniciado. 
*/
SELECT sqlserver_start_time FROM sys.dm_os_sys_info