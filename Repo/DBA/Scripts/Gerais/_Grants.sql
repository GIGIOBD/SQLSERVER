/* Grant sp_helptext */
grant view definition to [user]

/* Verificar permiss�es user */
EXEC dbo.sp_helprotect @username = 'user' 

/* Grant em procedure especifica */
GRANT EXECUTE ON [sp_consulta]
    TO [user]
