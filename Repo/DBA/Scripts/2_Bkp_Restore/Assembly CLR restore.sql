
EXEC dbo.sp_changedbowner @loginame = N'sa', @map = false
GO
EXEC sp_configure 'clr enabled';  
EXEC sp_configure 'clr enabled' , '1';  
RECONFIGURE;
go
use master
alter database pallas_mask_dev set trustworthy on

use master
GRANT EXTERNAL ACCESS ASSEMBLY TO public