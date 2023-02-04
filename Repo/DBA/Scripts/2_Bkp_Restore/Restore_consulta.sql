SELECT destination_database_name
	,bmf.physical_device_name
	,restore_date
FROM msdb.dbo.restorehistory
INNER JOIN msdb.dbo.backupset AS bs ON bs.backup_set_id = msdb.dbo.restorehistory.backup_set_id
INNER JOIN msdb.dbo.backupmediafamily AS bmf ON bs.media_set_id = bmf.media_set_id
WHERE restore_history_id IN (
		SELECT MAX(restore_history_id)
		FROM msdb.dbo.restorehistory
		WHERE restore_type = 'D'
			AND destination_database_name IN (
				SELECT DISTINCT destination_database_name
				FROM msdb.dbo.restorehistory
				)
		GROUP BY destination_database_name
		)
ORDER BY restore_date DESC