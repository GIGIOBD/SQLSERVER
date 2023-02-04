select sa.* 
,
'ALTER DATABASE  '+ DB_NAME(sa.dbid) +' MODIFY FILE ( NAME = N'''+name+''',FILEGROWTH = 102400KB )'
from sys.sysaltfiles sa
where sa.dbid > 4 
and sa.filename like '%.ldf'

