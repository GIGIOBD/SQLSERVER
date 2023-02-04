dbcc show_statistics  'corp_endosso'

DBCC SHOW_STATISTICS ('corp_endosso', 'pe_premio_adiantamento_corr') --WITH DENSITY_VECTOR;

create nonclustered index a_teste_statistica on corp_endosso (id_sub,cd_forma_pagamento)
drop index a_teste_statistica on corp_endosso 

SELECT
        S.name   AS StatisticsName,
      STATS_DATE(S.object_id,   S.stats_id) AS StatisticsUpdatedDate,
                  S.auto_created,
                  S.user_created,
                  S.no_recompute,
                  S.has_filter,
                  S.filter_definition,
                  S.is_temporary,
                  S.is_incremental,
                  SP.rows,
                  SP.rows_sampled,
                  SP.steps,
                  SP.unfiltered_rows,
                  SP.modification_counter
FROM sys.stats S
OUTER APPLY sys.dm_db_stats_properties(S.object_id, S.stats_id) as SP
WHERE OBJECT_NAME(S.object_id) = 'corp_endosso'
ORDER BY name;
GO

if exists (select 1 from sys.stats s where s.name like 'pe_premio_adiantamento_corr'and object_name(s.object_id) = 'corp_endosso')
begin
	DROP STATISTICS dbo.corp_endosso.pe_premio_adiantamento_corr;
end

DROP STATISTICS sys.filetable_updates_211024033.item_guid ;

CREATE STATISTICS pe_premio_adiantamento_corr  ON dbo.corp_endosso (pe_premio_adiantamento_corr) ;      


CREATE STATISTICS item_guid  ON sys.filetable_updates_211024033 (item_guid,table_id,oplsn_slotid) ;      


sys.filetable_updates_211024033.item_guid

item_guid,oplsn_bOffset,oplsn_fseqno,oplsn_slotid,table_id