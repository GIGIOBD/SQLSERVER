SELECT 
	convert(VARCHAR(10), backup_start_date, 111) AS BackupDate,
	convert(numeric(19,2),(backup_size / 1024000000)) AS Size
FROM msdb..backupset
WHERE database_name = 'apvstruck_erp_pro'
       AND type = 'd'
ORDER BY backup_start_date DESC