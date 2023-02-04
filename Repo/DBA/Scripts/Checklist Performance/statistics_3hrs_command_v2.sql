		 SELECT
			--A.object_id,
			--A.name AS [object_name],
			--s.name as [statistics_name],
			--B.last_user_update as B_last_updated_object,
			--datediff(HOUR,B.last_user_update,GETDATE()) as TmpSem_Atualiza_dados
			--,D.last_updated as D_last_updated_statitics
			--,datediff(HOUR,B.last_user_update,GETDATE()),
			--datediff(HOUR,D.last_updated,GETDATE()) TmpSem_Atualiza_stats
			'update statistics '+ sc.name +'.'+A.name + '  ['+ s.name +']' as command
		FROM sys.objects                                 A
		join sys.schemas sc on sc.schema_id = A.schema_id
		LEFT JOIN sys.dm_db_index_usage_stats       B	ON	B.[object_id] = A.[object_id] AND B.[database_id] = DB_ID()	
		JOIN sys.stats s on s.object_id = A.object_id
		OUTER APPLY sys.dm_db_stats_properties(s.object_id, s.stats_id) D
		WHERE A.[type_desc] IN ('VIEW', 'USER_TABLE')
		and A.name not in('corp_lancamento_contabil','t_log_operacao_campo','corp_acompanha_rotina','t_servico_log_chamada','t_ecm_documento','t_documento'
		,'t_documento_conteudo','sdk_processamento_log')		
		and datediff(HOUR,isnull(D.last_updated,'19000101'),GETDATE()) > 3			--ultima atualização de statistics
        and D.modification_counter > 1000