DBCC FREEPROCCACHE
GO
DBCC DROPCLEANBUFFERS
go
DBCC FREESYSTEMCACHE ('ALL')
GO
DBCC FREESESSIONCACHE
GO
use tempdb
go
DBCC SHRINKFILE (TEMPDEV,1024)
GO
DBCC SHRINKFILE (TEMPLOG,1024)
GO
DBCC SHRINKFILE (TEMP2,1024)
GO
DBCC SHRINKFILE (TEMP3,1024)
GO
DBCC SHRINKFILE (TEMP4,1024)
GO
DBCC SHRINKFILE (TEMP5,1024)
GO
DBCC SHRINKFILE (TEMP6,1024)
GO
DBCC SHRINKFILE (TEMP7,1024)
GO
DBCC SHRINKFILE (TEMP8,1024)
GO