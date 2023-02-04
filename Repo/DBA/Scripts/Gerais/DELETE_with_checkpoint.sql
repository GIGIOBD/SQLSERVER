DECLARE @Deleted_Rows INT;
SET @Deleted_Rows = 1;


WHILE (@Deleted_Rows > 0)
  BEGIN

   BEGIN TRANSACTION
        
		DELETE TOP (10000)  
		from dba.t_auditoria_sql 
		where event_time between '20211101' and '20211231'

		SET @Deleted_Rows = @@ROWCOUNT;

   COMMIT TRANSACTION
   CHECKPOINT -- for simple recovery model
END