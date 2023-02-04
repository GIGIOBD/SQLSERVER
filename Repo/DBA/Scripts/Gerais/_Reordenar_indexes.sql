begin tran
if object_id('tempdb..#temp_comandos','u') is not null
begin
	drop table #temp_comandos 
end

create table #temp_comandos 
(
	id				int identity,
	nm_tabela		varchar(1000),
	nm_indice		varchar(max),
	nm_comando		varchar(max),
	pe_fragmentacao numeric(15,13)
)

if object_id('tempdb..#temp_exec','u') is not null
begin
	drop table #temp_exec 
end
create table #temp_exec
(
	id				int identity,
	nm_comando		varchar(max)
)



insert into #temp_comandos (nm_tabela, nm_indice, pe_fragmentacao, nm_comando)
-- Consultar a fragmentação média:
select
    nome_tabela = object_name(b.object_id),
    nome_indice = name, 
    fragmentacao_media = avg_fragmentation_in_percent,
    script = case
        when avg_fragmentation_in_percent > 30 then 'alter index ' + name + ' on ' + object_name(b.object_id) + ' rebuild with (online = on)'
        when avg_fragmentation_in_percent >= 5 and avg_fragmentation_in_percent <= 30 then 'alter index ' + name + ' on ' + object_name(b.object_id) + ' reorganize'
    end
from sys.dm_db_index_physical_stats (db_id('porto_cap_hom'), null, null, null, null) as a -- (Parâmetros da função: banco de dados, tabela, indice, partição física, modo de analise: default, null, limited (limitado), sampled (amostra), detailed (detalhado))
join sys.indexes as b on a.object_id = b.object_id and a.index_id = b.index_id

insert into #temp_exec (nm_comando)
select
	nm_comando
from #temp_comandos
where nm_comando is not null
and nm_comando not like '%PK%'

declare 
	@contador	int = 1,
	@qtd_index	int	= (select count(1) from #temp_exec),
	@sql		varchar(max)

while @contador <= @qtd_index
begin
	select
		@sql = nm_comando
	from #temp_exec 
	where id = @contador

	--exec (@sql)
	select (@sql)
	set @contador = @contador + 1
end

rollback

--begin tran
--declare 
--	@sql2 varchar(max) = 'alter index XIF3cap_complemento_PF on cap_complemento_PF rebuild with (online = on)'

--exec (@sql2)


--select @@VERSION