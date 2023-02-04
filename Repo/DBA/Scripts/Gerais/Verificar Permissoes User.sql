-- Verificando as permissões do usuário "Usuario_Teste"
EXEC senac_prev_cli.dbo.sp_helprotect 
    @username = 'I4PROINFO\g-sql-prev'   