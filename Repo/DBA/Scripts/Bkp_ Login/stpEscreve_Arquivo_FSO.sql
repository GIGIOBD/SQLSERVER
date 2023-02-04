use master 
go
--drop PROCEDURE [dbo].[stpEscreve_Arquivo_FSO] 
create PROCEDURE [dbo].[stpEscreve_Arquivo_FSO] (
    @String VARCHAR(MAX),
    @Ds_Arquivo VARCHAR(1501)
)
AS
BEGIN

    DECLARE
        @objFileSystem INT,
        @objTextStream INT,
        @objErrorObject INT,
        @strErrorMessage VARCHAR(1000),
        @Command VARCHAR(1000),
        @hr INT

    SET NOCOUNT ON

    SELECT
        @strErrorMessage = 'opening the File System Object'
    
    EXECUTE @hr = sp_OACreate
        'Scripting.FileSystemObject',
        @objFileSystem OUT

    
    IF @HR = 0
        SELECT
            @objErrorObject = @objFileSystem,
            @strErrorMessage = 'Creating file "' + @Ds_Arquivo + '"'
    
    
    IF @HR = 0
        EXECUTE @hr = sp_OAMethod
            @objFileSystem,
            'CreateTextFile',
            @objTextStream OUT,
            @Ds_Arquivo,
            2,
            True

    IF @HR = 0
        SELECT
            @objErrorObject = @objTextStream,
            @strErrorMessage = 'writing to the file "' + @Ds_Arquivo + '"'
    
    
    IF @HR = 0
        EXECUTE @hr = sp_OAMethod
            @objTextStream,
            'Write',
            NULL,
            @String

    
    IF @HR = 0
        SELECT
            @objErrorObject = @objTextStream,
            @strErrorMessage = 'closing the file "' + @Ds_Arquivo + '"'
    
    
    IF @HR = 0
        EXECUTE @hr = sp_OAMethod
            @objTextStream,
            'Close'

    
    IF @hr <> 0
    BEGIN
    
        DECLARE
            @Source VARCHAR(255),
            @Description VARCHAR(255),
            @Helpfile VARCHAR(255),
            @HelpID INT
    
        EXECUTE sp_OAGetErrorInfo
            @objErrorObject,
            @source OUTPUT,
            @Description OUTPUT,
            @Helpfile OUTPUT,
            @HelpID OUTPUT
        
        
        SELECT
            @strErrorMessage = 'Error whilst ' + COALESCE(@strErrorMessage, 'doing something') + ', ' + COALESCE(@Description, '')
        
        
        RAISERROR (@strErrorMessage,16,1)
        
    END
    
    
    EXECUTE sp_OADestroy
        @objTextStream
    
    EXECUTE sp_OADestroy
        @objTextStream
        
END