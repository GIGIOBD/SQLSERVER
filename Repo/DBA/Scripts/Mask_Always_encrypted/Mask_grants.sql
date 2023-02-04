/* Grant em colunas especificas */
	GRANT SELECT ON dbo.t_pessoa(vl_salario) TO [I4PROINFO\rodferreira]

	DENY SELECT ON dbo.Funcionario(Salario) TO [usrTestePermission]

	GRANT SELECT ON dbo.Funcionario(Salario) TO [usrTestePermission]
	
/* Teste com outro User */
EXECUTE AS USER = 'I4PROINFO\powerbi';  

--senha mascarateste
select * from dw.t_colaborador_linha_tempo;
--SELECT * FROM dbo.t_pessoa_consultor;  

REVERT;

/* Grant e Revoke permissão */
GRANT UNMASK TO [I4PROINFO\g-sql-processos]; 
REVOKE UNMASK TO [I4PROINFO\g-sql-processos];


Use [i4pro_pallas_pro]; 
IF DATABASE_PRINCIPAL_ID('db_unmask') IS NULL CREATE ROLE [db_unmask] ;

--create schema [db_unmask]


--IF SCHEMA_ID('db_unmask') IS NOT NULL GRANT SELECT ON SCHEMA::[db_unmask] TO [mascara] AS [dbo];
GRANT UNMASK TO [db_unmask] AS [dbo];

EXEC sp_addrolemember @rolename = 'db_unmask',@membername = 'I4PROINFO\rodferreira';

EXEC sp_droprolemember @rolename = 'db_unmask',@membername = 'I4PROINFO\rodferreira';




select DATABASE_PRINCIPAL_ID('db_unmask') 
select SCHEMA_ID('db_unmask')
grant unmask to role [db_unmask]

/*
use i4pro_pallas_hom
GO

IF DATABASE_PRINCIPAL_ID('db_unmask') IS NULL CREATE ROLE [db_unmask] ;
GO

GRANT UNMASK TO [db_unmask] AS [dbo];
GO

EXEC sp_addrolemember @rolename = 'db_unmask',@membername = [I4PROINFO\g-sql-processos]

EXEC sp_droprolemember @rolename = 'db_unmask',@membername =[I4PROINFO\g-sql-processos]

*/