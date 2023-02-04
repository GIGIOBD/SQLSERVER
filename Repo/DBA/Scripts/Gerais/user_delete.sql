/*
Encontrar um usu�rio que executou o comando DELETE

Passo 1
Para saber quem apagou as linhas que voc� precisa para consultar o log de transa��es. A consulta abaixo mencionada vai buscar todos os registros de log de transa��es
*/

SELECT
   
    [Transaction ID],Operation, Context, AllocUnitName
   
FROM fn_dblog(NULL, NULL) 
WHERE Operation = 'LOP_DELETE_ROWS'


/*
Voc� pode ver todas as transa��es devolvidas no select acima. Como estamos em busca de dados apagados na tabela, 
podemos ver isso na �ltima linha. Podemos encontrar o nome da tabela na coluna "AllocUnitName". 
Agora capturar o ID da transa��o que ir� usar para rastrear.

Passo 2
N�s encontramos o ID da transa��o no comando acima, que ser� utilizado no comando abaixo para obter no SID da transa��o do usu�rio que tenha exclu�do os dados.
*/

SELECT
 
    Operation,
 
    [Transaction ID],[Begin Time], [Transaction Name],[Transaction SID]
 
FROM fn_dblog(NULL, NULL)
WHERE [Transaction ID] = '0000:000e29bc'
AND [Operation] = 'LOP_BEGIN_XACT'

/*
Agora, nosso pr�ximo passo � converter a transa��o SID que est� em hexadecimal para texto para encontrar o nome real do usu�rio.
Podemos converter esta SID na informa��o exata que ir� nos mostrar o usu�rio que realizou a opera��o de exclus�o.
*/

USE MASTER
GO 
   
SELECT SUSER_SNAME(0x010500000000000515000000FCE3153143170A32A837D665FFC90000)
 
/*E aqui est� o usu�rio que realizou a opera��o de exclus�o. */
