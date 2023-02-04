-- Consultar flags ativas
dbcc tracestatus(-1)

-- Ativar monitoramento de deadlocks
dbcc traceon (1204,-1)
dbcc traceon (1222,-1)

-- Desabilita monitoramento de deadlocks
dbcc traceoff (1204,-1)
dbcc traceoff (1222,-1)

-- Limpa o error log
sp_cycle_errorlog

--Lê o errorlog e filtra por incidentes de deadlock
    if object_id('tempdb..#error_log') is not null drop table #error_log 

    create table #error_log 
    (
        logdate datetime, 
        processinfo varchar(1000), 
        text varchar(max)
    )

    insert into #error_log 
    exec xp_ReadErrorLog

    select 
        * 
    from #error_log 
    where logdate in (select logdate from #error_log where text like '%Deadlock encountered%') 


    /*Exemplos */

    --Criar tabela de teste
    create table dbo.lock_table
    (
	    id int,
	    nm_pessoa varchar(50)
    )
     
    --Session 1
    begin tran

        insert into dbo.lock_table values (1, 'Gigio ')
            /* Session  2
        	begin tran

			    insert into dbo.lock_table values (1, 'FlaviooooAo Tomo Kill')

			    delete dbo.lock_table
            */
        delete dbo.lock_table

    rollback