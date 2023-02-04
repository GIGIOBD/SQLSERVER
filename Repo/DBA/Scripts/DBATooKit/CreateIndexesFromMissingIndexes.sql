SELECT 
		DB_NAME(dm_mid.database_id) AS DatabaseName, 
		[Total Cost]  = ROUND(avg_total_user_cost * avg_user_impact * (user_seeks + user_scans),0) ,
       dm_migs.avg_user_impact * (dm_migs.user_seeks + dm_migs.user_scans) Avg_Estimated_Impact, 
       dm_migs.last_user_seek AS Last_User_Seek, 
       OBJECT_NAME(dm_mid.OBJECT_ID, dm_mid.database_id) AS [TableName], 
	   s.name,
       'CREATE INDEX [ix_' + OBJECT_NAME(dm_mid.OBJECT_ID, dm_mid.database_id) + '_X_' + REPLACE(REPLACE(REPLACE(ISNULL(dm_mid.equality_columns, ''), ', ', '$'), '[', ''), ']', '') 
	   + CASE
             WHEN dm_mid.equality_columns IS NOT NULL
                  AND dm_mid.inequality_columns IS NOT NULL
             THEN '$'
             ELSE ''
         END + REPLACE(REPLACE(REPLACE(ISNULL(dm_mid.inequality_columns, ''), ', ', '$'), '[', ''), ']', '') + ']' 
		 + ' ON ' + dm_mid.statement + ' (' + ISNULL(dm_mid.equality_columns, '') 
		 + CASE
		     WHEN dm_mid.equality_columns IS NOT NULL
		          AND dm_mid.inequality_columns IS NOT NULL
		     THEN ','
		     ELSE ''
		 END + ISNULL(dm_mid.inequality_columns, '') + ')' + ISNULL(' INCLUDE (' + dm_mid.included_columns + ')', '') AS Create_Statement		 
FROM sys.dm_db_missing_index_groups dm_mig
     INNER JOIN sys.dm_db_missing_index_group_stats dm_migs ON dm_migs.group_handle = dm_mig.index_group_handle
     INNER JOIN sys.dm_db_missing_index_details dm_mid ON dm_mig.index_handle = dm_mid.index_handle
	 INNER JOIN sys.all_objects so on so.name = OBJECT_NAME(dm_mid.OBJECT_ID, dm_mid.database_id) 
	 INNER JOIN sys.schemas s on s.schema_id = so.schema_id
	WHERE dm_mid.database_ID = DB_ID()	
	and dm_migs.avg_user_impact > 85.00
ORDER BY [Total Cost] DESC;
GO
