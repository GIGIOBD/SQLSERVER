select
	(max_workers_count * 0.5) as X86, --500k
	(max_workers_count * 2) as X64, --2mb
	max_workers_count
from sys.dm_os_sys_info