SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED 

if object_id('tempdb..#tmp_propostas','u') is not null
begin
	drop table #tmp_propostas 
end

create table #tmp_propostas
(
	id					int identity,
	id_proposta_tr		bigint,
	id_produto			int,
	dt_fim_vigencia_pai smalldatetime,
	nr_qtdsorteios		int
)


select	
	cp.Nr_proposta, 
	filha = cp.Dt_inicio_vigencia, 
	filhafim = cp.Dt_fim_vigencia,
	pai = cpant.Dt_fim_vigencia,
	paifim = cpant.Dt_fim_vigencia,
	cp.id_proposta, 
	cpt.id_proposta_tr,
	cp.Id_produto, 
	prod.Nm_produto, 
	cms.Nr_qtdsorteios, 
	ant.nr_proposta_tr	

	--update cp 	set cp.Dt_inicio_vigencia = '20170101', cp.Dt_fim_vigencia = '20170101'
from cap_proposta cp
join cap_proposta_Tr cpt
on cpt.Id_proposta = cp.Id_proposta
and cpt.id_proposta_tr_anterior is not null
join dbo.cap_produto prod
on prod.Id_produto = cp.Id_produto
join dbo.cap_modalidadesorteio cms
on cms.id_produto = prod.Id_produto
join dbo.cap_proposta_tr ant
on ant.id_proposta_Tr = cpt.id_proposta_tr_anterior
join dbo.cap_proposta cpant
on cpant.id_proposta = ant.Id_proposta