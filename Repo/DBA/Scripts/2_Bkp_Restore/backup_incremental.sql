set nocount on 
declare 
	@contador int = 1,
	@valor int = 3

while @contador <= 1000
begin
	insert into dado_incremental values (@valor)
	
	set @contador = @contador + 1
end

select * from dado_incremental 

   
   BACKUP DATABASE bkp_strategy TO bkp_strategy WITH FORMAT, compression,  NAME = N'bkp_strategy - Full Database Backup',  STATS = 10


   declare @nm_arquivo varchar(1000) = 'F:\temp\bkp\bkp_strategy_'+convert(varchar(10),getdate(),112)+'_'+ convert(varchar(3),datepart(hour,CURRENT_TIMESTAMP))+'.bak'     
    BACKUP DATABASE bkp_strategy TO disk = @nm_arquivo WITH DIFFERENTIAL, compression,  NAME = N'bkp_strategy - Differential Database Backup',  STATS = 10

use master;
RESTORE DATABASE bkp_strategy FROM DISK = 'F:\temp\bkp\bkp_strategy.bak' WITH NORECOVERY
RESTORE DATABASE bkp_strategy FROM DISK = 'F:\temp\bkp\bkp_strategy_20220330_11.bak' WITH RECOVERY

USE bkp_strategy
SELECT * FROM DADO_INCREMENTAL 

--create table dado_incremental
--(
--	id int
--)
