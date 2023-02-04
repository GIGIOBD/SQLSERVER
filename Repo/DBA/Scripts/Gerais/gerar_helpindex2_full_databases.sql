
declare
	@db varchar(200),
	@sql varchar(max)
declare cur_db cursor for select name from sys.databases where database_id > 4 and state_desc = 'ONLINE'
	
	open cur_db
	
	fetch cur_db into @db
	
	while @@fetch_status = 0
	begin
	
		set @sql='use '+@db+' 
		GO 
IF (OBJECT_ID(''[dbo].[sp_helpindex2]'') IS NOT NULL)
begin
	drop procedure [dbo].[sp_helpindex2] 
end
GO
create  procedure [dbo].[sp_helpindex2]    
 @objname nvarchar(776),  -- the table to check for indexes    
 @checklist bit = null
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
  
 open ms_crs_ind    
 fetch ms_crs_ind into @indid, @groupid, @indname, @ignore_dup_key, @is_unique, @is_hypothetical,    
   @is_primary_key, @is_unique_key, @auto_created, @no_recompute    
       
 -- create temp tables    
 CREATE TABLE #spindtab    
 (    
 schem_name varchar(120)	,  
 table_name varchar(120)	,  
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
  index_keys   nvarchar(2126) collate database_default NULL, -- see @keys above for length descr    
  inc_Count   smallint,    
  inc_columns   nvarchar(max)    
 )    
    
 CREATE TABLE #IncludedColumns    
 ( RowNumber smallint,    
  [Name] nvarchar(128)    
 )    
    
 -- Now check out each index, figure out its type and keys and    
 -- save the info in a temporary table that well print out at the end.    
 while @@fetch_status >= 0    
 begin    
  -- First well figure out what the keys are.    
  declare @i int, @thiskey nvarchar(131) -- 128+3    
    
  select @keys = index_col(@objname, @indid, 1), @i = 2    
  if (indexkey_property(@objid, @indid, 1, ''isdescending'') = 1)    
   select @keys = @keys  + ''(-)''    
    
  select @thiskey = index_col(@objname, @indid, @i)    
  if ((@thiskey is not null) and (indexkey_property(@objid, @indid, @i, ''isdescending'') = 1))    
   select @thiskey = @thiskey + ''(-)''    
    
  while (@thiskey is not null )    
  begin    
   select @keys = @keys + '', '' + @thiskey, @i = @i + 1    
   select @thiskey = index_col(@objname, @indid, @i)    
   if ((@thiskey is not null) and (indexkey_property(@objid, @indid, @i, ''isdescending'') = 1))    
    select @thiskey = @thiskey + ''(-)''    
  end    
    
  -- Second, well figure out what the included columns are.    
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
    SELECT @inc_columns = @inc_columns + '', '' + [Name]     
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
	if @checklist = 1
	begin
		select    
		''schema_name''=null,  
		''table_name''= @objname,  
		''index_name'' = null,    		   
		''index_keys'' = null,    
		''included_columns'' = null  ,  
		''filegroup '' = null  
	end
	
 return 0  
 end  
 else  
 begin  
	select    
		''schema_name''=schem_name,  
		''table_name''=substring(table_name,charindex(''.'',table_name,1)+1,120),  
		 ''index_name'' = index_name,    
		   
		 ''index_keys'' = index_keys,    
		 ''included_columns'' = inc_columns  ,  
		 ''filegroup '' = groupname  
	from #spindtab    
	order by index_name    
    
 return (0) end 
 GO'
	
		print (@sql)
	
		fetch next from cur_db into @db
	
	end
	close cur_db
	deallocate cur_db;
