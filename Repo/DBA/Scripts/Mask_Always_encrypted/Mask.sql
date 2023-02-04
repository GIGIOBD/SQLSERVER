/* Consultar colunas com masked */
SELECT 
	TBLS.name as TableName,
	MC.NAME ColumnName, 
	MC.is_masked IsMasked, 
	MC.masking_function MaskFunction  
FROM sys.masked_columns AS MC 
JOIN sys.tables AS TBLS   
ON MC.object_id = TBLS.object_id  
WHERE is_masked = 1;   


-- db_owner consegue ver os dados
alter table cad.t_pessoas
alter column nm_pessoa add masked with(function='partial(0,"xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",0)')


create table corp_teste(id_teste int,
[nm_teste] varchar(80)  masked with(function='partial(0, "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx", 0)' ))


alter table dbo.corp_teste
alter column nm_cript add masked with(function='partial(0, "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx", 0)' )


ALTER TABLE corp_pessoas   
ALTER COLUMN nm_pessoa DROP MASKED;  

select nm_pessoa from corp_pessoas_criptografia

GRANT EXECUTE TO [homhead];

-- criando o campo com a mascara
alter table [dbo].[corp_teste] 
add [nm_endereco] varchar(80)  masked with(function='partial(0, "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx", 0)' )null 

alter table [dbo].[corp_teste]
drop column nm_teste

SELECT s.name,c.name, t.name as table_name, c.is_masked, c.masking_function  
FROM sys.masked_columns AS c  
JOIN sys.tables AS t   
    ON c.[object_id] = t.[object_id]  
join sys.schemas s
on s.schema_id = t.schema_id
WHERE is_masked = 1;  

GRANT UNMASK TO homhead; -- dando permissão para ver tudo

revoke UNMASK TO usr_engine_mask; -- tirando a permissão

create table teste(dt_emissao datetime)

alter table [dbo].[teste] 
alter column dt_emissao ADD MASKED WITH(FUNCTION = 'default()')


insert into teste values('2021-03-17')

