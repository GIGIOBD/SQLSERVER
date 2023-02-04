if object_id('tempdb..##tmp_usuarios','u') is not null
begin
	drop table ##tmp_usuarios 
end

create table ##tmp_usuarios
(
	nm_server		varchar(50)	,
	nm_database		varchar(50)	,
	nm_user			varchar(100),
	sid				varbinary(1000),
	command			varchar(1000)
)

declare 
	@database	varchar(200),
	@sql		varchar(2000)

declare cur_db cursor for 
	select
		a.name
	from sys.databases a
	--where a.name = 'i4pro_sancor_dev'

open cur_db

fetch cur_db into @database 

while @@FETCH_STATUS = 0
begin

	set @sql = 'use ' + @database + '
	insert into ##tmp_usuarios (nm_server, nm_database, nm_user, sid, command)
	SELECT	
		@@servername,
		s.name as ''Database'',
	    A.[name],
	    A.[sid],
	    (CASE 
	        WHEN C.principal_id IS NULL THEN NULL -- Não tem o que fazer.. Login correspondente não existe
	        ELSE ''ALTER USER ['' + A.[name] + ''] WITH LOGIN = ['' + C.[name] + '']'' -- Tenta corrigir o usuário órfão
	    END) AS command
	FROM
	    sys.database_principals A WITH(NOLOCK)
	    LEFT JOIN sys.sql_logins B WITH(NOLOCK) ON A.[sid] = B.[sid]
	    LEFT JOIN sys.server_principals C WITH(NOLOCK) 
			ON (A.[name] COLLATE SQL_Latin1_General_CP1_CI_AI = C.[name] COLLATE SQL_Latin1_General_CP1_CI_AI OR A.[sid] = C.[sid]) 
			AND C.is_fixed_role = 0 
			AND C.[type_desc] = ''SQL_LOGIN''
		join sys.databases s on s.database_id = db_id()
	WHERE
	    A.principal_id > 4
	    AND B.[sid] IS NULL
	    AND A.is_fixed_role = 0
	    AND A.[type_desc] = ''SQL_USER''
	    AND A.authentication_type <> 0 -- NONE'

	exec (@sql)
	
	fetch next from cur_db into @database
end	


select 
	nm_server, 
	nm_database, 
	nm_user, 
	sid, 
	command,
	del = 'drop user ['+nm_user+']'
from ##tmp_usuarios 
order by nm_database, nm_user

