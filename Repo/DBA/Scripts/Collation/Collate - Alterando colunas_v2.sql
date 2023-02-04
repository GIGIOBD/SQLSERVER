/**************************************************************************

Autor	= Alexandre Shinoda
Empresa = I4PRO
OBJETIVO= Troca do Collate das colunas do database em que for executado.
		  	
Executar o script no database que deseja trocar o Collate		  	

select 'drop table '+s.name+'.'+ t.name, * from sys.tables t 
join sys.schemas s
on s.schema_id = t.schema_id
where s.name = 'tSQLt'

USE master;
GO
ALTER DATABASE capemisa_erp_azure2
SET SINGLE_USER
WITH ROLLBACK IMMEDIATE;
GO

USE master;
GO
ALTER DATABASE capemisa_erp_azure2
SET MULTI_USER;
GO

ALTER DATABASE [capemisa_erp_azure2] COLLATE SQL_Latin1_General_CP1_CI_AS;

sp_helptext 'dbo.f_multiselect_to_table'
**************************************************************************/
use capemisa_erp_azure2
GO

declare @cmd varchar(200)

if not exists (select 1 from sys.schemas where name = 'migracao')
begin
	 set @cmd = 'create schema migracao'
	 exec (@cmd)
end
GO



set nocount on

declare @collate varchar(50), 
		@collate_novo varchar(50),
		@tab_atu	varchar(255),
		@tab_ant	varchar(255),
		@ind_ant	varchar(255),
		@ind_atu	varchar(255),
		@col		varchar(255),
		@idx		varchar(500),
		@cmd		varchar(700),
		@database	varchar(100),
		@msgerror	varchar(700)

		

set @collate = 'SQL_Latin1_General_CP1_CI_AI' -- aqui collate que será alterado
set @collate_novo = 'SQL_Latin1_General_CP1_CI_AS' -- aqui COLLATE NOVO
set @tab_ant ='A' 
set @ind_ant = 'A'

 
/*************************** Atenção ********************************************/

IF OBJECT_ID('drop_object', 'U') IS NOT NULL DROP TABLE drop_object 
IF OBJECT_ID('migracao.create_object', 'U') IS NOT NULL DROP TABLE migracao.create_object
IF OBJECT_ID('collate_object', 'U') IS NOT NULL DROP TABLE collate_object
IF OBJECT_ID('migracao.fk_tmp', 'U') IS NOT NULL DROP TABLE migracao.fk_tmp
IF OBJECT_ID('migracao.pk_tmp', 'U') IS NOT NULL DROP TABLE migracao.pk_tmp
IF OBJECT_ID('migracao.uq_tmp', 'U') IS NOT NULL DROP TABLE migracao.uq_tmp
IF OBJECT_ID('migracao.ind_tmp', 'U') IS NOT NULL DROP TABLE migracao.ind_tmp

---- tabela para armazenarmos os drops
--create table migracao.drop_objet(
--cmd varchar(500),
--seq decimal(1)
--)

------ tabela para armazenarmos as colunas que terão o collate alterado
--create table migracao.create_object(
--cmd varchar(500),
--seq decimal(1)
--)

-- --tabela para armazenarmos as FKs 
--drop table [migracao].[fk_tmp] 
--CREATE TABLE [migracao].[fk_tmp](
--	[schem] [sysname] NOT NULL,
--	[tabela_filha] [sysname] NOT NULL,
--	[constraint_indice] [sysname] NOT NULL,
--	[tabela_pai] [sysname] NOT NULL,
--	[coluna_filha] [varchar](500) NULL,
--	[coluna_pai] [varchar](500) NULL
--) ON [PRIMARY]
--GO
-- --tabela para armazenarmos as PKs e UQs
--DROP TABLE migracao.pk_tmp
--CREATE TABLE [migracao].[pk_tmp](
--	[schem] [sysname] NOT NULL,
--	[tabela] [sysname] NOT NULL,
--	[Constraint_indice] [sysname] NULL,
--	[coluna] [varchar](500) NULL
--) ON [PRIMARY]
--GO



-- --tabela para armazenarmos os indices
--drop table [migracao].[ind_tmp]
--CREATE TABLE [migracao].[ind_tmp](
--	[schem] [sysname] NOT NULL,
--	tabela varchar(255),
--	constraint_indice varchar(255),
--	coluna varchar(500)
--) ON [PRIMARY]
--GO

--drop table uq_tmp 

--CREATE TABLE [migracao].[uq_tmp](
--	[schem] [sysname] NOT NULL,
--	[tabela] [sysname] NOT NULL,
--	[Constraint_indice] [sysname] NULL,
--	[coluna] [varchar](500) NULL
--) ON [PRIMARY]
--GO


/************************************************ FK INICIO ************************************************/

-- Inserindo quais FKs utilizam colunas com o Collate a ser alterado


--insert into migracao.fk_tmp(tabela_filha,constraint_indice,tabela_pai)
select distinct s.name schem,fil.name tabela_filha,obj.name constraint_indice,pai.name tabela_pai,REPLICATE(' ',500) coluna_filha,REPLICATE(' ',500) coluna_pai 
into migracao.fk_tmp
from sys.tables fil 
		inner join sys.columns col		
				on col.object_id = fil.object_id	
		inner join 	sys.foreign_key_columns fkc
				on fil.object_id = fkc.parent_object_id		
				and col.column_id = fkc.parent_column_id	
		inner join sys.tables pai
				on 	pai.object_id = fkc.referenced_object_id
		inner join sysobjects obj
				on fkc.constraint_object_id = obj.id
		inner join sys.schemas s 
				on fil.schema_id = s.schema_id								
where col.collation_name = @collate
and s.name <> 'migracao'

-- Verificando quais colunas pertencem a FK

declare @schem varchar(112), @schem_ant varchar(112),@parent_column_id smallint

set @schem =''
set @schem_ant =''


declare cur_fk cursor for 
select f.schem,f.tabela_filha,f.constraint_indice,col.name , fkc.referenced_column_id
from sys.tables fil 
		inner join sys.columns col		
				on col.object_id = fil.object_id	
		inner join sys.types typ
				on col.user_type_id = typ.user_type_id
		inner join 	sys.foreign_key_columns fkc
				on fil.object_id = fkc.parent_object_id		
				and col.column_id = fkc.parent_column_id	
		inner join sysobjects obj
				on fkc.constraint_object_id = obj.id
	
		inner join migracao.fk_tmp f
				on f.tabela_filha = fil.name
				and f.constraint_indice = obj.name 	
		
		order by 1,2,3,fkc.referenced_column_id


open cur_fk

fetch cur_fk into @schem,@tab_atu, @ind_atu, @col, @parent_column_id

while @@FETCH_STATUS = 0

begin 

	if @schem = @schem_ant and @tab_atu = @tab_ant and @ind_atu = @ind_ant 
	begin
		
		set @idx = @idx+','+@col
	
	end
	else
	begin
	
		set @idx = @col
	
	end
	
	
	select @schem_ant= @schem, @tab_ant = @tab_atu,@ind_ant = @ind_atu


		update migracao.fk_tmp
		set coluna_filha = '('+@idx+')'
		where tabela_filha = @tab_atu
		and constraint_indice = @ind_atu

	fetch next from cur_fk into @schem, @tab_atu, @ind_atu, @col,@parent_column_id
	

end
	
close  cur_fk
deallocate cur_fk


		--update migracao.fk_tmp
		--set constraint_indice = '['+constraint_indice+']'


/************************************************ FK FIM ************************************************/


/********************************************* PK E UQ INICIO *********************************************/

-- Inserindo quais PKs e UQs utilizam colunas com o Collate a ser alterado
--insert into migracao.pk_tmp(tabela,constraint_indice)
select distinct s.name schem,ob.name tabela,ix.name Constraint_indice, REPLICATE(' ',500) coluna
into migracao.pk_tmp
from sys.tables ob 
	inner join sys.indexes ix
		on ob.object_id = ix.object_id
	inner join sys.index_columns ic
		on	ob.object_id = ic.object_id
		and	ix.index_id = ic.index_id
	inner join sys.columns c
		on	ob.object_id = c.object_id
		and ic.column_id = c.column_id
	inner join sys.key_constraints con
		on ix.name = con.name
	inner join sys.schemas s
		on ob.schema_id = s.schema_id									
where c.collation_name = @collate
and s.name <> 'migracao'
and con.type='pk'

select distinct s.name schem,ob.name tabela,ix.name Constraint_indice, REPLICATE(' ',500) coluna
into migracao.uq_tmp
from sys.tables ob 
	inner join sys.indexes ix
		on ob.object_id = ix.object_id
	inner join sys.index_columns ic
		on	ob.object_id = ic.object_id
		and	ix.index_id = ic.index_id
	inner join sys.columns c
		on	ob.object_id = c.object_id
		and ic.column_id = c.column_id
	inner join sys.key_constraints con
		on ix.name = con.name
	inner join sys.schemas s
		on ob.schema_id = s.schema_id									
where c.collation_name = @collate
and s.name <> 'migracao'
and con.type='uq'



set @schem_ant =''
set @tab_ant =''
set @ind_ant = ''


declare @index_column_id smallint
		


-- Verificando quais colunas pertencem a PK/UQ
declare cur_pk cursor for 
select distinct migracao.pk_tmp.schem,ob.name tabela,ix.name Constraint_indice,c.name,ic.index_column_id
from sys.tables ob 
	inner join sys.indexes ix
		on ob.object_id = ix.object_id
	inner join sys.index_columns ic
		on	ob.object_id = ic.object_id
		and	ix.index_id = ic.index_id
	inner join sys.columns c
		on	ob.object_id = c.object_id
		and ic.column_id = c.column_id
	inner join sys.types typ
		on c.user_type_id = typ.user_type_id	
	inner join sys.key_constraints con
		on ix.name = con.name	
	inner join sys.schemas s
		on ob.schema_id = s.schema_id	
		and s.name <> 'migracao'
	inner join migracao.pk_tmp 
		on migracao.pk_tmp.tabela = ob.name
		and migracao.pk_tmp.constraint_indice = ix.name
		and migracao.pk_tmp.schem = s.name
				order by 1,2,3,ic.index_column_id

open cur_pk

fetch cur_pk into @schem, @tab_atu, @ind_atu, @col,@index_column_id

while @@FETCH_STATUS = 0

begin 

	if @schem = @schem_ant and @tab_atu = @tab_ant and @ind_atu = @ind_ant 
	begin
		
		set @idx = @idx+','+@col
	
	end
	else
	begin
	
		set @idx = @col
	
	end
	
	select @schem_ant = @schem, @tab_ant = @tab_atu,@ind_ant = @ind_atu
	
		update migracao.pk_tmp
		set coluna = '('+@idx+')'
		where tabela = @tab_atu
		and constraint_indice = @ind_atu
		and schem = @schem
		

	fetch next from cur_pk into @schem,@tab_atu, @ind_atu, @col,@index_column_id
	
	

end
	
close  cur_pk
deallocate cur_pk

set @schem_ant =''
set @tab_ant =''
set @ind_ant = ''


-- Verificando quais colunas pertencem a PK/UQ
declare cur_pk cursor for 
select distinct migracao.uq_tmp.schem,ob.name tabela,ix.name Constraint_indice,c.name,ic.index_column_id
from sys.tables ob 
	inner join sys.indexes ix
		on ob.object_id = ix.object_id
	inner join sys.index_columns ic
		on	ob.object_id = ic.object_id
		and	ix.index_id = ic.index_id
	inner join sys.columns c
		on	ob.object_id = c.object_id
		and ic.column_id = c.column_id
	inner join sys.types typ
		on c.user_type_id = typ.user_type_id	
	inner join sys.key_constraints con
		on ix.name = con.name									
	inner join migracao.uq_tmp
		on migracao.uq_tmp.tabela = ob.name
		and migracao.uq_tmp.constraint_indice = ix.name
		order by 1,2,3,ic.index_column_id


open cur_pk

fetch cur_pk into @schem, @tab_atu, @ind_atu, @col,@index_column_id

while @@FETCH_STATUS = 0

begin 

	if @schem = @schem_ant and @tab_atu = @tab_ant and @ind_atu = @ind_ant 
	begin
		
		set @idx = @idx+','+@col
	
	end
	else
	begin
	
		set @idx = @col
	
	end
	
	select @schem_ant = @schem, @tab_ant = @tab_atu,@ind_ant = @ind_atu
	
		update migracao.uq_tmp
		set coluna = '('+@idx+')'
		where tabela = @tab_atu
		and constraint_indice = @ind_atu

	fetch next from cur_pk into @schem,@tab_atu, @ind_atu, @col,@index_column_id
	
	

end
	
close  cur_pk
deallocate cur_pk


-- Armazenando a PK/UQ para dropar

update f
set coluna_pai = p.coluna
from migracao.fk_tmp f join migracao.pk_tmp p 
on f.tabela_pai = p.tabela


-- Armazenaremos os objetos FK para droparmos 
--insert into migracao.drop_objet(cmd,seq)
select 'alter table '+schem+'.'+tabela_filha+' drop constraint ['+constraint_indice+']' cmd, 1 seq
into drop_object
from migracao.fk_tmp

-- Armazenaremos os objetos FK para recriarmos 
--insert into migracao.create_object(cmd,seq)
select  'alter table '+schem+'.'+tabela_filha+' with nocheck add constraint ['+constraint_indice+ '] foreign key '+ coluna_filha+' references '+
		+schem+'.'+tabela_pai+coluna_pai cmd, 3 seq
into migracao.create_object
from migracao.fk_tmp	




insert into drop_object(cmd,seq)
select 'alter table '+schem+'.'+tabela+' drop constraint ['+constraint_indice+']' cmd,2 seq
--into migracao.drop_objet
from migracao.pk_tmp

insert into drop_object(cmd,seq)
select 'alter table '+schem+'.'+tabela+' drop constraint ['+constraint_indice+']' cmd,2 seq
--into migracao.drop_objet
from migracao.uq_tmp



-- Armazenando a PK/UQ para recriar
insert into migracao.create_object(cmd,seq)
select 'alter table '+schem+'.'+tabela+' add constraint ['+constraint_indice+'] primary key '+coluna cmd,2 seq
--into migracao.create_object
from migracao.pk_tmp
where constraint_indice like 'pk%'

insert into migracao.create_object(cmd,seq)
select 'create unique index  ['+constraint_indice+'] on '+schem+'.'+tabela +coluna cmd,2 seq
--into migracao.create_object
from migracao.uq_tmp
where constraint_indice not like 'pk%'

/********************************************* PK E UQ FIM *********************************************/

/********************************************* INDICES INICIO *********************************************/


-- Inserindo quais Indices utilizam colunas com o Collate a ser alterado
--insert into migracao.ind_tmp(tabela,constraint_indice)
select distinct s.name schem,ob.name tabela,ix.name Constraint_indice, REPLICATE(' ',600) coluna
into migracao.ind_tmp
from sys.tables ob 
	inner join sys.indexes ix
		on ob.object_id = ix.object_id
	inner join sys.index_columns ic
		on	ob.object_id = ic.object_id
		and	ix.index_id = ic.index_id
	inner join sys.columns c
		on	ob.object_id = c.object_id
		and ic.column_id = c.column_id
	inner join sys.schemas s
		on ob.schema_id = s.schema_id
where c.collation_name = @collate
and s.name <> 'migracao'
and not exists(select 1 from migracao.pk_tmp pk
						where ix.name = pk.Constraint_indice)
and not exists(select 1 from migracao.uq_tmp pk
						where ix.name = pk.Constraint_indice)


-- Verificando quais colunas pertencem ao indice
declare cur_ind cursor for		
select ind.schem,ob.name tabela,ix.name Constraint_indice, c.name coluna
from sys.tables ob 
	inner join sys.indexes ix
		on ob.object_id = ix.object_id
	inner join sys.index_columns ic
		on	ob.object_id = ic.object_id
		and	ix.index_id = ic.index_id
	inner join sys.columns c
		on	ob.object_id = c.object_id
		and ic.column_id = c.column_id
	inner join migracao.ind_tmp ind
		on ob.name = ind.tabela
		and ix.name = ind.Constraint_indice
		where ic.is_included_column=0
			

open cur_ind

fetch cur_ind into @schem,@tab_atu, @ind_atu, @col

while @@FETCH_STATUS = 0

begin 

	if @tab_atu = @tab_ant and @ind_atu = @ind_ant 
	begin
		
		set @idx = @idx+','+@col
	
	end
	else
	begin
	
		set @idx = @col
	
	end
	
	select @tab_ant = @tab_atu,@ind_ant = @ind_atu
	


		update migracao.ind_tmp
		set coluna = '('+@idx+')'
		where tabela = @tab_atu
		and constraint_indice = @ind_atu

	fetch next from cur_ind into @schem,@tab_atu, @ind_atu, @col
	
	

end
	
close  cur_ind
deallocate cur_ind

-- inserindo o indice para dropar
insert into drop_object(cmd,seq)
select 'drop index '+schem+'.'+tabela+'.['+constraint_indice+']',3 
from migracao.ind_tmp



-- inserindo o indice para recriar
insert into migracao.create_object(cmd,seq)
select 'create index ['+constraint_indice+'] on '+schem+'.'+tabela+coluna,1
from migracao.ind_tmp

/********************************************* INDICES FIM *********************************************/

/************************ TABELAS E COLUNAS QUE TERÃO O COLLATE ALTERADO INICIO ************************/

--insert into migracao.create_object(cmd)
select 'alter table '+s.name+'.['+fil.name+'] alter column ['+col.name+'] ['+typ.name+']'
+	case	
	when typ.user_type_id < '256' and typ.user_type_id not in(99,35)
				then '('+convert(varchar,case	when convert(varchar,col.max_length) = '-1'	
													then 'max' 
												when typ.user_type_id in(231,239)
													then convert(varchar,col.max_length/2)
																							
												else convert(varchar,col.max_length) 
										  end )+')' 
				else '' 
	 end +' Collate '
+@collate_novo+
+	case 
	when col.is_nullable = 0 
		then ' Not Null' 
		else ' Null' 
	end as cmd
into collate_object
from sys.tables fil 
		inner join sys.columns col		
				on col.object_id = fil.object_id	
		inner join sys.types typ
				on col.user_type_id = typ.user_type_id	
		inner join sys.schemas s
				on fil.schema_id = s.schema_id			
where col.collation_name = @collate
and s.name <> 'migracao'
--and fil.schema_id = 1



/************************** TABELAS E COLUNAS QUE TERÃO O COLLATE ALTERADO FIM **************************/




begin try




/************************************** EXECUÇÃO DOS DROPS INICIO ***************************************/

--declare @cmd varchar(2000)

declare cur_drop cursor for select cmd from drop_object order by seq


open cur_drop

fetch cur_drop into @cmd

while @@FETCH_STATUS = 0

begin

--print @cmd
	exec (@cmd)
	fetch next from cur_drop into @cmd
	
end

close cur_drop
deallocate cur_drop




/**************************************** EXECUÇÃO DOS DROPS FIM ***************************************/

/********************************* EXECUÇÃO DA TROCA DO COLLATE INICIO *********************************/
--declare @cmd varchar(4000)

declare cur_collate insensitive cursor for select cmd+char(10) from collate_object 

open cur_collate

fetch cur_collate into @cmd

while @@FETCH_STATUS = 0

begin


	--print(@cmd)
	exec (@cmd)
	fetch next from cur_collate into @cmd
	
end

close cur_collate
deallocate cur_collate


/********************************* EXECUÇÃO DA TROCA DO COLLATE FIM *********************************/

/********************************* EXECUÇÃO DOS CREATES INICIO **************************************/

--declare @cmd varchar(max)

declare cur_create cursor for select cmd+char(10)+'go' from migracao.create_object  order by seq

open cur_create

fetch cur_create into @cmd

while @@FETCH_STATUS = 0

begin

--select @cmd

	exec (@cmd)

	fetch next from cur_create into @cmd
	
end

close cur_create
deallocate cur_create




/********************************* EXECUÇÃO DOS CREATES INICIO **************************************/

print 'TABELAS QUE CONTINUAM COM O COLLATE ANTIGO'
select s.name schem,fil.name,col.name,typ.name,col.collation_name
from sys.tables fil 
		inner join sys.columns col		
				on col.object_id = fil.object_id	
		inner join sys.types typ
				on col.user_type_id = typ.user_type_id	
		inner join sys.schemas s
			on fil.schema_id = s.schema_id 
						
where col.collation_name <> @collate_novo
and fil.schema_id = 1


if not exists (select 1 from sys.schemas where name = 'migracao')
begin
	 set @cmd = 'drop schema migracao'
	 exec (@cmd)
end

end try

begin catch

    select  @msgerror = isnull(@msgerror,'') + char(13) + 
                        'erro #' + convert(varchar, error_number()) + char(13) +
                        'linha #' + convert(varchar, error_line()) + char(13) +
                        'descricao: ' + error_message()
                        
select @msgerror                       
end catch

go


