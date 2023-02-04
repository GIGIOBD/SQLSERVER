
declare @cmd nvarchar(4000)
declare @bd varchar(100)
declare @file nvarchar(100)
declare @size nvarchar(100)
declare pap_log cursor read_only forward_only for 

SELECT 
	--dbid,
    db_name(sf.dbid) as [Database_Name],
    sf.name as [File_Name],
    (sf.size/128.0 - CAST(FILEPROPERTY(file_name(fileid), 'SpaceUsed') AS int)/128.0) AS 'Available_Space_MB'

FROM    master..sysaltfiles sf
WHERE   groupid = 0
and db_name(sf.dbid) not in('model')
--and dbid = 168
ORDER BY    Available_Space_MB  DESC



open pap_log
fetch next from pap_log into @bd,@file,@size
while @@fetch_status = 0
begin 
/*2005*/
--set @cmd='backup log '+@bd+' with no_log ;use '+@bd+';dbcc shrinkfile(['+@file+'],0);'
/*2000*/
--set @cmd='backup log '+@bd+' with no_log ;use '+@bd+';dbcc shrinkfile('+@file+',0);'
/*2008*/
set @cmd='use '+@bd+';dbcc shrinkfile('+@file+',0);'
	exec sp_executeSQL @cmd
	--print (@cmd)
declare @filepath varchar(100)
print ''
print @bd
print rtrim(ltrim(@file+' '+@size))
select @filepath=filename from master..sysaltfiles where name=@file
print @filepath
print ''
fetch next from pap_log into @bd,@file,@size
end
close pap_log
deallocate pap_log



--use W127150_migracao_Sistema;

--dbcc shrinkfile(i4proerp_log,0);
 
--W127150_migracao_Sistema
--i4proerp_log 258608.359375
--F:\Apoio\I4ProClone\ClonadoDB\W128829_teste\Sistema\W128829_teste_fator_erp_head.ldf