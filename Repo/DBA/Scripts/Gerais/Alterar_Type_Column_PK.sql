--select * from  edn.t_mapa_sisser_dados_proposta_cobertura
--insert into edn.t_mapa_sisser_dados_proposta_cobertura (id_proposta) values (7 )
--select * from edn.t_mapa_sisser_dados_proposta
--insert into edn.t_mapa_sisser_dados_proposta (id_endosso) values (rand(10))

ALTER TABLE edn.t_mapa_sisser_dados_proposta_cobertura ADD id_proposta_cobertura3 BIGINT IDENTITY
GO

UPDATE edn.t_mapa_sisser_dados_proposta_cobertura SET id_proposta_cobertura = id_proposta_cobertura3
GO

ALTER TABLE [edn].[t_mapa_sisser_dados_proposta_cobertura] DROP CONSTRAINT [PK_t_mapa_sisser_dados_proposta_cobertura(id_proposta_cobertura)] WITH ( ONLINE = ON )
GO

ALTER TABLE [edn].[t_mapa_sisser_dados_proposta_cobertura] DROP COLUMN id_proposta_cobertura
GO

ALTER TABLE [edn].[t_mapa_sisser_dados_proposta_cobertura] ADD CONSTRAINT [PK_t_mapa_sisser_dados_proposta_cobertura(id_proposta_cobertura)] PRIMARY KEY CLUSTERED
(
id_proposta_cobertura3 ASC
)
GO
EXEC sp_rename 'edn.t_mapa_sisser_dados_proposta_cobertura.id_proposta_cobertura3', 'id_proposta_cobertura', 'COLUMN'
GO

