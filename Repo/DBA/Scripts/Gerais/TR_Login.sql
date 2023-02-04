USE [master]
GO

/****** Object:  DdlTrigger [TR_Login]    Script Date: 04/12/2019 09:38:16 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO







create TRIGGER [TR_Login]
      ON ALL SERVER WITH EXECUTE AS 'sa'
      FOR LOGON
      AS
      BEGIN
            DECLARE @User VARCHAR(200),
					@host varchar(100),
					@spid	smallint,
					@sql varchar(50),
					@app varchar(50)
            
            SET @User = ORIGINAL_LOGIN()
            set @host = HOST_NAME()
            set @spid = @@spid
            set @app = APP_NAME()
        
			DECLARE @Tab TABLE (login_name VARCHAR(100))  
 
			INSERT INTO @Tab 
			select name 
			from master.dbo.syslogins
			where isntuser = 0 
			and password is not null
			and name not like '##%'
			and name not in( 'sa','i4promod')
			

			if exists(select 1 
						from @tab where login_name = @User 
						and (@host like 'i4pro%' 
						and @host 
						not in('i4pronote433',
'i4pro05',
'i4pronote244',
'I4PRONOTE443',
'I4PRONOTE473',
'I4PRONOTE355',
'i4pronote528',
'I4PRONOTE259',
'I4PRONOTE217',
'I4PRONOTE224 ',
'i4pronote480',
'i4pronote220',
'i4pronote230',
'i4pronote160'
)) 
						and @app <>'i4propublicador')
			begin
			
				
			set @sql ='kill '+CONVERT(varchar,@spid)
			
			exec(@sql)
			
			end      
            
            
      END;
 




GO

ENABLE TRIGGER [TR_Login] ON ALL SERVER
GO


