
if exists(select 1 from sys.procedures where name='sp_helpindex2')
begin

	drop procedure   [dbo].[sp_helpindex2]

end
go
  
  
create  procedure [dbo].[sp_helpindex2]    
 @objname nvarchar(776)  -- the table to check for indexes    
as    
 
 set nocount on    
    
 declare @objid int,   -- the object id of the table    
   @indid smallint, -- the index id of an index    
   @groupid int,    -- the filegroup id of an index    
   @indname sysname,    
   @groupname sysname,    
   @status int,    
   @keys nvarchar(2126), --Length (16*max_identifierLength)+(15*2)+(16*3)    
   @inc_columns nvarchar(max),    
   @inc_Count  smallint,    
   @loop_inc_Count  smallint,    
   @dbname sysname,    
   @ignore_dup_key bit,    
   @is_unique  bit,    
   @is_hypothetical bit,    
   @is_primary_key bit,    
   @is_unique_key  bit,    
   @auto_created bit,    
   @no_recompute bit,  
   @schema_name varchar(120)  ,  
   @filegroup varchar(50)  
    
 -- Check to see that the object names are local to the current database.    
 select @dbname = parsename(@objname,3)    
 if @dbname is null    
  select @dbname = db_name()    
 else if @dbname <> db_name()    
  begin    
   raiserror(15250,-1,-1)    
   return (1)    
  end    
    
 -- Check to see the the table exists and initialize @objid.    
 select @objid = object_id(@objname)    
 if @objid is NULL    
 begin    
  raiserror(15009,-1,-1,@objname,@dbname)    
  return (1)    
 end    
    

 -- OPEN CURSOR OVER INDEXES (skip stats: bug shiloh_51196)    
 declare ms_crs_ind cursor local static for    
  select i.index_id, i.data_space_id, i.name,    
   i.ignore_dup_key, i.is_unique, i.is_hypothetical, i.is_primary_key, i.is_unique_constraint,    
   s.auto_created, s.no_recompute    
  from sys.indexes i join sys.stats s    
   on i.object_id = s.object_id and i.index_id = s.stats_id    
  where i.object_id = @objid    
  and (i.is_primary_key=0 or i.is_unique = 0)  
  
  --if @@ROWCOUNT = 0  
  --return (0)  
  
 open ms_crs_ind    
 fetch ms_crs_ind into @indid, @groupid, @indname, @ignore_dup_key, @is_unique, @is_hypothetical,    
   @is_primary_key, @is_unique_key, @auto_created, @no_recompute    
    
  
    
 -- create temp tables    
 CREATE TABLE #spindtab    
 (    
 schem_name varchar(120),  
 table_name varchar(120),  
  index_name   sysname collate database_default NOT NULL,    
  index_id   int,    
  ignore_dup_key  bit,    
  is_unique   bit,    
  is_hypothetical  bit,    
  is_primary_key  bit,    
  is_unique_key  bit,    
  auto_created  bit,    
  no_recompute  bit,    
  groupname   sysname collate database_default NULL,    
  index_keys   nvarchar(2126) collate database_default NOT NULL, -- see @keys above for length descr    
  inc_Count   smallint,    
  inc_columns   nvarchar(max)    
 )    
    
 CREATE TABLE #IncludedColumns    
 ( RowNumber smallint,    
  [Name] nvarchar(128)    
 )    
    
 -- Now check out each index, figure out its type and keys and    
 -- save the info in a temporary table that we'll print out at the end.    
 while @@fetch_status >= 0    
 begin    
  -- First we'll figure out what the keys are.    
  declare @i int, @thiskey nvarchar(131) -- 128+3    
    
  select @keys = index_col(@objname, @indid, 1), @i = 2    
  if (indexkey_property(@objid, @indid, 1, 'isdescending') = 1)    
   select @keys = @keys  + '(-)'    
    
  select @thiskey = index_col(@objname, @indid, @i)    
  if ((@thiskey is not null) and (indexkey_property(@objid, @indid, @i, 'isdescending') = 1))    
   select @thiskey = @thiskey + '(-)'    
    
  while (@thiskey is not null )    
  begin    
   select @keys = @keys + ', ' + @thiskey, @i = @i + 1    
   select @thiskey = index_col(@objname, @indid, @i)    
   if ((@thiskey is not null) and (indexkey_property(@objid, @indid, @i, 'isdescending') = 1))    
    select @thiskey = @thiskey + '(-)'    
  end    
    
  -- Second, we'll figure out what the included columns are.    
  SELECT @inc_Count = count(*)    
  FROM    
  sys.tables AS tbl    
   INNER JOIN sys.indexes AS i     
    ON (i.index_id > 0     
     and i.is_hypothetical = 0)     
     AND (i.object_id=tbl.object_id)    
   INNER JOIN sys.index_columns AS ic     
    ON (ic.column_id > 0     
     and (ic.key_ordinal > 0 or ic.partition_ordinal = 0 or ic.is_included_column != 0))     
     AND (ic.index_id=CAST(i.index_id AS int) AND ic.object_id=i.object_id)    
   INNER JOIN sys.columns AS clmns     
    ON clmns.object_id = ic.object_id     
    and clmns.column_id = ic.column_id    
  WHERE ic.is_included_column = 1    
   and (i.index_id = @indid)    
   and (tbl.object_id = @objid)     
    
  SET @inc_Columns = NULL    
    
  IF @inc_Count > 0    
  BEGIN    
   DELETE FROM #IncludedColumns    
   INSERT #IncludedColumns    
    SELECT ROW_NUMBER() OVER (ORDER BY clmns.column_id)     
    , clmns.name     
   FROM    
   sys.tables AS tbl    
   INNER JOIN sys.indexes AS si     
    ON (si.index_id > 0     
     and si.is_hypothetical = 0)     
     AND (si.object_id=tbl.object_id)    
   INNER JOIN sys.index_columns AS ic     
    ON (ic.column_id > 0     
     and (ic.key_ordinal > 0 or ic.partition_ordinal = 0 or ic.is_included_column != 0))     
     AND (ic.index_id=CAST(si.index_id AS int) AND ic.object_id=si.object_id)    
   INNER JOIN sys.columns AS clmns     
    ON clmns.object_id = ic.object_id     
    and clmns.column_id = ic.column_id    
   WHERE ic.is_included_column = 1 and    
    (si.index_id = @indid) and     
    (tbl.object_id= @objid)    
   ORDER BY 1    
     
   SELECT @inc_columns = [Name]     
    FROM #IncludedColumns     
    WHERE RowNumber = 1    
       
   SET @loop_inc_Count = 1    
    
   WHILE @loop_inc_Count < @inc_Count    
   BEGIN    
    SELECT @inc_columns = @inc_columns + ', ' + [Name]     
     FROM #IncludedColumns WHERE RowNumber = @loop_inc_Count + 1    
    SET @loop_inc_Count = @loop_inc_Count + 1    
   END    
  END    
     
  select @groupname = null    
  select @groupname = name from sys.data_spaces where data_space_id = @groupid    
    
  --select @schema_name=s.name  
  --from sys.schemas s join sys.tables t  
  --on s.schema_id = t.schema_id  
  --where t.object_id=object_id(@objname)  
  
  SELECT @schema_name=s.name  
FROM   
sys.tables t  
join sys.schemas s  
on t.[schema_id]=s.[schema_id]  
WHERE t.object_id = object_id (@objname)  
  
  -- INSERT ROW FOR INDEX    
  insert into #spindtab values (@schema_name,@objname,@indname, @indid, @ignore_dup_key, @is_unique, @is_hypothetical,    
   @is_primary_key, @is_unique_key, @auto_created, @no_recompute, @groupname, @keys, @inc_Count, @inc_columns)    
    
  -- Next index    
  fetch ms_crs_ind into @indid, @groupid, @indname, @ignore_dup_key, @is_unique, @is_hypothetical,    
   @is_primary_key, @is_unique_key, @auto_created, @no_recompute    
 end    
 deallocate ms_crs_ind    
    
 -- DISPLAY THE RESULTS    
  
 declare @count smallint  
  
 select @count=count(*) from #spindtab  
  
 if @count = 0   
 begin   
 return 0  
 end  
 else  
   
 begin  
   
 select    
 'schema_name'=schem_name,  
 'table_name'=substring(table_name,charindex('.',table_name,1)+1,120),  
  'index_name' = index_name,    
    
  'index_keys' = index_keys,    
  --'num_included_columns' = inc_Count,    
  'included_columns' = inc_columns  ,  
  'filegroup ' = groupname  
 from #spindtab    
 order by index_name    
    
 return (0) -- sp_helpindex2    
    
  end  
  go
set nocount on

if object_id('tempdb..#result_database','u') is not null
	drop table #result_database

create table #result_database(id_comando int identity(1,1),nm_comando varchar(max))

insert into #result_database(nm_comando)
select '

declare @versao_sql varchar(500)

select @versao_sql=substring(@@version,22,4)



set nocount on

if object_id(''tempdb..#schem_dev_database'',''u'') is not null
begin
	drop table #schem_dev_database
end

create table #schem_dev_database(schem_name varchar(120))

if object_id(''tempdb..#type_dev_database'',''u'') is not null
begin
	drop table #type_dev_database
end

create table #type_dev_database
(
	schem_name			varchar(120),
	type_name_custom	varchar(50),
	type_name_system	varchar(50),
	precision			varchar(4),
	scale				varchar(4)
)

if object_id(''tempdb..#campo_dev_database'',''u'') is not null
begin
	drop table #campo_dev_database
end

create table #campo_dev_database 
(
	schem_name varchar(120),
	table_name		sysname,
	column_name		sysname,
	column_id		smallint,
	is_identity		bit,
	is_nullable		varchar(3),
	data_type		varchar(50),
	max_length		numeric(15),
	precision		numeric(10),
	scale			numeric(10),
	nm_filegroup	varchar(20),
	nm_criptografia varchar(200),
	nm_mascara      varchar(200)
)

if object_id(''tempdb..#pk_dev_database'',''u'') is not null
begin
	drop table #pk_dev_database
end

create table #pk_dev_database
(
	schem_name varchar(120),
	table_name		sysname,
	pk_name			sysname,
	column_name		sysname,
	index_column_id	tinyint,
	nm_filegroup	varchar(20)
)

if object_id(''tempdb..#uq_dev_database'',''u'') is not null
begin
	drop table #uq_dev_database
end

create table #uq_dev_database
(
	schem_name varchar(120),
	table_name		sysname,
	uq_name			sysname,
	column_name		sysname,
	index_column_id	tinyint,
	nm_filegroup	varchar(20)
)

if object_id(''tempdb..#pk_cli_database'',''u'') is not null
begin
	drop table #pk_cli_database
end

create table #pk_cli_database
(
	schem_name varchar(120),
	table_name		sysname,
	pk_name			sysname,
	column_name		sysname,
	index_column_id	tinyint
)

if object_id(''tempdb..#df_dev_database'',''u'') is not null
begin
	drop table #df_dev_database
end

create table #df_dev_database
(
	schem_name varchar(120),
	table_name		sysname,
	df_name			sysname,
	column_name		sysname,
	nm_definition	sysname
)

if object_id(''tempdb..#indice_dev_database'',''u'') is not null
begin
	drop table #indice_dev_database
end

create table #indice_dev_database
(
	schem_name varchar(120),
	table_name		sysname,
	index_name		sysname,
	column_list		varchar(1200),
	include_list	varchar(1200),
	nm_filegroup	sysname
)

if object_id(''tempdb..#fk_dev_database'',''u'') is not null
begin
	drop table #fk_dev_database
end

create table #fk_dev_database 
(
	schem_name_filha	varchar(120),
	table_name_filha	sysname,
	fk_name				sysname,
	schem_name_pai		varchar(120),
	table_name_pai		sysname,
	column_name_filha	sysname,
	column_name_pai		sysname,
	column_id			smallint
)

if object_id(''tempdb..#trigger_dev_database'',''u'') is not null
begin
	drop table #trigger_dev_database
end

create table #trigger_dev_database
(
	schem_name varchar(120),
	table_name		sysname
)



if object_id(''tempdb..#campo_dev_database_type'',''u'') is not null
begin
	drop table #campo_dev_database_type
end

create table #campo_dev_database_type
(
	schem_name varchar(120),
	table_name		sysname,
	column_name		sysname,
	column_id		smallint,
	is_identity		bit,
	is_nullable		varchar(3),
	data_type		varchar(50),
	max_length		numeric(15),
	precision		numeric(10),
	scale			numeric(10)
)

if object_id(''tempdb..#campos_alterar_database'',''U'') is not null
begin
	drop table #campos_alterar_database
end

create table #campos_alterar_database(
	schem_name		varchar(120),
	table_name		sysname,
	column_name		sysname,
	is_nullable		varchar(3),
	data_type		varchar(50),
	max_length		numeric(15),
	precision		numeric(10),
	scale			numeric(10)
)




if object_id (''tempdb..#quantidade_registros_cliente'',''U'') is not null
begin
	drop table #quantidade_registros_cliente
end

create table #quantidade_registros_cliente(
nm_schema varchar(10),
nm_tabela varchar(150),
qt_registros int)

'
 if db_name() not like '%i4pro%'
 begin
	select 'XXXXXXX Banco de dados selecionado não é I4pro. XXXXXXX'
	return
	
 end
/*quantidade de registros */

if object_id ('tempdb..#quantidade_registros','U') is not null
begin
	drop table #quantidade_registros
end

create table #quantidade_registros(
nm_schema varchar(50),
nm_tabela varchar(150),
qt_registros int)

insert into #quantidade_registros (nm_schema,nm_tabela,qt_registros)
select distinct top 100 s.name,a.name,b.row_count  
FROM sys.tables a 
join sys.dm_db_partition_stats b
on a.object_id = b.object_id 
join sys.schemas s 
on a.schema_id = s.schema_id
where b.row_count > 0 
order by 3 desc

/* Gerando a quantidade de registros */
insert into #result_database(nm_comando)

select 'insert into #quantidade_registros_cliente values('
    +''''+lower(nm_schema)+''','
	+''''+lower(nm_tabela)+''','
    +''''+convert(varchar,qt_registros)+''')'
FROM #quantidade_registros


/* Gerando o script de inserção dos schemas do Dev */
insert into #result_database(nm_comando)

select 'insert into #schem_dev_database values('
+''''+name+''')'
from sys.schemas
where principal_id = 1
	and name <> 'dbo'
and schema_id < 16000


/* Gerando o script de inserção de data types customizados do DEV */
insert into #result_database(nm_comando)
select 'insert into #type_dev_database values('
    +''''+sch.name+''','
    +''''+lower(typ.name)+''','
    +''''+lower(typ2.name)+''','
    +''''+convert(varchar,typ.precision)+''','
    +''''+convert(varchar,typ.scale)+''')'
from sys.types typ
join sys.schemas sch
    on typ.schema_id = sch.schema_id
join sys.types typ2
    on typ.system_type_id = typ2.user_type_id
where typ.is_user_defined = 1

/* Gerando o script de inserção de TableTypes */
insert into #result_database(nm_comando)
select 'insert into #campo_dev_database_type values('
	+''''+sch.name+''','
	+''''+lower(tab.name)+''','
	+''''+lower(col.name) +''','
	+''''+convert(varchar,col.column_id) +''','
	+''''+convert(varchar,col.is_identity) +''','
	+''''+lower(col.is_nullable) +''','
	+''''+typ.name+''','
	+''''+convert(varchar(15),isnull(col.max_length,'0')) +''','
	+''''+convert(varchar(15),isnull(col.precision,'0')) +''','
	+''''+convert(varchar(15),isnull(col.scale,'0')) +''')'
from sys.table_types tab
join sys.columns col
	on tab.type_table_object_id = col.object_id
join sys.types typ
	on typ.user_type_id = col.user_type_id
join sys.schemas sch
	on tab.schema_id = sch.schema_id

/* Gerando o script de inserção de dados de colunas do DEV */
insert into #result_database(nm_comando)
select 'insert into #campo_dev_database values('
	+''''+sch.name+''','
	+''''+lower(tab.name)+''','
	+''''+lower(col.name) +''','
	+''''+convert(varchar,col.column_id) +''','
	+''''+convert(varchar,col.is_identity) +''','
	+''''+lower(col.is_nullable) +''','
	+''''+typ.name+''','
	+''''+convert(varchar(15),isnull(col.max_length,'0')) +''','
	+''''+convert(varchar(15),isnull(col.precision,'0')) +''','
	+''''+convert(varchar(15),isnull(col.scale,'0')) +''','
	+''''+convert(varchar(20),isnull(f.name,' ')) 
	+''','' '
	+''','' '+''')'
from sys.tables tab
join sys.columns col
	on tab.object_id = col.object_id
join sys.types typ
	on typ.user_type_id = col.user_type_id
join sys.schemas sch
	on tab.schema_id = sch.schema_id
join sys.indexes i
	on tab.object_id = i.object_id
JOIN sys.filegroups f
	on i.data_space_id = f.data_space_id
where i.index_id < 2
--and col.encryption_algorithm_name is null
--and col.is_masked = 0 






/* Gerando o script de inserção de dados de PK do DEV */
insert into #result_database(nm_comando)
select
'insert into #pk_dev_database values('
	+''''+sch.name+''','
	+''''+tab.name+''','
	+''''+lower(ind2.name)+''','
	+''''+col.name+''','
	+''''+convert(varchar,ind.key_ordinal)+''','
	+''''+f.name+''')'
from sys.key_constraints con
join sys.tables tab
	on con.parent_object_id = tab.object_id
join sys.index_columns ind
	on tab.object_id = ind.object_id
join sys.indexes ind2
	on tab.object_id = ind2.object_id
	and ind.index_id = ind2.index_id
	and con.name = ind2.name
join sys.columns col
	on ind.column_id = col.column_id
	and tab.object_id = col.object_id
join sys.schemas sch
	on tab.schema_id = sch.schema_id
JOIN sys.filegroups f
 ON ind2.data_space_id = f.data_space_id

where ind2.is_primary_key = 1
order by tab.name,ind.key_ordinal

/* Gerando o script de inserção de dados de UK do DEV */
insert into #result_database(nm_comando)
select
'insert into #uq_dev_database values('
	+''''+sch.name+''','
	+''''+tab.name+''','
	+''''+lower(ind2.name)+''','
	+''''+col.name+''','
	+''''+convert(varchar,ind.key_ordinal)+''','
	+''''+f.name+''')'
from sys.key_constraints con
join sys.tables tab
	on con.parent_object_id = tab.object_id
join sys.index_columns ind
	on tab.object_id = ind.object_id
join sys.indexes ind2
	on tab.object_id = ind2.object_id
	and ind.index_id = ind2.index_id
	and con.name = ind2.name
join sys.columns col
	on ind.column_id = col.column_id
	and tab.object_id = col.object_id
join sys.schemas sch
	on tab.schema_id = sch.schema_id
JOIN sys.filegroups f
 ON ind2.data_space_id = f.data_space_id

where ind2.is_unique_constraint = 1
order by tab.name,ind.key_ordinal

/* Gerando o script de inserção de dados de Indices do DEV */
if object_id ('tempdb..#indice_dev_database_interno','U') is not null
drop table #indice_dev_database_interno

create table #indice_dev_database_interno
(
	schem_name		varchar(120),
	table_name		varchar(128),
	index_name		varchar(128),
	column_list		varchar(1200),
	include_list	varchar(1200),
	nm_filegroup	varchar(20)
)

declare
	@schema varchar(20),
	@tab varchar(120),
	@sql varchar(max),
	@sch varchar(128),
	@tr varchar(128)

declare cur_tab cursor for
select distinct s.name,t.name
from sys.schemas s join sys.tables t
on s.schema_id = t.schema_id
join sys.indexes i 
on t.object_id = i.object_id
where i.type_desc <> 'heap'
and s.name not like 'i4proinfo%'




open cur_tab

fetch cur_tab into @schema,@tab

while @@fetch_status = 0
begin

set @sql='insert into #indice_dev_database_interno(schem_name,	table_name,
	index_name		,
	column_list		,
	include_list	,
	nm_filegroup
	)
exec sp_helpindex2 ['+@schema+'.'+@tab+']'

exec (@sql)

delete from #indice_dev_database_interno
where index_name like '%pk%'

delete from #indice_dev_database_interno
where index_name like '%uq%'

fetch next from cur_tab into @schema,@tab

end
close cur_tab
deallocate cur_tab

insert into #result_database(nm_comando)
select
'insert into #indice_dev_database values('
	+''''+schem_name+''','
	+''''+table_name+''','
	+''''+index_name+''','
	+''''+column_list+''','
	+''''+isnull(include_list,' ')+''','
	+''''+isnull(nm_filegroup,' ')+''')'
from #indice_dev_database_interno

/* Gerando o script de inserção de dados de FKs do DEV */
insert into #result_database(nm_comando)
select
'insert into #fk_dev_database values('
	+''''+sch.name+''','
	+''''+fil.name+''','
	+''''+lower(cons.name)+''','
	+''''+lower(sc_pai.name)+''','
	+''''+pai.name+''','
	+''''+col.name+''','
	+''''+cpai.name+''','
	+''''+convert(varchar,fkc.constraint_column_id)+''')'
from sys.tables fil
join sys.columns col
	on col.object_id = fil.object_id
join sys.foreign_key_columns fkc
	on fil.object_id = fkc.parent_object_id
	and col.column_id = fkc.parent_column_id
join sys.tables pai
	on pai.object_id = fkc.referenced_object_id
join sys.schemas sc_pai
	on sc_pai.schema_id = pai.schema_id
join sysobjects cons
	on fkc.constraint_object_id = cons.id
join sys.schemas sch
	on fil.schema_id = sch.schema_id
join sys.columns cpai
	on pai.object_id = cpai.object_id 
	and cpai.column_id = fkc.referenced_column_id
order by sch.name,fil.name,cons.name,fkc.constraint_column_id

/* Gerando o script de inserção de dados de Defaults do DEV */
insert into #result_database(nm_comando)
select 'insert into #df_dev_database values('
	+''''+sch.name+''','
	+''''+lower(tab.name)+''','
	+''''+lower(sdc.name)+''','
	+''''+lower(col.name)+''','
	+''''+replace(lower(sdc.definition), '''', '''''')+''')'
from sys.tables tab
join sys.default_constraints sdc
	on tab.object_id = sdc.parent_object_id
join sys.columns col
	on tab.object_id = col.object_id
	and col.column_id =sdc.parent_column_id
join sys.schemas sch
	on tab.schema_id = sch.schema_id

/* Checa se a tabelas existe, caso contrário será criada */
insert into #result_database(nm_comando)
select
'
/* Cria os data types e as tabelas */
declare
	@id_sequencia				int,
	@id_sequencia_max			int,
	@table_name_atu				varchar(128),
	@table_name_ant				varchar(128),
	@column_name				varchar(128),
	@column_name_composta		varchar(1000),
	@pk_name_atu				varchar(128),
	@pk_name_ant				varchar(128),
	@schem_name_atu				varchar(120),
	@schem_name_ant				varchar(120),
	@schem_name_filha_atu		varchar(120),
	@schem_name_filha_ant		varchar(120),
	@schem_name_pai_atu			varchar(120),
	@schem_name_pai_ant			varchar(120),
	@sql						varchar(2000),
	@sql2						varchar(max),
	@index_name_atu				varchar(128),
	@index_name_ant				varchar(128),
	@is_unique_atu				tinyint,
	@is_unique_ant				tinyint,
	@table_name_pai_atu			varchar(128),
	@table_name_pai_ant			varchar(128),
	@table_name_filha_atu		varchar(128),
	@table_name_filha_ant		varchar(128),
	@column_name_composta_filha	varchar(1000),
	@column_name_composta_pai	varchar(1000),
	@column_name_filha_atu		varchar(128),
	@column_name_filha_ant		varchar(128),
	@column_name_pai_atu		varchar(128),
	@column_name_pai_ant		varchar(128),
	@fk_name_atu				varchar(128),
	@fk_name_ant				varchar(128),
	@nm_filegroup				varchar(20),
	@path						varchar(1000),
	@db_name					varchar(255) = DB_NAME(),
	@logical_name				sysname,
	@filegroup_name				sysname

if object_id (''tempdb..#criacao_database'',''U'') is not null
	drop table #criacao_database

create table #criacao_database (id_sequencia int,nm_comando varchar(3000))

print ''Criando os schemas''
insert into #criacao_database(id_sequencia,nm_comando)
select ROW_NUMBER() OVER (ORDER BY dev.schem_name),''create schema [''+ dev.schem_name+'']''
from #schem_dev_database dev 
where not exists(select 1 from sys.schemas s where dev.schem_name = s.name)

select @id_sequencia = 1, @id_sequencia_max = max(id_sequencia)
from #criacao_database

while @id_sequencia <= @id_sequencia_max
begin
	select @sql = nm_comando
	from #criacao_database
	where id_sequencia = @id_sequencia

	exec (@sql)

	set @id_sequencia = @id_sequencia + 1
end

truncate table #criacao_database



print ''Criando os types''
insert into #criacao_database(id_sequencia,nm_comando)
select ROW_NUMBER() OVER (ORDER BY dev.type_name_custom),''create type ''+dev.schem_name+''.''+dev.type_name_custom+'' from ''
+dev.type_name_system+''(''+ dev.precision+'',''+dev.scale+'')''
from #type_dev_database dev
where not exists(select 1 from sys.types typ where dev.type_name_custom = typ.name)

select
	@id_sequencia = 1,
	@id_sequencia_max = max(id_sequencia)
from #criacao_database

while @id_sequencia <= @id_sequencia_max
begin
	select @sql = nm_comando
	from #criacao_database
	where id_sequencia = @id_sequencia

	exec (@sql)

	set @id_sequencia = @id_sequencia + 1
end

truncate table #criacao_database'

insert into #result_database(nm_comando)
select'

declare @schem_name sysname,@table_name sysname,@funcname varchar(300), @sql_tab varchar(200),
@sql_col varchar(max),@funcnameAnt varchar(300), @user_type_id int,@procnameAnt sysname, @procname sysname,
@nm_depend varchar(120), @type_depend varchar(10)

declare cur_tab cursor for select distinct schem_name,table_name from #campo_dev_database_type

open cur_tab

fetch cur_tab into @schem_name,@table_name

while @@fetch_status = 0
begin

		-- verificando se tem coluna a mais no dev
		if exists(
		select top 1 dev.table_name
		from #campo_dev_database_type dev left join sys.schemas sch
			on dev.schem_name = sch.name
		left join sys.table_types tab
			on dev.table_name = tab.name
			and sch.schema_id = tab.schema_id
		left join sys.columns col
			on tab.type_table_object_id = col.object_id
			and dev.column_name = col.name
		where dev.schem_name=@schem_name
		and dev.table_name=@table_name
		and col.name is null
		union
		-- verificando se tem algum campo com datatype ou caracteristica diferente
		select  top 1 dev.table_name
		from #campo_dev_database_type dev 
		 join sys.schemas sch
			on dev.schem_name = sch.name
		 join sys.table_types tab
			on dev.table_name = tab.name
			and sch.schema_id = tab.schema_id
		 join sys.columns col
			on tab.type_table_object_id = col.object_id
			and dev.column_name = col.name
		where dev.schem_name=@schem_name
		and dev.table_name=@table_name
		and exists(select * from sys.columns sc
					join sys.table_types tt
						on sc.object_id = tt.type_table_object_id
						and tt.name=dev.table_name
						and sc.name = dev.column_name
					join sys.types t
						on sc.system_type_id = t.system_type_id

					where tt.name=@table_name
					and( dev.is_nullable <> sc.is_nullable
					or dev.data_type <> t.name
					or dev.max_length <> sc.max_length
					or dev.precision <> sc.precision
					or dev.scale <> sc.scale)))

	begin
		
		/* Tirando as dependencias */

		declare cur_dep cursor for 
		select s.name,o.name , o.type
		from sys.sql_expression_dependencies d
		join sys.objects o
		on d.referencing_id = o.object_id
		join sys.schemas s
		on o.schema_id = s.schema_id
		where d.referenced_entity_name=@table_name

		open cur_dep

		fetch cur_dep into @schem_name,@nm_depend, @type_depend

		while @@fetch_status = 0
		begin

			set @sql=''drop ''+case when @type_depend in (''fn'',''tf'') then ''function ''
								  when  @type_depend =''p'' then ''procedure '' end
								  +@schem_name+''.''+@nm_depend

								  exec (@sql)
	
			fetch cur_dep into @schem_name,@nm_depend, @type_depend
		end
		close cur_dep
		deallocate cur_dep

			if exists(select 1 from sys.table_types t join sys.schemas s
			on t.schema_id = s.schema_id
			where t.name=@table_name
			and s.name=@schem_name)
			begin

				set @sql=''drop type ['' + @schem_name + ''].['' + @table_name +'']''

			exec (@sql)

			end
			
			set @sql_tab=''create type  ['' + @schem_name + ''].['' + @table_name +''] as table(''
			set @sql ='' ''
			declare cur_col cursor for
						select dev.column_name+'' ''+ dev.data_type+
						case
							when dev.data_type in (''decimal'',''numeric'') then ''(''+convert(varchar,dev.precision)+'',''+convert(varchar,dev.scale)+'')''
							when dev.data_type in (''char'',''varchar'') and dev.max_length <> -1 then ''(''+convert(varchar,dev.max_length)+'')''
							when dev.data_type in (''nchar'',''nvarchar'',''char'',''varchar'',''varbinary'') and dev.max_length = -1 then ''(max)''
							when dev.data_type in (''nchar'',''nvarchar'') and dev.max_length <> -1 then ''(''+convert(varchar,convert(int,dev.max_length/2))+'')''
							else ''''
						end +
							case when dev.is_identity =1 then '' identity(1,1)'' else '''' end+
							case when dev.is_nullable = 0 then '' not null '' else '' null ''end +'',''
	
						from #campo_dev_database_type dev left join sys.schemas sch
							on dev.schem_name = sch.name
						left join sys.table_types tab
							on dev.table_name = tab.name
							and sch.schema_id = tab.schema_id
							and tab.name is null
						where dev.schem_name=@schem_name
						and dev.table_name = @table_name
						order by dev.column_id

				open cur_col

				fetch cur_col into @sql_col

				while @@fetch_status=0
				begin
				
					set @sql = @sql + @sql_col

					fetch next from cur_col into @sql_col
					
				end
				close cur_col
				deallocate cur_col

				select @sql=@sql_tab+reverse(substring(reverse(@sql),2,100000))+'')''

				exec(@sql)
			end
	fetch next from cur_tab into @schem_name,@table_name


end
close cur_tab
deallocate cur_tab

print ''Criando as tabelas''
insert into #criacao_database(id_sequencia,nm_comando)
select ROW_NUMBER() OVER (ORDER BY dev.table_name),''create table [''+dev.schem_name+'']''+''.[''+dev.table_name+'']''+''(''+''[''+dev.column_name+''] ''+ dev.data_type+
case
	when dev.data_type in (''decimal'',''numeric'') then ''(''+convert(varchar,dev.precision)+'',''+convert(varchar,dev.scale)+'')''
	when dev.data_type in (''varbinary'',''char'',''varchar'') and dev.max_length <> -1 then ''(''+convert(varchar,dev.max_length)+'')''
	when dev.data_type in (''nchar'',''nvarchar'',''char'',''varchar'') and dev.max_length = -1 then ''(max)''
	when dev.data_type in (''nchar'',''nvarchar'') and dev.max_length <> -1 then ''(''+convert(varchar,convert(int,dev.max_length/2))+'')''
	else ''''
end +
	case when dev.is_identity =1 then '' identity(1,1)'' else '''' end+
	case when dev.is_nullable = 0 then '' not null '' else '' null ''end +'')
	on [''+dev.nm_filegroup+'']''
from #campo_dev_database dev left join sys.schemas sch
	on dev.schem_name = sch.name
left join sys.tables tab
	on dev.table_name = tab.name
	and sch.schema_id = tab.schema_id
where dev.column_id = (select min(column_id) from #campo_dev_database a where a.table_name = dev.table_name)
	and tab.name is null

select
	@id_sequencia = 1,
	@id_sequencia_max = max(id_sequencia)
from #criacao_database

while @id_sequencia <= @id_sequencia_max
begin
	select @sql = nm_comando
	from #criacao_database
	where id_sequencia = @id_sequencia

	exec (@sql)
	
	set @id_sequencia = @id_sequencia + 1
end

truncate table #criacao_database'
insert into #result_database(nm_comando)
select'

print ''Adiciona os campos''
if @versao_sql < ''2016''
begin
	
	insert into #criacao_database(id_sequencia,nm_comando)      
	select ROW_NUMBER() OVER (ORDER BY dev.table_name),''alter table [''+ dev.schem_name+'']''+''.[''+dev.table_name+'']''+'' add ''+''[''+dev.column_name+''] ''+ dev.data_type+
	case 
		when dev.data_type in (''decimal'',''numeric'') then ''(''+convert(varchar,dev.precision)+'',''+convert(varchar,dev.scale)+'')'' 
		when dev.data_type in (''varbinary'',''char'',''varchar'') and dev.max_length <> -1 then ''(''+convert(varchar,dev.max_length)+'')''
		when dev.data_type in (''nchar'',''nvarchar'',''char'',''varchar'',''varbinary'') and dev.max_length = -1 then ''(max)''
		when dev.data_type in (''nchar'',''nvarchar'') then ''(''+convert(varchar,convert(int,dev.max_length/2))+'')''
		else ''''
	end +
		case when dev.is_identity =1 then '' identity(1,1)'' else '''' end+
		case when dev.is_nullable = 0 then '' not null '' else '' null ''end
	from #campo_dev_database dev left join sys.schemas sch
		on dev.schem_name = sch.name
	left join sys.tables tab
		on dev.table_name = tab.name
		and sch.schema_id = tab.schema_id
	left join sys.columns col
		on tab.object_id = col.object_id
		and dev.column_name = col.name
	where dev.column_id >= 1
		and col.name is null
	order by dev.table_name,dev.column_id

		select @id_sequencia = 1, @id_sequencia_max = max(id_sequencia)
	from #criacao_database

	while @id_sequencia <= @id_sequencia_max
		begin
		select @sql = nm_comando
		from #criacao_database
		where id_sequencia = @id_sequencia

		exec (@sql)

		set @id_sequencia = @id_sequencia + 1
	end
	
	truncate table #criacao_database
end
else
begin



	insert into #criacao_database(id_sequencia,nm_comando)      
	select ROW_NUMBER() OVER (ORDER BY dev.table_name),''alter table [''+ dev.schem_name+'']''+''.[''+dev.table_name+'']''+'' add ''+''[''+dev.column_name+''] ''+ dev.data_type+
	case 
		when dev.data_type in (''decimal'',''numeric'') then ''(''+convert(varchar,dev.precision)+'',''+convert(varchar,dev.scale)+'')'' 
		when dev.data_type in (''varbinary'',''char'',''varchar'') and dev.max_length <> -1 then ''(''+convert(varchar,dev.max_length)+'')''
		when dev.data_type in (''nchar'',''nvarchar'',''char'',''varchar'',''varbinary'') and dev.max_length = -1 then ''(max)''
		when dev.data_type in (''nchar'',''nvarchar'') then ''(''+convert(varchar,convert(int,dev.max_length/2))+'')''
		else ''''
	end +
		case when dev.is_identity =1 then '' identity(1,1)'' else '''' end+
		dev.nm_criptografia+
		case when dev.is_nullable = 0 then '' not null '' else '' null ''end
	from #campo_dev_database dev left join sys.schemas sch
		on dev.schem_name = sch.name
	left join sys.tables tab
		on dev.table_name = tab.name
		and sch.schema_id = tab.schema_id
	left join sys.columns col
		on tab.object_id = col.object_id
		and dev.column_name = col.name
	where dev.column_id >= 1
		and col.name is null
	order by dev.table_name,dev.column_id

	select @id_sequencia = 1, @id_sequencia_max = max(id_sequencia)
	from #criacao_database

	while @id_sequencia <= @id_sequencia_max
		begin
		select @sql = nm_comando
		from #criacao_database
		where id_sequencia = @id_sequencia

		exec (@sql)

		set @id_sequencia = @id_sequencia + 1
	end
	
	truncate table #criacao_database
	  
	insert into #criacao_database(id_sequencia,nm_comando)  
	select ROW_NUMBER() OVER (ORDER BY dev.table_name),''alter table [''+ dev.schem_name+'']''+''.[''+dev.table_name+'']''+'' add ''+''[''+dev.column_name+''] ''+ dev.data_type+
	case 
		when dev.data_type in (''decimal'',''numeric'') then ''(''+convert(varchar,dev.precision)+'',''+convert(varchar,dev.scale)+'')'' 
		when dev.data_type in (''varbinary'',''char'',''varchar'') and dev.max_length <> -1 then ''(''+convert(varchar,dev.max_length)+'')''
		when dev.data_type in (''nchar'',''nvarchar'',''char'',''varchar'',''varbinary'') and dev.max_length = -1 then ''(max)''
		when dev.data_type in (''nchar'',''nvarchar'') then ''(''+convert(varchar,convert(int,dev.max_length/2))+'')''
		else ''''
	end +
		case when dev.is_identity =1 then '' identity(1,1)'' else '''' end+
		dev.nm_mascara+
		case when dev.is_nullable = 0 then '' not null '' else '' null ''end
	from #campo_dev_database dev left join sys.schemas sch
		on dev.schem_name = sch.name
	left join sys.tables tab
		on dev.table_name = tab.name
		and sch.schema_id = tab.schema_id
	left join sys.columns col
		on tab.object_id = col.object_id
		and dev.column_name = col.name
	where dev.column_id >= 1
		and col.name is null
		order by dev.table_name,dev.column_id

	select @id_sequencia = 1, @id_sequencia_max = max(id_sequencia)
	from #criacao_database

	while @id_sequencia <= @id_sequencia_max
		begin
		select @sql = nm_comando
		from #criacao_database
		where id_sequencia = @id_sequencia

		exec (@sql)

		set @id_sequencia = @id_sequencia + 1
	end

end

'


insert into #result_database(nm_comando)
select
'
print ''verifica se houve alteração no datatype ou tamanho''
insert into #campos_alterar_database
(schem_name,table_name,column_name,is_nullable,
data_type,max_length,precision,scale)

select s.name,t.name,c.name,dev.is_nullable,
dev.data_type,dev.max_length,dev.precision,dev.scale
from sys.schemas s join sys.tables t
on s.schema_id = t.schema_id
join sys.columns c
on t.object_id = c.object_id
join sys.types ty
on c.user_type_id = ty.user_type_id
join #campo_dev_database dev
on dev.schem_name = s.name
and dev.table_name = t.name
and dev.column_name = c.name
and  (dev.max_length > c.max_length or dev.precision > c.precision or dev.scale > c.scale)

insert into #campos_alterar_database
(schem_name,table_name,column_name,is_nullable,
data_type,max_length,precision,scale)

select s.name,t.name,c.name,dev.is_nullable,
dev.data_type,dev.max_length,dev.precision,dev.scale
from sys.schemas s join sys.tables t
on s.schema_id = t.schema_id
join sys.columns c
on t.object_id = c.object_id
join sys.types ty
on c.user_type_id = ty.user_type_id
join #campo_dev_database dev
on dev.schem_name = s.name
and dev.table_name = t.name
and dev.column_name = c.name
and (dev.is_nullable <> c.is_nullable 
	or dev.data_type <> ty.name 
	)


insert into #campos_alterar_database
(schem_name,table_name,column_name,is_nullable,
data_type,max_length,precision,scale)
select s.name,t.name,c.name,dev.is_nullable,
dev.data_type,dev.max_length,dev.precision,dev.scale
from sys.schemas s join sys.tables t
on s.schema_id = t.schema_id
join sys.columns c
on t.object_id = c.object_id
join sys.types ty
on c.user_type_id = ty.user_type_id
join #campo_dev_database dev
on dev.schem_name = s.name
and dev.table_name = t.name
and dev.column_name = c.name
and (dev.is_nullable <> c.is_nullable 
	or dev.data_type <> ty.name 
	or dev.max_length <> c.max_length 
	or dev.precision <> c.precision 
	or dev.scale <> c.scale)
and dev.data_type in (''char'',''varchar'',''varbinary'',''nchar'',''nvarchar'')
and dev.max_length = ''-1''

-- colunas já existentes, porém sem o masked
if @versao_sql >= ''2016''
begin
set @sql2=''
	insert into #campos_alterar_database
	select s.name,t.name,c.name,dev.is_nullable,
	dev.data_type,dev.max_length,dev.precision,dev.scale
	from sys.schemas s join sys.tables t
	on s.schema_id = t.schema_id
	join sys.columns c
	on t.object_id = c.object_id
	join sys.types ty
	on c.user_type_id = ty.user_type_id
	join #campo_dev_database dev
	on dev.schem_name = s.name
	and dev.table_name = t.name
	and dev.column_name = c.name
	and c.is_masked = 0
	where dev.nm_mascara <> '''' ''''''

	exec (@sql2)
end

	print ''dropando indices''
declare cur_ind cursor for
select ''drop index [''+ix.name+''] on ''+s.name+''.''+ca.table_name
from sys.tables t 
join sys.index_columns i 
on t.object_id = i.object_id
join sys.schemas s
on t.schema_id = s.schema_id
join sys.columns c 
on t.object_id = c.object_id
and i.column_id = c.column_id
join sys.indexes ix
on t.object_id = ix.object_id
and i.index_id = ix.index_id
join #campos_alterar_database ca
on t.name = ca.table_name
and c.name = ca.column_name
and s.name = ca.schem_name
where ix.is_primary_key=0
and ix.is_unique_constraint =0

open cur_ind

fetch cur_ind into @sql

while @@fetch_status = 0
begin

	exec (@sql)
	
	fetch next from cur_ind into @sql
end
close cur_ind
deallocate cur_ind

print ''dropando fks''


insert into #fk_dev_database(schem_name_filha,table_name_filha,fk_name,schem_name_pai,table_name_pai,column_name_filha,column_name_pai)
select sfil.name,fil.name,f.name,s.name,pai.name,c.name,coluna_pai.name
from #campos_alterar_database ca
join sys.schemas s 
on ca.schem_name = s.name
join sys.tables pai
on s.schema_id = pai.schema_id
and ca.table_name = pai.name
join sys.foreign_key_columns fk
on fk.referenced_object_id = pai.object_id
join sys.tables fil
on fk.parent_object_id = fil.object_id
join sys.schemas sfil
on fil.schema_id = sfil.schema_id
join sys.foreign_keys f
on fil.object_id = f.parent_object_id
and f.referenced_object_id = fk.referenced_object_id
join sys.columns as c 
 on fk.parent_object_id = c.object_id 
 and fk.parent_column_id = c.column_id
 and ca.column_name = c.name
join sys.columns as coluna_pai
 on fk.referenced_object_id = coluna_pai.object_id 
 and fk.referenced_column_id = coluna_pai.column_id
where not exists(select 1 from #fk_dev_database #fk
				where s.name = #fk.schem_name_filha
				and fil.name = #fk.table_name_filha
				and f.name = #fk.fk_name)


declare cur_fk cursor for
select ''alter table [''+s.name+''].[''+ca.table_name+''] drop constraint[''+fk.name+'']''
from sys.foreign_keys fk
	join sys.tables fil
	on fk.parent_object_id = fil.object_id
	join sys.schemas s
	on fil.schema_id = s.schema_id
	join sys.tables pai
	on fk.referenced_object_id = pai.object_id
	join sys.foreign_key_columns fkc
	on fkc.constraint_object_id = fk.object_id
	join sys.columns pai2
	on pai.object_id = pai2.object_id
	and fkc.referenced_column_id = pai2.column_id
	join sys.columns fil2
	on fil.object_id = fil2.object_id
	and fkc.parent_column_id = fil2.column_id
	join #campos_alterar_database ca
on fil.name = ca.table_name
and fil2.name = ca.column_name
and  s.name = ca.schem_name
union
select ''alter table [''+sfil.name+''].[''+fil.name+''] drop constraint[''+f.name+'']''
from #campos_alterar_database ca
join sys.schemas s 
on ca.schem_name = s.name
join sys.tables pai
on s.schema_id = pai.schema_id
and ca.table_name = pai.name
join sys.foreign_key_columns fk
on fk.referenced_object_id = pai.object_id
join sys.tables fil
on fk.parent_object_id = fil.object_id
join sys.schemas sfil
on fil.schema_id = sfil.schema_id
join sys.foreign_keys f
on fil.object_id = f.parent_object_id
and f.referenced_object_id = fk.referenced_object_id
join sys.columns as c 
 on fk.parent_object_id = c.object_id 
 and fk.parent_column_id = c.column_id
 and ca.column_name = c.name
join sys.columns as coluna_pai
 on fk.referenced_object_id = coluna_pai.object_id 
 and fk.referenced_column_id = coluna_pai.column_id

open cur_fk

fetch cur_fk into @sql

while @@fetch_status = 0
begin

	exec (@sql)
	
	fetch next from cur_fk into @sql
end
close cur_fk
deallocate cur_fk

print ''dropando Pks''

declare cur_pk cursor for
select distinct ''alter table [''+s.name+''].[''+ca.table_name+''] drop constraint[''+c.name+'']''
from sys.key_constraints c
join sys.tables t
on c.parent_object_id = t.object_id
join sys.index_columns ic
on t.object_id = ic.object_id
join sys.indexes i
on t.object_id = i.object_id
and ic.index_id = i.index_id
and c.name = i.name
join sys.columns b
on ic.column_id = b.column_id
and t.object_id = b.object_id
join sys.schemas s
on s.schema_id = t.schema_id
join #campos_alterar_database ca
on s.name = ca.schem_name
and t.name = ca.table_name
and b.name = ca.column_name
where i.is_primary_key = 1

open cur_pk

fetch cur_pk into @sql

while @@fetch_status = 0
begin


	exec (@sql)
	
	fetch next from cur_pk into @sql
end
close cur_pk
deallocate cur_pk'

insert into #result_database(nm_comando)
select
'

print ''dropando UQs''

declare cur_pk cursor for
select distinct ''alter table [''+s.name+''].[''+ca.table_name+''] drop constraint[''+c.name+'']''
from sys.key_constraints c
join sys.tables t
on c.parent_object_id = t.object_id
join sys.index_columns ic
on t.object_id = ic.object_id
join sys.indexes i
on t.object_id = i.object_id
and ic.index_id = i.index_id
and c.name = i.name
join sys.columns b
on ic.column_id = b.column_id
and t.object_id = b.object_id
join sys.schemas s
on s.schema_id = t.schema_id
join #campos_alterar_database ca
on s.name = ca.schem_name
and t.name = ca.table_name
and b.name = ca.column_name
where i.is_unique_constraint = 1

open cur_pk

fetch cur_pk into @sql

while @@fetch_status = 0
begin

	exec (@sql)
	
	fetch next from cur_pk into @sql
end
close cur_pk
deallocate cur_pk

'
insert into #result_database(nm_comando)
select'


print ''Alterando colunas''



declare cur_alt cursor for
select ''alter table ''+ca.schem_name+''.[''+ca.table_name+''] alter column [''+ca.column_name+''] [''+ca.data_type+'']''
+''(''+	case	
	when  convert(varchar,ca.max_length) = ''-1''	
													then ''max'' 
												--when typ.user_type_id in(231,239)
												--	then convert(varchar,ca.max_length/2)
																							
												else convert(varchar,ca.max_length) 
										  end  +'')''+
	 case 
	when ca.is_nullable = 0 
		then '' Not Null'' 
		else '' Null'' end
from sys.tables fil 
		 join sys.columns col		
				on col.object_id = fil.object_id	
		 join sys.types typ
				on col.user_type_id = typ.user_type_id	
		 join sys.schemas s
				on fil.schema_id = s.schema_id	
		join #campos_alterar_database ca
			on s.name = ca.schem_name
			and fil.name = ca.table_name
			and col.name = ca.column_name
where ca.data_type  in( ''char'',
''nchar'',
''varchar'',
''nvarchar'',
''varbinary'')
union all
select ''alter table ''+schem_name+''.[''+table_name+''] alter column [''+column_name+''] [''+data_type+'']''
+
	 case 
	when ca.is_nullable = 0 
		then '' Not Null'' 
		else '' Null'' end
from sys.tables fil 
		 join sys.columns col		
				on col.object_id = fil.object_id	
		 join sys.types typ
				on col.user_type_id = typ.user_type_id	
		 join sys.schemas s
				on fil.schema_id = s.schema_id	
		join #campos_alterar_database ca
			on s.name = ca.schem_name
			and fil.name = ca.table_name
			and col.name = ca.column_name
where ca.data_type  in( ''corpty_desconto'',
''corpty_percentual'',
''corpty_quantidade'',
''corpty_valor'',''bit'',''tinyint'',''smallint'',''int'',''bigint'',''datetime'',''smalldatetime'',''float'',''image'',''text'')
union all
select ''alter table ''+schem_name+''.[''+table_name+''] alter column [''+column_name+''] [''+data_type+'']''
+''(''+ convert(varchar,ca.precision)+'',''+convert(varchar,ca.scale)+'')''
+
	 case 
	when ca.is_nullable = 0 
		then '' Not Null'' 
		else '' Null'' end
from sys.tables fil 
		 join sys.columns col		
				on col.object_id = fil.object_id	
		 join sys.types typ
				on col.user_type_id = typ.user_type_id	
		 join sys.schemas s
				on fil.schema_id = s.schema_id	
		join #campos_alterar_database ca
			on s.name = ca.schem_name
			and fil.name = ca.table_name
			and col.name = ca.column_name
where ca.data_type  in(''numeric'',''decimal'')


open cur_alt 

fetch cur_alt into @sql

while @@fetch_status = 0
begin
	exec (@sql)

	fetch next from cur_alt into @sql
end
close cur_alt
deallocate cur_alt

if @versao_sql >= ''2016''
begin
	print ''Criando as mascaras nas colunas''
	set @sql2=''
	declare @sql varchar(1000)
	declare cur_mask cursor for
	select ''''alter table ''''+s.name+''''.''''+t.name+'''' alter column ''''+c.name+'''' 
	add ''''+dev.nm_mascara
	from sys.schemas s join sys.tables t
	on s.schema_id = t.schema_id
	join sys.columns c
	on t.object_id = c.object_id
	join sys.types ty
	on c.user_type_id = ty.user_type_id
	join #campo_dev_database dev
	on dev.schem_name = s.name
	and dev.table_name = t.name
	and dev.column_name = c.name
	and c.is_masked = 0
	where dev.nm_mascara <> '''' ''''



	open cur_mask

	fetch cur_mask into @sql

	while @@fetch_status = 0
	begin
		exec (@sql)

		fetch next from cur_mask into @sql
	end
	close cur_mask
	deallocate cur_mask

	''
exec (@sql2)
end'








insert into #result_database(nm_comando)
select
'
print ''Criando as Pks compostas''
if object_id (''tempdb..#pk_composta_database'',''u'') is not null
	drop table #pk_composta_database

create table #pk_composta_database
(
	id_sequencia	int identity(1,1),
	schem_name		varchar(20),
	table_name		varchar(128),
	pk_name			varchar(128),
	column_name		varchar(128),
	index_column_id	int,
	nm_filegroup varchar(20)
)

insert into #pk_composta_database(schem_name,table_name,pk_name,column_name,index_column_id,nm_filegroup)
select dev.schem_name,dev.table_name,dev.pk_name,dev.column_name,dev.index_column_id,dev.nm_filegroup
from #pk_dev_database dev
join (
	select dev.schem_name,dev.table_name,count(*) contador
	from #pk_dev_database dev
	where not exists(
		select 1 from sys.tables tab
		join sys.indexes ind
			on tab.object_id = ind.object_id
		join sys.schemas sc
			on tab.schema_id = sc.schema_id
		where ind.is_primary_key = 1
		and tab.name = dev.table_name
		and sc.name = dev.schem_name
	)
	group by dev.schem_name,dev.table_name
	having count(*) > 1
) dup
	on dev.table_name = dup.table_name
order by dev.schem_name,dev.table_name,dev.pk_name,dev.index_column_id

select @schem_name_ant ='''',@table_name_ant ='''',@column_name_composta='''',
@pk_name_ant ='''',@nm_filegroup=''''
select @id_sequencia = 1, @id_sequencia_max = max(id_sequencia)+1
from #pk_composta_database

while @id_sequencia < @id_sequencia_max
begin
	select @schem_name_atu = schem_name,@table_name_atu = table_name , 
	@column_name = column_name,@pk_name_atu = pk_name,
	@nm_filegroup = nm_filegroup
	from #pk_composta_database
	where id_sequencia = @id_sequencia

	if @table_name_atu = @table_name_ant and @schem_name_atu = @schem_name_ant and @pk_name_atu = @pk_name_ant
	begin
		set @column_name_composta = @column_name_composta+@column_name+'',''
	end
	else
	begin
		if @table_name_ant <> ''''
		begin
			set @sql = ''alter table ''+@schem_name_ant+''.''+@table_name_ant+'' add constraint [''+@pk_name_ant+''] primary key''+reverse(substring(reverse(@column_name_composta),2,1000))+'') 
			on [''+@nm_filegroup+'']''
			
			exec (@sql)
		end
		
		set @column_name_composta = ''(''+@column_name+'',''
	end
	
	select @schem_name_ant = @schem_name_atu,@table_name_ant = @table_name_atu, @pk_name_ant = @pk_name_atu

	set @id_sequencia = @id_sequencia + 1
end

if @schem_name_ant <> '''' and @table_name_ant <> ''''
begin
	set @sql = ''alter table ''+@schem_name_ant+''.''+@table_name_ant+'' add constraint [''+@pk_name_ant+''] primary key''+reverse(substring(reverse(@column_name_composta),2,1000))+'')
	on [''+@nm_filegroup+'']''

	exec (@sql)
end'

insert into #result_database(nm_comando)
select
'
print ''Gerando as PKs simples''

truncate table #criacao_database
insert into #criacao_database(id_sequencia,nm_comando)
select ROW_NUMBER() OVER (ORDER BY dev.table_name),''alter table ''+dev.schem_name+''.''+dev.table_name+'' add constraint ''+
''[''+dev.pk_name+'']''+'' primary key (''+dev.column_name+'') ON [''+dev.nm_filegroup+'']''

from #pk_dev_database dev
where not exists(select 1 from sys.tables tab
join sys.indexes ind 
	on tab.object_id = ind.object_id
join sys.schemas sc
	on tab.schema_id = sc.schema_id
where ind.is_primary_key = 1
	and tab.name = dev.table_name
	and sc.name = dev.schem_name)

select @id_sequencia = 1, @id_sequencia_max = max(id_sequencia)
from #criacao_database

while @id_sequencia <= @id_sequencia_max
begin
	select @sql = nm_comando
	from #criacao_database
	where id_sequencia = @id_sequencia

	exec (@sql)

	set @id_sequencia = @id_sequencia + 1
end
'


insert into #result_database(nm_comando)
select
'
print ''Criando as uqs compostas''
if object_id (''tempdb..#uq_composta_database'',''u'') is not null
	drop table #uq_composta_database

create table #uq_composta_database
(
	id_sequencia	int identity(1,1),
	schem_name		varchar(20),
	table_name		varchar(128),
	uq_name			varchar(128),
	column_name		varchar(128),
	index_column_id	int,
	nm_filegroup varchar(20)
)

insert into #uq_composta_database(schem_name,table_name,uq_name,column_name,index_column_id,nm_filegroup)
select dev.schem_name,dev.table_name,dev.uq_name,dev.column_name,dev.index_column_id,dev.nm_filegroup
from #uq_dev_database dev
join (
	select dev.schem_name,dev.table_name,count(*) contador
	from #uq_dev_database dev
	where not exists(
		select 1 from sys.tables tab
		join sys.indexes ind
			on tab.object_id = ind.object_id
		join sys.schemas sc
			on tab.schema_id = sc.schema_id
		where ind.is_unique_constraint = 1
		and tab.name = dev.table_name
		and sc.name = dev.schem_name
	)
	group by dev.schem_name,dev.table_name
	having count(*) > 1
) dup
	on dev.table_name = dup.table_name
order by dev.schem_name,dev.table_name,dev.uq_name,dev.index_column_id

select @schem_name_ant ='''',@table_name_ant ='''',@column_name_composta='''',
@pk_name_ant ='''',@nm_filegroup=''''
select @id_sequencia = 1, @id_sequencia_max = max(id_sequencia)+1
from #uq_composta_database

while @id_sequencia < @id_sequencia_max
begin
	select @schem_name_atu = schem_name,@table_name_atu = table_name , 
	@column_name = column_name,@pk_name_atu = uq_name,
	@nm_filegroup = nm_filegroup
	from #uq_composta_database
	where id_sequencia = @id_sequencia

	if @table_name_atu = @table_name_ant and @schem_name_atu = @schem_name_ant and @pk_name_atu = @pk_name_ant
	begin
		set @column_name_composta = @column_name_composta+@column_name+'',''
	end
	else
	begin
		if @table_name_ant <> ''''
		begin
			set @sql = ''alter table ''+@schem_name_ant+''.''+@table_name_ant+'' add constraint [''+@pk_name_ant+''] unique''+reverse(substring(reverse(@column_name_composta),2,1000))+'') 
			on [''+@nm_filegroup+'']''
			
			exec (@sql)
		end
		
		set @column_name_composta = ''(''+@column_name+'',''
	end
	
	select @schem_name_ant = @schem_name_atu,@table_name_ant = @table_name_atu, @pk_name_ant = @pk_name_atu

	set @id_sequencia = @id_sequencia + 1
end

if @schem_name_ant <> '''' and @table_name_ant <> ''''
begin
	set @sql = ''alter table ''+@schem_name_ant+''.''+@table_name_ant+'' add constraint [''+@pk_name_ant+''] unique''+reverse(substring(reverse(@column_name_composta),2,1000))+'')
	on [''+@nm_filegroup+'']''

	exec (@sql)
end'

insert into #result_database(nm_comando)
select
'
print ''Gerando as uqs simples''

truncate table #criacao_database
insert into #criacao_database(id_sequencia,nm_comando)
select ROW_NUMBER() OVER (ORDER BY dev.table_name),''alter table ''+dev.schem_name+''.''+dev.table_name+'' add constraint ''+
''[''+dev.uq_name+'']''+'' unique (''+dev.column_name+'') ON [''+dev.nm_filegroup+'']''

from #uq_dev_database dev
where not exists(select 1 from sys.tables tab
join sys.indexes ind 
	on tab.object_id = ind.object_id
join sys.schemas sc
	on tab.schema_id = sc.schema_id
where ind.is_unique_constraint = 1
	and tab.name = dev.table_name
	and sc.name = dev.schem_name)

select @id_sequencia = 1, @id_sequencia_max = max(id_sequencia)
from #criacao_database

while @id_sequencia <= @id_sequencia_max
begin
	select @sql = nm_comando
	from #criacao_database
	where id_sequencia = @id_sequencia

	exec (@sql)

	set @id_sequencia = @id_sequencia + 1
end
'

insert into #result_database(nm_comando)
select
'
print ''Gerando as pks compostas''

insert into #pk_cli_database
select sch.name,
	tab.name,
	lower(ind2.name),
	col.name,
	convert(varchar,ind.key_ordinal)
from sys.key_constraints con
join sys.tables tab
	on con.parent_object_id = tab.object_id
join sys.index_columns ind
	on tab.object_id = ind.object_id
join sys.indexes ind2
	on tab.object_id = ind2.object_id
	and ind.index_id = ind2.index_id
	and con.name = ind2.name
join sys.columns col
	on ind.column_id = col.column_id
	and tab.object_id = col.object_id
join sys.schemas sch
	on tab.schema_id = sch.schema_id
where ind2.is_primary_key = 1
order by tab.name,ind.key_ordinal

if object_id (''tempdb..#fk_composta_database'',''U'') is not null
	drop table #fk_composta_database

create table #fk_composta_database
(
	id_sequencia		int identity(1,1),
	schem_name_filha	varchar(20),
	table_name_filha	varchar(128),
	fk_name				varchar(128),
	schem_name_pai		varchar(20),
	table_name_pai		varchar(128),
	column_name_filha	varchar(128),
	column_name_pai		varchar(128),
	column_id			smallint
)

insert into #fk_composta_database(schem_name_filha,table_name_filha,fk_name,schem_name_pai,table_name_pai,column_name_filha,column_name_pai,column_id)
select dev.schem_name_filha,dev.table_name_filha,dev.fk_name,dev.schem_name_pai,dev.table_name_pai,dev.column_name_filha,dev.column_name_pai,pk.index_column_id
from #fk_dev_database dev
join (
	select dev.schem_name_filha,dev.table_name_filha,dev.fk_name,count(*) contador
	from #fk_dev_database dev
	where not exists(
		select 1 from sys.tables tab
		join sys.foreign_key_columns fkc
			on tab.object_id = fkc.parent_object_id
		join sys.tables pai
			on fkc.referenced_object_id = pai.object_id
		join sys.schemas sc
			on tab.schema_id = sc.schema_id
		where tab.name = dev.table_name_filha
			and pai.name = dev.table_name_pai
			and sc.name = dev.schem_name_filha
	)
	group by dev.schem_name_filha,dev.table_name_filha,dev.fk_name
	having count(*) > 1
) dup
	on dev.table_name_filha = dup.table_name_filha
	and dev.schem_name_filha = dup.schem_name_filha
	and dev.fk_name=dup.fk_name
join #pk_cli_database pk
	on dev.table_name_pai = pk.table_name
	and dev.column_name_pai = pk.column_name
order by dev.schem_name_filha,dev.table_name_filha,dev.table_name_pai,dev.fk_name,pk.index_column_id

select
	@schem_name_filha_ant ='''',@schem_name_pai_ant ='''',@table_name_filha_ant ='''',@column_name_composta_filha='''',
	@column_name_composta_pai='''',@fk_name_ant ='''',
	@column_name_filha_ant = '''',@column_name_pai_ant ='''',
	@table_name_pai_ant =''''

select @id_sequencia = 1, @id_sequencia_max = max(id_sequencia)+1
from #fk_composta_database

while @id_sequencia < @id_sequencia_max
begin
	select
		@schem_name_filha_atu = schem_name_filha,
		@table_name_filha_atu = table_name_filha ,
		@column_name_filha_atu = column_name_filha,
		@fk_name_atu = fk_name,
		@column_name_pai_atu = column_name_pai,
		@schem_name_pai_atu = schem_name_pai,
		@table_name_pai_atu = table_name_pai
	from #fk_composta_database
	where id_sequencia = @id_sequencia

	if @table_name_filha_atu = @table_name_filha_ant and @schem_name_filha_atu = @schem_name_filha_ant and @fk_name_atu = @fk_name_ant
	begin
		set @column_name_composta_filha = @column_name_composta_filha+@column_name_filha_atu+'',''
		set @column_name_composta_pai = @column_name_composta_pai+@column_name_pai_atu+'',''
	end
	else
	begin
		if @table_name_filha_ant <> ''''
		begin
			set @sql = ''alter table ''+@schem_name_filha_ant+''.''+@table_name_filha_ant+'' with nocheck add constraint [''+@fk_name_ant+''] foreign key (''+
			reverse(substring(reverse(@column_name_composta_filha),2,1000))+'') references ''+@schem_name_pai_ant+''.''+@table_name_pai_ant+''(''+reverse(substring(reverse(@column_name_composta_pai),2,1000))+'')''

			exec (@sql)
		end

		set @column_name_composta_filha = @column_name_filha_atu+'',''
		set @column_name_composta_pai = @column_name_pai_atu+'',''
	end

	select
		@schem_name_filha_ant = @schem_name_filha_atu,@table_name_filha_ant = @table_name_filha_atu,
		@table_name_pai_ant = @table_name_pai_atu,@fk_name_ant = @fk_name_atu,
		@schem_name_pai_ant = @schem_name_pai_atu

	set @id_sequencia = @id_sequencia + 1
end

if @schem_name_ant <> '''' and @table_name_filha_ant <> ''''
begin
	set @sql = ''alter table ''+@schem_name_filha_ant+''.''+@table_name_filha_ant+'' with nocheck add constraint [''+@fk_name_ant+''] foreign key (''+
	reverse(substring(reverse(@column_name_composta_filha),2,1000))+'') references ''+@schem_name_pai_ant+''.''+@table_name_pai_ant+''(''+reverse(substring(reverse(@column_name_composta_pai),2,1000))+'')''

	exec (@sql)
end

delete from #fk_dev_database
from #fk_dev_database dev
join #fk_composta_database comp
	on dev.fk_name = comp.fk_name
'

insert into #result_database(nm_comando)
select
'
print ''Gerando as Fks simples''

truncate table #criacao_database
insert into #criacao_database(id_sequencia,nm_comando)
select ROW_NUMBER() OVER (ORDER BY dev.table_name_filha),''alter table ''+dev.schem_name_filha+''.''+dev.table_name_filha+'' with nocheck add constraint [''
+dev.fk_name+''] foreign key (''+dev.column_name_filha+'') references ''+dev.schem_name_pai+''.''+dev.table_name_pai+''(''+
column_name_pai+'')''
from #fk_dev_database dev
where not exists(select 1 from sys.tables tab
	join sys.foreign_keys fk
		on tab.object_id = fk.parent_object_id
	join sys.tables pai
		on fk.referenced_object_id = pai.object_id
	join sys.schemas sc
		on tab.schema_id = sc.schema_id
	where tab.name = dev.table_name_filha
		and pai.name = dev.table_name_pai
		and sc.name = dev.schem_name_filha
)

select @id_sequencia = 1, @id_sequencia_max = max(id_sequencia)
from #criacao_database

while @id_sequencia <= @id_sequencia_max
begin
	select @sql = nm_comando
	from #criacao_database
	where id_sequencia = @id_sequencia

	exec (@sql)

	set @id_sequencia = @id_sequencia + 1
end
'

insert into #result_database(nm_comando)
select
'
print ''Gerando os Defaults''

truncate table #criacao_database

insert into #criacao_database(id_sequencia,nm_comando)
select ROW_NUMBER() OVER (ORDER BY dev.table_name),''alter table ''+dev.schem_name+''.''+dev.table_name+'' add constraint [''
+dev.df_name+''] default (''+dev.nm_definition+'') for ''+dev.column_name
from #df_dev_database dev
where not exists(select 1 from sys.tables tab
	join sys.default_constraints sdc
		on tab.object_id = sdc.parent_object_id
	join sys.columns col
		on tab.object_id = col.object_id
		and col.column_id =sdc.parent_column_id
	join sys.schemas sch
		on tab.schema_id = sch.schema_id
	where tab.name = dev.table_name
		and sch.name = dev.schem_name
		and col.name = dev.column_name
)

select @id_sequencia = 1, @id_sequencia_max = max(id_sequencia)
from #criacao_database

while @id_sequencia <= @id_sequencia_max
begin
	select @sql = nm_comando
	from #criacao_database
	where id_sequencia = @id_sequencia
	
	exec (@sql)

	set @id_sequencia = @id_sequencia + 1
end
'


insert into #result_database(nm_comando)
select
'
print ''Gerando os indices''

insert into #criacao_database(id_sequencia,nm_comando)
select ROW_NUMBER() OVER (ORDER BY dev.table_name),''create index [''+dev.index_name+''] on ''+dev.schem_name+''.''+dev.table_name+
'' (''+dev.column_list+'')''+ case when dev.include_list <> '' ''
then +''include(''+dev.include_list+'')'' else '''' end+ '' on [''+dev.nm_filegroup+'']''
from #indice_dev_database dev
where not exists(
		select 1 from sys.schemas s
		join sys.tables t
		on s.schema_id = t.schema_id
		join sys.indexes i
		on t.object_id = i.object_id
		where s.name = dev.schem_name
		and t.name = dev.table_name
		and i.name = dev.index_name)


select @id_sequencia = 1, @id_sequencia_max = max(id_sequencia)
from #criacao_database

while @id_sequencia <= @id_sequencia_max
begin
	select @sql = nm_comando
	from #criacao_database
	where id_sequencia = @id_sequencia
	
	exec (@sql)

	set @id_sequencia = @id_sequencia + 1
end'


select nm_comando 
from #result_database
order by id_comando


