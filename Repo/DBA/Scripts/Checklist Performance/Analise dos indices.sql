/* Script 1*/

select  object_name(object_id) as table_name
,a.name as stats_name
,stats_date(object_id, stats_id) as last_update
from sys.stats a inner join sysobjects o
on a.object_id = o.id
where objectproperty(object_id, 'IsUserTable') = 1
--and o.name='corp_apolice'
order by last_update desc


/* Script 2*/

SELECT
    DB_NAME(u.database_id) As Banco, OBJECT_NAME(I.object_id) As Tabela, I.Name As Indice,
    U.User_Seeks As Pesquisas, U.User_Scans As Varreduras, U.User_Lookups As LookUps,
    U.Last_User_Seek As UltimaPesquisa, U.Last_User_Scan As UltimaVarredura,
    U.Last_User_LookUp As UltimoLookUp, U.Last_User_Update As UltimaAtualizacao
FROM
    sys.indexes As I
    LEFT OUTER JOIN sys.dm_db_index_usage_stats As U
    ON I.object_id = U.object_id AND I.index_id = U.index_id
    inner join sys.databases d
    on u.database_id = d.database_id
order by 1,4 desc    


/* Script 3*/

SELECT  
        [Total Cost]  = ROUND(avg_total_user_cost * avg_user_impact * (user_seeks + user_scans),0) 
        , avg_user_impact
        , TableName = statement
        , [EqualityUsage] = equality_columns 
        , [InequalityUsage] = inequality_columns
        , [Include Cloumns] = included_columns
FROM        sys.dm_db_missing_index_groups g 
INNER JOIN    sys.dm_db_missing_index_group_stats s 
       ON s.group_handle = g.index_group_handle 
INNER JOIN    sys.dm_db_missing_index_details d 
       ON d.index_handle = g.index_handle
       where avg_user_impact > 85.00
ORDER BY [Total Cost] DESC;



/* Script 4*/

USE master;
DECLARE @starttime datetime
SET @starttime = (SELECT crdate FROM sysdatabases WHERE name = 'tempdb' )

DECLARE @currenttime datetime
SET @currenttime = GETDATE()

DECLARE @difference_dd int
DECLARE @difference_hh int
DECLARE @difference_mi int

SET @difference_mi = (SELECT DATEDIFF(mi, @starttime, @currenttime))
SET @difference_dd = (@difference_mi/60/24)
SET @difference_mi = @difference_mi - (@difference_dd*60)*24
SET @difference_hh = (@difference_mi/60)
SET @difference_mi = @difference_mi - (@difference_hh*60)

select 'O serviço do SQL Server foi iniciado: ' 
+ CONVERT(varchar, @difference_dd) + ' dias ' 
+ CONVERT(varchar, @difference_hh) + ' horas ' 
+ CONVERT(varchar, @difference_mi) + ' minutos.'  