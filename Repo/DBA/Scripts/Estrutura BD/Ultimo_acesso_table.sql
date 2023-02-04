	use apvs_erp_dev;
	
	
	SELECT
		A.name AS [object_name],
		A.type_desc,
		B.database_id,
		C.name AS index_name,
		(
		SELECT MAX(Ultimo_Acesso)
		FROM (VALUES (B.last_user_seek),(B.last_user_scan),(B.last_user_lookup),(B.last_user_update)) AS DataAcesso(Ultimo_Acesso)
		) AS last_access,
		B.last_user_seek,
		B.last_user_scan,
		B.last_user_lookup,
		B.last_user_update,
		NULLIF(
		(CASE WHEN B.last_user_seek IS NOT NULL THEN 'Seek, ' ELSE '' END) +
		(CASE WHEN B.last_user_scan IS NOT NULL THEN 'Scan, ' ELSE '' END) +
		(CASE WHEN B.last_user_lookup IS NOT NULL THEN 'Lookup, ' ELSE '' END) +
		(CASE WHEN B.last_user_update IS NOT NULL THEN 'Update, ' ELSE '' END)
		, '') AS operations
	FROM
	sys.objects                                 A
	LEFT JOIN sys.dm_db_index_usage_stats       B	ON	B.[object_id] = A.[object_id] AND B.[database_id] = DB_ID()
	LEFT JOIN sys.indexes                       C	ON	C.index_id = B.index_id AND C.[object_id] = B.[object_id]
	WHERE
	A.[type_desc] IN ('VIEW', 'USER_TABLE')

	ORDER BY
	A.name,
	B.index_id




--use master;
--sp_helpdb core2_erp_dev_rest
--drop database core2_erp_dev_rest;