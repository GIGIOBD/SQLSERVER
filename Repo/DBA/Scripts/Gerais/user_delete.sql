/*
Encontrar um usuário que executou o comando DELETE

Passo 1
Para saber quem apagou as linhas que você precisa para consultar o log de transações. A consulta abaixo mencionada vai buscar todos os registros de log de transações
*/

SELECT
   
    [Transaction ID],Operation, Context, AllocUnitName
   
FROM fn_dblog(NULL, NULL) 
WHERE Operation = 'LOP_DELETE_ROWS'


/*
Você pode ver todas as transações devolvidas no select acima. Como estamos em busca de dados apagados na tabela, 
podemos ver isso na última linha. Podemos encontrar o nome da tabela na coluna "AllocUnitName". 
Agora capturar o ID da transação que irá usar para rastrear.

Passo 2
Nós encontramos o ID da transação no comando acima, que será utilizado no comando abaixo para obter no SID da transação do usuário que tenha excluído os dados.
*/

SELECT
 
    Operation,
 
    [Transaction ID],[Begin Time], [Transaction Name],[Transaction SID]
 
FROM fn_dblog(NULL, NULL)
WHERE [Transaction ID] = '0000:000e29bc'
AND [Operation] = 'LOP_BEGIN_XACT'

/*
Agora, nosso próximo passo é converter a transação SID que está em hexadecimal para texto para encontrar o nome real do usuário.
Podemos converter esta SID na informação exata que irá nos mostrar o usuário que realizou a operação de exclusão.
*/

USE MASTER
GO 
   
SELECT SUSER_SNAME(0x010500000000000515000000FCE3153143170A32A837D665FFC90000)
 
/*E aqui está o usuário que realizou a operação de exclusão. */
