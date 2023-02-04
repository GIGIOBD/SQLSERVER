SELECT 
	--dbid,
    db_name(sf.dbid) as [Database_Name],
    sf.name as [File_Name],
    (sf.size/128.0 - CAST(FILEPROPERTY(file_name(fileid), 'SpaceUsed') AS int)/128.0) AS 'Available_Space_MB'

FROM    master..sysaltfiles sf
WHERE   groupid = 0
and db_name(sf.dbid) not in('model')
--and dbid = 168
ORDER BY    Available_Space_MB  DESC