select 
	at.transaction_id,
	s.*
from sys.sysprocesses s
LEFT OUTER JOIN sys.dm_tran_session_transactions st on s.spid = st.session_id
LEFT OUTER JOIN sys.dm_tran_active_transactions at on st.transaction_id = at.transaction_id
order by at.transaction_id desc

