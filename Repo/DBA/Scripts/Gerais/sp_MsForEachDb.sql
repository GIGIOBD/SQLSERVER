

select * from sys.schemas where name = 'atz'

--select * from sys.tables where schema_id = 26

set nocount on 
EXEC sp_MSForEachDB 'USE ?; 
if (db_id() > 4)
begin    
    if not exists (select 1 from sys.schemas where name = ''atz'')
    begin
        print(''
			use '' + db_name(db_id()) + ''
			go

			create schema [atz]
			go
        '')
    end
    else
    begin
        select ''Schema existente no database: ''+ db_name(db_id())
    end
end
'