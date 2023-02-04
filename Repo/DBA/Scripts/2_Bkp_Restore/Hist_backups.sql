-- Look at recent Full backups for the current database (Query 86) (Recent Full Backups)
SELECT  top (100)
	bs.backup_finish_date AS [Backup Finish Date], 
	bmf.physical_device_name AS [Backup Location], 
	bs.database_name AS [Database Name], 
	bmf.physical_block_size,	
	bs.machine_name, 
	bs.server_name, 
	bs.recovery_model,
	CONVERT (BIGINT, bs.backup_size / 1048576 ) AS [Uncompressed Backup Size (MB)],
	CONVERT (BIGINT, bs.compressed_backup_size / 1048576 ) AS [Compressed Backup Size (MB)],
	CONVERT (NUMERIC (20,2), (CONVERT (FLOAT, bs.backup_size) /	CONVERT (FLOAT, bs.compressed_backup_size))) AS [Compression Ratio], 
	bs.has_backup_checksums, 
	bs.is_copy_only, 
	bs.encryptor_type,
	DATEDIFF (SECOND, bs.backup_start_date, bs.backup_finish_date) AS [Backup Elapsed Time (sec)]
FROM msdb.dbo.backupset AS bs WITH (NOLOCK)
INNER JOIN msdb.dbo.backupmediafamily AS bmf WITH (NOLOCK)
ON bs.media_set_id = bmf.media_set_id  
WHERE 1=1 --bs.database_name = DB_NAME(DB_ID())
AND bs.[type] = 'D' -- Change to L if you want Log backups
ORDER BY bs.backup_finish_date DESC OPTION (RECOMPILE);

/*
select COUNT(1) from sys.databases
where database_id > 4

select name, compatibility_level from sys.databases
where database_id > 4


*/

