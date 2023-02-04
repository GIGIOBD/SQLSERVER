/* Login windows authentication */
USE [master]
GO

CREATE LOGIN [I4PROINFO\g-sql-edn] FROM WINDOWS WITH DEFAULT_DATABASE=[master], DEFAULT_LANGUAGE=[us_english]
GO

/* login sql authentication */
use master 
GO

CREATE LOGIN [mascara] WITH PASSWORD=N'testemascara', DEFAULT_DATABASE=[master], DEFAULT_LANGUAGE=[us_english], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
GO

ALTER LOGIN [i4pro_next] DISABLE
GO

/* user bd */
use i4pro_treinamento_dev

create user [mascara]

--exec sp_addrolemember db_owner, [I4PROINFO\pacoteservices] -- somente login site.
exec sp_addrolemember db_datareader, [mascara]
exec sp_addrolemember db_datawriter, [mascara]
exec sp_addrolemember db_ddladmin,   [mascara]


/* Criar usuario para aplicação de pacotes */
create user [I4PROINFO\poolsdkupdate]  from login [I4PROINFO\poolsdkupdate];
create user [I4PROINFO\pacoteservices]  from login [I4PROINFO\pacoteservices];
create user [I4PROINFO\PortalDevServices]  from login [I4PROINFO\PortalDevServices];

/*  Ambientes internos */
use i4pro_next_dev
exec sp_addrolemember db_datareader, [I4PROINFO\poolsdkupdate]
exec sp_addrolemember db_datawriter, [I4PROINFO\poolsdkupdate]
exec sp_addrolemember db_ddladmin,   [I4PROINFO\poolsdkupdate]

exec sp_addrolemember db_datareader, [I4PROINFO\pacoteservices]
exec sp_addrolemember db_datawriter, [I4PROINFO\pacoteservices]
exec sp_addrolemember db_ddladmin,   [I4PROINFO\pacoteservices]

exec sp_addrolemember db_datareader,[I4PROINFO\PortalDevServices] 

/* Drop role */
--exec sp_droprolemember db_datareader, [I4PROINFO\PortalDevServices]
exec sp_droprolemember db_datareader, [I4PROINFO\poolsdkupdate]
exec sp_droprolemember db_datawriter, [I4PROINFO\poolsdkupdate]
exec sp_droprolemember db_ddladmin, [I4PROINFO\poolsdkupdate]