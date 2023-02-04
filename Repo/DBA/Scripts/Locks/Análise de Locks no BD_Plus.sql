


USE master
GO

ALTER PROCEDURE [dbo].[stpLock_Raiz]
AS
BEGIN
	-- Cria a tabela que ira armazenar os dados dos processos
	IF ( OBJECT_ID('tempdb..#Resultado_WhoisActive') IS NOT NULL )
		DROP TABLE #Resultado_WhoisActive
  
	CREATE TABLE #Resultado_WhoisActive (  
		[dd hh:mm:ss.mss]  VARCHAR(20),
		[database_name]   NVARCHAR(128),  
		[login_name]   NVARCHAR(128),
		[host_name]    NVARCHAR(128),
		[start_time]   DATETIME,
		[status]    VARCHAR(30),
		[session_id]   INT,
		[blocking_session_id] INT,
		[wait_info]    VARCHAR(MAX),
		[open_tran_count]  INT,
		[CPU]     VARCHAR(MAX),
		[reads]     VARCHAR(MAX),
		[writes]    VARCHAR(MAX),  
		[sql_command]   XML  
	)   
	
	---------------------------------------------------------------------------------------------------------------------------
	-- Carrega os Dados da sp_whoisactive
	--------------------------------------------------------------------------------------------------------------------------------
	-- Retorna todos os processos que est�o sendo executados no momento
	EXEC [dbo].[sp_whoisactive]
		@get_outer_command = 1,
		@output_column_list = '[dd hh:mm:ss.mss][database_name][login_name][host_name][start_time][status][session_id][blocking_session_id][wait_info][open_tran_count][CPU][reads][writes][sql_command]',
		@destination_table = '#Resultado_WhoisActive'

	-- Altera a coluna que possui o comando SQL
	ALTER TABLE #Resultado_WhoisActive
	ALTER COLUMN [sql_command] VARCHAR(MAX)
 
	UPDATE #Resultado_WhoisActive
	SET [sql_command] = REPLACE( REPLACE( REPLACE( REPLACE( CAST([sql_command] AS VARCHAR(1000)), '<?query --', ''), '--?>', ''), '&gt;', '>'), '&lt;', '')  

	--------------------------------------------------------------------------------------------------------------------------------
	-- Verifica o Nivel dos Locks
	--------------------------------------------------------------------------------------------------------------------------------
	ALTER TABLE #Resultado_WhoisActive
	ADD Nr_Nivel_Lock TINYINT 

	-- Nivel 0
	UPDATE A
	SET Nr_Nivel_Lock = 0
	FROM #Resultado_WhoisActive A
	WHERE blocking_session_id IS NULL AND session_id IN ( SELECT DISTINCT blocking_session_id 
				FROM #Resultado_WhoisActive WHERE blocking_session_id IS NOT NULL)

	UPDATE A
	SET Nr_Nivel_Lock = 1
	FROM #Resultado_WhoisActive A
	WHERE	Nr_Nivel_Lock IS NULL
			AND blocking_session_id IN ( SELECT DISTINCT session_id FROM #Resultado_WhoisActive WHERE Nr_Nivel_Lock = 0)

	UPDATE A
	SET Nr_Nivel_Lock = 2
	FROM #Resultado_WhoisActive A
	WHERE	Nr_Nivel_Lock IS NULL
			AND blocking_session_id IN ( SELECT DISTINCT session_id FROM #Resultado_WhoisActive WHERE Nr_Nivel_Lock = 1)

	UPDATE A
	SET Nr_Nivel_Lock = 3
	FROM #Resultado_WhoisActive A
	WHERE	Nr_Nivel_Lock IS NULL
			AND blocking_session_id IN ( SELECT DISTINCT session_id FROM #Resultado_WhoisActive WHERE Nr_Nivel_Lock = 2)

	-- Tratamento quando n�o tem um Lock Raiz
	IF NOT EXISTS(select * from #Resultado_WhoisActive where Nr_Nivel_Lock IS NOT NULL)
	BEGIN
		UPDATE A
		SET Nr_Nivel_Lock = 0
		FROM #Resultado_WhoisActive A
		WHERE session_id IN ( SELECT DISTINCT blocking_session_id 
			FROM #Resultado_WhoisActive WHERE blocking_session_id IS NOT NULL)
          
		UPDATE A
		SET Nr_Nivel_Lock = 1
		FROM #Resultado_WhoisActive A
		WHERE	Nr_Nivel_Lock IS NULL
				AND blocking_session_id IN ( SELECT DISTINCT session_id FROM #Resultado_WhoisActive WHERE Nr_Nivel_Lock = 0)

		UPDATE A
		SET Nr_Nivel_Lock = 2
		FROM #Resultado_WhoisActive A
		WHERE	Nr_Nivel_Lock IS NULL
				AND blocking_session_id IN ( SELECT DISTINCT session_id FROM #Resultado_WhoisActive WHERE Nr_Nivel_Lock = 1)

		UPDATE A
		SET Nr_Nivel_Lock = 3
		FROM #Resultado_WhoisActive A
		WHERE	Nr_Nivel_Lock IS NULL
				AND blocking_session_id IN ( SELECT DISTINCT session_id FROM #Resultado_WhoisActive WHERE Nr_Nivel_Lock = 2)
	END

	-- Retorna o resultado -- incluir nivel
	SELECT
		CAST(Nr_Nivel_Lock AS VARCHAR)       AS [Nr_Nivel_Lock],
		ISNULL([dd hh:mm:ss.mss], '-')       AS [Duracao], 
		ISNULL([database_name], '-')       AS [database_name],
		ISNULL([login_name], '-')        AS [login_name],
		ISNULL([host_name], '-')        AS [host_name],
		ISNULL(CONVERT(VARCHAR(20), [start_time], 120), '-') AS [start_time],
		ISNULL([status], '-')         AS [status],
		ISNULL(CAST([session_id] AS VARCHAR), '-')    AS [session_id],
		ISNULL(CAST([blocking_session_id] AS VARCHAR), '-')  AS [blocking_session_id],
		ISNULL([wait_info], '-')        AS [Wait],
		ISNULL(CAST([open_tran_count] AS VARCHAR), '-')   AS [open_tran_count],
		ISNULL([CPU], '-')          AS [CPU],
		ISNULL([reads], '-')         AS [reads],
		ISNULL([writes], '-')         AS [writes],
		[sql_command]
	FROM #Resultado_WhoisActive
	WHERE Nr_Nivel_Lock IS NOT NULL
	ORDER BY [Nr_Nivel_Lock], [start_time] 

	if object_id('tempdb..#temp_table','u') is not null
	begin
		drop table #temp_table
	end
	
	set nocount on;

	select 
		spid, blocked, replace( replace( t.text, char(10), ' '), char(13), ' ') as batch
	into #temp_table
	from sys.sysprocesses r
	cross apply sys.dm_exec_sql_text(R.sql_handle) t;
	
	
	with blockers (spid, blocked, level, batch)
	as
	(select
		spid,
		blocked,
		cast(replicate('0', 4- len(cast (SPID as varchar))) + cast(spid as varchar) as varchar(1000)) as level,
		batch 
	from #temp_table R
	where (blocked = 0 or blocked = spid)
	and exists (select * from #temp_table R2 where R2.blocked = r.spid and R2.blocked <> R2.spid)
	union all
	
	select
		R.spid,
		R.blocked,
		cast(blockers.level + right(cast ((1000 + R.SPID) as varchar(100)), 4) as varchar(1000)) as level,
		R.batch 
	from #temp_table R
	inner join blockers 
	on r.blocked = blockers.spid where r.blocked > 0 and r.blocked <> R.spid
	)
	
	select
		N' ' + replicate(N'| ', len(level)/4 -1) +
		case when (len(level)/4 - 1) = 0
		then 'HEAD - '
		else '|------' END
		+ cast(spid as nvarchar(10)) + N' '+ batch as blocking_tree
	from blockers 
	order by level asc

END

GO



-- Primeira query que rodamos
EXEC sp_whoisactive

-- Query para 
EXEC stpLock_Raiz 



