/*
Permiss�es
Nesta sess�o, vou ajud�-los a identificar as permiss�es dos usu�rios em objetos, database roles, server roles e 
permiss�es a n�vel de inst�ncia no ambiente.
*/
SELECT
    C.[name] AS Ds_Usuario,
    B.[name] AS Ds_Database_Role
FROM 
    sys.database_role_members A
    JOIN sys.database_principals B ON A.role_principal_id = B.principal_id
    JOIN sys.database_principals C ON A.member_principal_id = C.principal_id