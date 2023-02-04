--verificação utilização tempdb
select 
        sum(unallocated_extent_page_count) as FreePages,
        sum(unallocated_extent_page_count) * 8 / 1024. as FreeSpaceMB,
        sum(version_store_reserved_page_count) as VersionStorePages ,
        sum(version_store_reserved_page_count)* 8 / 1024. as VersionStoreMB,
        sum(internal_object_reserved_page_count) as InternalObjectPages,
        sum(internal_object_reserved_page_count)* 8 / 1024. as InternalObjectsMB,
        sum(user_object_reserved_page_count) as UserObjectPages,
        sum(user_object_reserved_page_count)* 8 / 1024. as UserObjectsMB 
from sys.dm_db_file_space_usage;