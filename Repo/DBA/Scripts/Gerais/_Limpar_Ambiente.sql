USE master
GO

declare @sql varchar(max),@db varchar(120)

DECLARE cur_db cursor for select name from sys.databases 
where name like '%_head'
--or name in('db_i4pro_interface','bd_i4pro_interface')

open cur_db 

fetch cur_db into @db

while @@fetch_status = 0
begin
set @sql='use '+@db+'




		truncate table eng.t_log_operacao_campo
truncate table eng.t_log_operacao_relatorio
delete eng.t_log_operacao

delete dbo.t_auditoria_acao_parametro
DBCC CHECKIDENT (''dbo.t_auditoria_acao_parametro'', RESEED, 1)
delete dbo.t_auditoria_acao
DBCC CHECKIDENT (''dbo.t_auditoria_acao'', RESEED, 1)
delete eng.t_catalogo
DBCC CHECKIDENT (''eng.t_catalogo'', RESEED, 1)
delete eng.t_certificacao_digital_trace
DBCC CHECKIDENT (''eng.t_certificacao_digital_trace'', RESEED, 1)
delete eng.t_coleta_log
DBCC CHECKIDENT (''eng.t_coleta_log'', RESEED, 1)
delete eng.t_data_expiracao_bloqueio_usuario
DBCC CHECKIDENT (''eng.t_data_expiracao_bloqueio_usuario'', RESEED, 1)
delete eng.t_diagnostico_client
DBCC CHECKIDENT (''eng.t_diagnostico_client'', RESEED, 1)
delete eng.t_diagnostico_server_aplicacao
DBCC CHECKIDENT (''eng.t_diagnostico_server_aplicacao'', RESEED, 1)
delete eng.t_diagnostico_server_objeto
DBCC CHECKIDENT (''eng.t_diagnostico_server_objeto'', RESEED, 1)
delete eng.t_diagnostico_server_sql
DBCC CHECKIDENT (''eng.t_diagnostico_server_sql'', RESEED, 1)
delete eng.t_diagnostico_server
DBCC CHECKIDENT (''eng.t_diagnostico_server'', RESEED, 1)
delete eng.t_log_erro
DBCC CHECKIDENT (''eng.t_log_erro'', RESEED, 1)
delete eng.t_log_erro_parametros
delete eng.t_log_geracao_relatorio
DBCC CHECKIDENT (''eng.t_log_geracao_relatorio'', RESEED, 1)
delete eng.t_geracao_relatorio
DBCC CHECKIDENT (''eng.t_geracao_relatorio'', RESEED, 1)
delete eng.t_log_inconsistencia
DBCC CHECKIDENT (''eng.t_log_inconsistencia'', RESEED, 1)
delete eng.t_log_operacao_campo
delete eng.t_log_operacao_relatorio
delete eng.t_log_operacao
DBCC CHECKIDENT (''eng.t_log_operacao'', RESEED, 1)
delete eng.t_manual_log
DBCC CHECKIDENT (''eng.t_manual_log'', RESEED, 1)
	if exists (select 1 from sys.schemas s join sys.tables t on s.schema_id = t.schema_id 
		 where s.name=''eng'' and t.name=''t_modulo_macro_log_operacao'')
		 begin
		delete eng.t_modulo_macro_log_operacao
		DBCC CHECKIDENT (''eng.t_modulo_macro_log_operacao'', RESEED, 1)
		end
		if exists (select 1 from sys.schemas s join sys.tables t on s.schema_id = t.schema_id 
		 where s.name=''eng'' and t.name=''t_modulo_macro_log'')
		 begin
		delete eng.t_modulo_macro_log
		DBCC CHECKIDENT (''eng.t_modulo_macro_log'', RESEED, 1)
		end
delete eng.t_servico_log_chamada
if exists (select 1 from sys.schemas s join sys.tables t on s.schema_id = t.schema_id 
		 where s.name=''eng'' and t.name=''t_sessao_aberta_ims'')
		 begin
		delete eng.t_sessao_aberta_ims
		end
delete eng.t_status_sistema_log
DBCC CHECKIDENT (''eng.t_status_sistema_log'', RESEED, 1)
delete eng.t_status_sistema


    delete eng.t_relatorio_agrupamento_relatorio_log
    delete eng.t_relatorio_empresa_log
    delete eng.t_relatorio_parametro_log
    delete eng.t_relatorio_log
    DBCC CHECKIDENT (''eng.t_relatorio_log'', RESEED, 1)

    delete eng.t_tela_coluna_condicao_coluna_log
    delete eng.t_tela_coluna_condicao_acao_log
    delete eng.t_tela_coluna_condicao_log
    delete eng.t_tela_coluna_propriedade_log
    delete eng.t_tela_coluna_log
    delete eng.t_tela_acao_propriedade_log
    delete eng.t_tela_acao_log
    delete eng.t_tela_grupo_coluna_propriedade_log
    delete eng.t_tela_grupo_coluna_log
    delete eng.t_tela_coluna_manual_log
    DBCC CHECKIDENT (''eng.t_tela_coluna_manual_log'', RESEED, 1)
    delete eng.t_tela_manual_log
    DBCC CHECKIDENT (''eng.t_tela_manual_log'', RESEED, 1)
    delete eng.t_tela_log

delete eng.t_tela_objeto_copy_paste
DBCC CHECKIDENT (''eng.t_tela_objeto_copy_paste'', RESEED, 1)


--ErpFila2
if OBJECT_ID(''sdk_fila_log_old'') is not null
	exec(''DELETE sdk_fila_log_old'')

if OBJECT_ID(''sdk_fila_execucao_log_old'') is not null
	exec(''DELETE sdk_fila_execucao_log_old'')

if OBJECT_ID(''sdk_fila_execucao_grupo_log_old'') is not null
	exec(''DELETE sdk_fila_execucao_grupo_log_old'')

if OBJECT_ID(''sdk_fila_execucao_contexto_old'') is not null
	exec(''DELETE sdk_fila_execucao_contexto_old'')

if OBJECT_ID(''sdk_fila_execucao_old'') is not null
	exec(''DELETE sdk_fila_execucao_old'')

if OBJECT_ID(''sdk_fila_execucao_grupo_old'') is not null
	exec(''DELETE sdk_fila_execucao_grupo_old'')

--ErpFila2.5
if OBJECT_ID(''fil.t_execucao_log_old'') is not null
	exec(''DELETE fil.t_execucao_log_old'')

if OBJECT_ID(''fil.t_execucao_grupo_log_old'') is not null
	exec(''DELETE fil.t_execucao_grupo_log_old'')

if OBJECT_ID(''fil.t_execucao_contexto_old'') is not null
	exec(''DELETE fil.t_execucao_contexto_old'')

if OBJECT_ID(''fil.t_execucao_old'') is not null
	exec(''DELETE fil.t_execucao_old'')

if OBJECT_ID(''fil.t_execucao_grupo_old'') is not null
	exec(''DELETE fil.t_execucao_grupo_old'')

--ErpFila3
if OBJECT_ID(''fil.[t_atividade_log]'') is not null
	exec(''DELETE fil.[t_atividade_log]'')

if OBJECT_ID(''fil.[t_atividade_contexto]'') is not null
	exec(''DELETE fil.[t_atividade_contexto]'')

if OBJECT_ID(''fil.[t_atividade_retorno]'') is not null
	exec(''DELETE fil.[t_atividade_retorno]'')

if OBJECT_ID(''fil.[t_atividade_retorno]'') is not null
	exec(''DELETE fil.[t_atividade_retorno]'')

if OBJECT_ID(''fil.[t_atividade]'') is not null
	exec(''DELETE fil.[t_atividade]'')

if OBJECT_ID(''fil.[t_andamento_log]'') is not null
	exec(''DELETE fil.[t_andamento_log]'')

if OBJECT_ID(''fil.[t_andamento]'') is not null
begin
	exec(''DELETE fil.[t_andamento]'')
end

--ErpMiddleware2
if OBJECT_ID(''[sdk_middleware_lote_detalhe]'') is not null
	exec(''DELETE [sdk_middleware_lote_detalhe]'')

if OBJECT_ID(''[sdk_middleware_lote_header]'') is not null
begin
	exec(''DELETE [sdk_middleware_lote_header]'')
end

if OBJECT_ID(''[sdk_middleware_arquivo]'') is not null
begin
	exec(''DELETE [sdk_middleware_arquivo]'')
end

if OBJECT_ID(''[sdk_processamento_log]'') is not null
	exec(''DELETE [sdk_processamento_log]'')

--ErpMiddleware1

if OBJECT_ID(''[corp_interfacenovo_lote_ocorrencia]'') is not null
	exec(''DELETE [corp_interfacenovo_lote_ocorrencia]'')

if OBJECT_ID(''[corp_interfacenovo_lote_txt]'') is not null
	exec(''DELETE [corp_interfacenovo_lote_txt]'')

if OBJECT_ID(''[corp_interfacenovo_lote_header]'') is not null
	exec(''DELETE [corp_interfacenovo_lote_header]'')

--ErpProcessamento
if OBJECT_ID(''corp_processo_log'') is not null
	exec(''DELETE corp_processo_log'')

if OBJECT_ID(''corp_grupo_processo_log'') is not null
	exec(''DELETE corp_grupo_processo_log'')

'

select @db

exec (@sql)

fetch next from cur_db into @db

end

close cur_db
deallocate cur_db
go
delete from [alife_erp_head].[dbo].[tk_segurado_acumulo] 
go
delete from [alife_erp_head].[dbo].[tk_cap_bnb] 
go
delete from [alife_erp_head].[dbo].[corp_log_emissao_apolice] 
go
delete from [alife_erp_head].[dbo].[tk_saldo_mov_sinistro] 
go
delete from [alife_erp_head].[dbo].[tbkpi_fato_emissao_diaria] 
go
delete from [alife_erp_head].[dbo].[tk_controle_processamento_carteira] 
go
delete from [alife_erp_head].[dbo].[tk_controle_importacao_carteira] 
go
delete from [alife_erp_head].[dbo].[corp_log_regra] 
go
delete from [alife_erp_head].[dbo].[tk_log_item_segurado] 
go
delete from [alife_erp_head].[dbo].[t_coluna_cliente] 
go
delete from [alife_erp_head].[dbo].[tk_fatura] 
go
delete from [alife_erp_head].[dbo].[corp_acompanha_rotina] 
go
delete from [alife_erp_head].[dbo].[tk_corretores_sp] 
go
delete from [apvs_erp_head].[dbo].[t_coluna_cliente] 
go
delete from [apvs_erp_head].[dbo].[corp_acompanha_rotina] 
go
delete from [apvs_truck_head].[dbo].[t_coluna_cliente] 
go
delete from [apvs_truck_head].[dbo].[corp_acompanha_rotina] 
go
delete from [bmg_erp_head].[dbo].[pagtos_dez_outros_ramos] 
go
delete from [bmg_erp_head].[dbo].[tbl_envio_diario_resseguro_fechamento] 
go
delete from [bmg_erp_head].[dbo].[corp_pessoa_produto_bk] 
go
delete from [essor_erp_head].[dbo].[premrec_subvencao_contabil] 
go
delete from [essor_erp_head].[dbo].[uss_auto_apolice_vigencia] 
go
delete from [essor_erp_head].[dbo].[sdk_recibo_externo_corretor] 
go
delete from [essor_erp_head].[dbo].[plan_contabil_plano_conta] 
go
delete from [essor_erp_head].[dbo].[corp_acompanha_rotina] 
go
delete from [i4pro_edn_head].[dbo].[cep_log_bkp] 
go
delete from [i4pro_edn_head].[dbo].[corp_acompanha_rotina] 
go
delete from [i4pro_edn_head].[dbo].[corp_circ_resprem] 
go
delete from [i4pro_edn_head].[dbo].[corp_circ_premrec] 
go
delete from [i4pro_edn_head].[dbo].[corp_pesseoas_coretor_log] 
go
delete from [i4pro_edn_head].[dbo].[corp_fecha_parcela_longo_prazo] 
go
delete from [i4pro_edn_head].[dbo].[cep_bai_bkp] 
go
delete from [i4pro_edn_head].[dbo].[corp_processo_impressao] 
go
delete from [i4pro_edn_head].[dbo].[corp_log_emissao_apolice] 
go
delete from [i4pro_edn_head].[dbo].[corp_log_cobranca_sistema] 
go
delete from [investre_erp_head].[dbo].[tmp_limpa_pessoas] 
go
delete from [jm_erp_head].[dbo].[corp_acompanha_rotina] 
go
delete from [jm_erp_head].[dbo].[corp_parc_movto_log] 
go
delete from [jm_erp_head].[dbo].[corp_circ_corretagen] 
go
delete from [jm_erp_head].[dbo].[corp_interface_fip_quadro_270] 
go
delete from [jm_erp_head].[dbo].[corp_interface_fip_quadro_271] 
go
delete from [jns_erp_head].[edn].[t_integraçao_corretor_ags] 
go
delete from [jns_erp_head].[dbo].[corp_acompanha_rotina] 
go
delete from [mitsui_erp_head].[dbo].[premrec_subvencao_segurado_contabil] 
go
delete from [mitsui_erp_head].[dbo].[premrec_subvencao_contabil] 
go
delete from [mitsui_erp_head].[dbo].[sdk_recibo_externo_corretor] 
go
delete from [mitsui_erp_head].[dbo].[plan_contabil_plano_conta] 
go
delete from [mitsui_erp_head].[dbo].[corp_pessoas_fisica_bkpcad] 
go
delete from [mitsui_erp_head].[lgpd].[t_dicionario_conteudo] 
go
delete from [mitsui_erp_head].[lgpd].[t_dicionario_modelagem] 
go
delete from [mitsui_erp_head].[dbo].[corp_endereco_bkpcad] 
go
delete from [mitsui_erp_head].[hom].[hm_passo_cenario] 
go
delete from [omint_erp_head].[dbo].[tmp_limpa_pessoas] 
go
delete from [omint_erp_head].[dbo].[t_coluna_dev] 
go
delete from [omint_erp_head].[dbo].[cotacao_atualizada'] 
go
delete from [tokio_erp_head].[dbo].[corp_acompanha_rotina] 
go
delete from [tokio_erp_head].[dbo].[corp_debug] 
go
delete from [tokio_erp_head].[dbo].[inter_i4pro_alteracao_parcela] 

delete from [twg_erp_head].[dbo].[corp_acompanha_rotina] 
go
delete from [zurich_erp_head].[dbo].[corp_acompanha_rotina] 
go
delete from [zurich_erp_head].[dbo].[corp_essor_dbf] 
go
delete from [zurich_erp_head].[dbo].[corp_circ_premrecec_subvencao_emp230] 
go
delete from [zurich_erp_head].[dbo].[corp_pessoas_papel_bkpcad] 
go
delete from [zurich_erp_head].[dbo].[sdk_recibo_externo_corretor] 
go
delete from [zurich_erp_head].[dbo].[plan_contabil_plano_conta] 

