IF OBJECT_ID('ChangeCollation_SP','P') IS NOT NULL
    DROP PROC ChangeCollation_SP
GO
 
CREATE PROCEDURE ChangeCollation_SP
 @ToCollation                sysname            = 'SQL_Latin1_General_CP1_CI_AI'
,@TableName                    sysname            = ''
,@Columnname                sysname            = ''
,@SchemaName                sysname            = 'dbo'
,@FromCollation                sysname            = 'SQL_Latin1_General_CP1_CI_AS'
,@GenerateScriptsOnly        BIT                = 1
 
 
AS
 
/*
option (maxrecursion 0)
--exec ChangeCollation_SP
Parameters
@ToCollation                - To which collation columns needs to be moved
@TableName                    - TableName for which the collation needs to be changed.
                              Default value is '' and all the tables will be considered for changing the collation.
@Columnname                    - Columnname for which the collation needs to be changed.
                              Default value is '' and all the columns will be considered for changing the collation.
@SchemaName                    - SchemaName for which the collation needs to be changed.
                              Default value is '' and all the columns will be considered for changing the collation.
@FromCollation                - The columns with which collation needs to be changed to the To collation.
                              Default value is '' and all the columns with all collation will be considered for changing the collation.
@GenerateScriptsOnly        - Generates the scripts only for changing the collation.
                              Default value is 1 and generates only script. When changed to 0 the collation change will be applied
                               
*/
 
    SET NOCOUNT ON
 
 
   
  DECLARE @DBname        sysname
  DECLARE @SchemaID        INT
  DECLARE @TableID        INT
  DECLARE @IndexID        INT
  DECLARE @isPrimaryKey BIT
  DECLARE @IndexType    INT
   
  DECLARE @CreateSQL    VARCHAR(MAX)
  DECLARE @IndexColsSQL VARCHAR(MAX)
  DECLARE @WithSQL VARCHAR(MAX)
  DECLARE @IncludeSQL VARCHAR(MAX)
  DECLARE @WhereSQL      VARCHAR(MAX)
   
  DECLARE @sql        VARCHAR(MAX)
  DECLARE @DropSQL        VARCHAR(MAX)
  DECLARE @ExistsSQL        VARCHAR(MAX)
  DECLARE @Indexname    sysname
  DECLARE @TblSchemaName sysname
 
 
    IF OBJECT_ID('#ChangeCollationTables','U') IS NOT NULL
    BEGIN
        DROP TABLE #ChangeCollationTables
    END
     
    CREATE TABLE #ChangeCollationTables
    (
         SchemaID        INT
        ,SchemaName        sysname
        ,TableID        INT
        ,TableName        sysname
        ,Processed         BIT
        ,RunRank        INT   NULL
    )
 
    IF OBJECT_ID('#ChangeCollationColumns','U') IS NOT NULL
    BEGIN
        DROP TABLE #ChangeCollationColumns
    END
     
    CREATE TABLE #ChangeCollationColumns
    (
         SchemaID        INT
        ,SchemaName        sysname
        ,TableID        INT
        ,TableName        sysname
        ,ColumnID        INT
        ,Col            sysname
        ,AlterScript    VARCHAR(MAX)    NULL
    )
 
    IF OBJECT_ID('#ChangeCollationObjectsBackupTbl','U') IS NOT NULL
    BEGIN
        DROP TABLE #ChangeCollationObjectsBackupTbl
    END
     
    CREATE TABLE #ChangeCollationObjectsBackupTbl
    (
         BackupID        INT IDENTITY(1,1)
        ,SchemaID        INT
        ,TableID        INT
        ,ObjectName        sysname
        ,ObjectType        VARCHAR(50)
        ,CreateScript    VARCHAR(MAX)    NULL
        ,DropScript        VARCHAR(MAX)    NULL
        ,ExistsScript    VARCHAR(MAX)    NULL
        ,Processed        BIT                NULL
    )
 
 
---------------------------------------------------------------------------------------------------------------------------
-- Get List of columns needs the collation to be changed
---------------------------------------------------------------------------------------------------------------------------
 
    INSERT INTO #ChangeCollationColumns
 
    SELECT SCH.schema_id
          ,SCH.name
          ,ST.object_id
          ,ST.name
          ,SC.column_id
          ,SC.name
          ,'ALTER TABLE ' + QUOTEname(SCH.name) + '.' + QUOTEname(ST.name) 
            + ' ALTER COLUMN ' + QUOTEname(SC.name) + '  '
            + STY.name +
            + CASE
              WHEN STY.name IN ('char','varchar','nchar','nvarchar') AND SC.max_length = -1 THEN '(max)'
              WHEN STY.name IN ('char','varchar') AND SC.max_length <> -1 THEN  '(' + CONVERT(VARCHAR(5),SC.max_length) + ')'
              WHEN STY.name IN ('nchar','nvarchar') AND SC.max_length <> -1 THEN '(' + CONVERT(VARCHAR(5),SC.max_length/2) + ')'
              ELSE ''
              END
            + ' COLLATE ' + @ToCollation 
            + CASE SC.is_nullable
              WHEN 0 THEN ' NOT NULL'
              ELSE ' NULL'
              END
      FROM sys.tables  ST
      JOIN sys.schemas SCH
        ON SCH.schema_id = ST.schema_id
      JOIN sys.columns SC
        ON SC.object_id = ST.object_id
      JOIN sys.types STY
        ON STY.system_type_id = SC.system_type_id
       AND STY.user_type_id      = SC.user_type_id
     WHERE SCH.name = CASE
                      WHEN @SchemaName = '' THEN SCH.name
                      ELSE @SchemaName
                      END
       AND ST.name  = CASE
                      WHEN @TableName = '' THEN ST.name
                      ELSE @TableName
                      END
       AND SC.name    = CASE
                      WHEN @Columnname = '' THEN SC.name
                      ELSE @Columnname
                      END
       AND SC.collation_name = CASE
                               WHEN @FromCollation = '' THEN SC.collation_name
                               ELSE @FromCollation
                               END
       AND STY.name in ('char', 'varchar', 'text', 'nchar', 'nvarchar', 'ntext')
       AND SC.is_computed = 0
       OPTION (MAXRECURSION 1000)
        
-----------------------------------------------------------------------------------------------------------------------------
-- Get the list of tables need to be processed 
-----------------------------------------------------------------------------------------------------------------------------
 
    INSERT INTO #ChangeCollationTables
    SELECT  DISTINCT SchemaID
            ,SchemaName
            ,TableID
            ,TableName
            ,convert(bit,0) as Processed
            ,0 as RunRank
    FROM #ChangeCollationColumns;
 
 
----------------------------------------------------------------------------------------------------------------------------
-- Order by foreignkey
-----------------------------------------------------------------------------------------------------------------------------
 
WITH fkey (ReferencingObjectid,ReferencingSchemaid,ReferencingTableName,PrimarykeyObjectid,PrimarykeySchemaid,PrimarykeyTableName,level)AS
    (
        SELECT         DISTINCT        
                               convert(int,null)
                              ,convert(INT,null)
                              ,convert(sysname,null)
                              ,ST.object_id
                              ,ST.schema_id
                              ,ST.name
                              ,0 as level
                               
        FROM sys.tables ST
   LEFT JOIN sys.foreign_keys SF
          ON SF.parent_object_id = ST.object_id
       WHERE SF.object_id IS NULL
       UNION ALL
      SELECT                   STP.object_id
                             ,STP.schema_id
                             ,STP.name
                             ,STC.object_id
                             ,STC.schema_id
                             ,STC.name
                              ,f.level+1 as level
                               
        FROM sys.foreign_keys SFK
        JOIN fkey f
          ON SFK.referenced_object_id = ISNULL(f.ReferencingObjectid,  f.PrimarykeyObjectid)
        JOIN sys.tables STP
          ON STP.object_id  = SFK.parent_object_id
        JOIN sys.tables STC
          ON STC.object_id  = SFK.referenced_object_id
           
      )

 
       
      UPDATE CT
         SET RunRank = F.Lvl 
        FROM #ChangeCollationTables CT
        JOIN
        (
          SELECT TableId = ISNULL(ReferencingObjectid,PrimarykeyObjectid)
                 , Lvl = MAX(level)
            FROM fkey
            GROUP BY ISNULL(ReferencingObjectid,PrimarykeyObjectid)
        ) F
        ON F.TableId = CT.TableID
		option (maxrecursion 0)
		--exec ChangeCollation_SP

 
---------------------------------------------------------------------------------------------------------------------------
-- Backup Views
---------------------------------------------------------------------------------------------------------------------------
    INSERT INTO #ChangeCollationObjectsBackupTbl
    (SchemaID, TableID, ObjectName, ObjectType, CreateScript, DropScript, ExistsScript, Processed)
    SELECT SchemaID, TableID, ObjectName, ObjectType, CreateScript, DropScript, ExistsScript, Processed
     FROM
    (
        SELECT SchemaID=SV.schema_id
              ,TableID= x.referenced_major_id 
              ,ObjectName=SV.name
              ,ObjectType='View'
              ,CreateScript=definition
              ,DropScript='DROP VIEW ' + QUOTEname(SCH.name) + '.' + QUOTEname(SV.name)
              ,ExistsScript=' EXISTS (SELECT 1 
                           FROM sys.Views SV
                           JOIN sys.schemas SCH
                             ON SV.Schema_id = SCH.Schema_ID
                          WHERE SV.name =''' + SV.name + '''
                            AND SCH.name =''' + SCH.name + ''')'
              ,Processed=0
              ,Rnk = Rank() Over(Partition by SV.name order by x.referenced_major_id)
          FROM sys.views SV
          JOIN sys.sql_modules SQM
            ON SV.object_id = SQM.object_id
          JOIN
            (
                SELECT DISTINCT SD.object_id,SD.referenced_major_id
                  FROM sys.sql_dependencies SD
                  JOIN sys.objects so
                    ON SD.referenced_major_id = so.object_id
                  JOIN sys.columns SC
                    ON SC.object_id = so.object_id
                   AND SC.column_id = SD.referenced_minor_id
                  JOIN #ChangeCollationColumns CCC
                    ON SC.column_id = CCC.ColumnID
                   AND so.object_id  = CCC.TableID
                   AND so.schema_id     = CCC.SchemaID
 
            ) x
            ON x.object_id = SV.object_id
          JOIN sys.schemas SCH
            ON SCH.schema_id = SV.schema_id
        ) Vie
        WHERE Vie.Rnk = 1
 
     
     
 
---------------------------------------------------------------------------------------------------------------------------
-- Backup Computed Columns
---------------------------------------------------------------------------------------------------------------------------
     
    INSERT INTO #ChangeCollationObjectsBackupTbl
    (SchemaID, TableID, ObjectName, ObjectType, CreateScript, DropScript, ExistsScript, Processed)
    SELECT CCC.SchemaID 
          ,CCC.TableID
          ,SCC.name
          ,'ComputedColumn'
          ,'ALTER TABLE ' + QUOTEname(CCC.SchemaName) + '.' + QUOTEname(CCC.TableName) + 
           ' ADD  ' + QUOTEname(SCC.name) + ' as ' + SCC.definition
          ,'ALTER TABLE ' + QUOTEname(CCC.SchemaName) + '.' + QUOTEname(CCC.TableName) + 
           ' DROP COLUMN  ' + QUOTEname(SCC.name) 
          ,'EXISTS (SELECT 1 
                      FROM sys.computed_columns SCC
                      JOIN sys.tables ST
                        ON ST.object_id = SCC.object_id
                      JOIN sys.schemas SCH
                        ON ST.schema_id = SCH.schema_id
                      WHERE SCC.name =''' + SCC.name  + '''
                        AND ST.name  =''' + CCC.TableName + '''
                        AND SCH.name =''' + CCC.SchemaName + ''')'
          ,0
      FROM sys.computed_columns SCC
      JOIN #ChangeCollationTables CCC
        ON SCC.object_id = CCC.TableID
      JOIN sys.tables ST
        ON ST.object_id = CCC.TableID
       AND ST.schema_id = CCC.SchemaID
 
        
 
 
-----------------------------------------------------------------------------------------------------------------------------
-- Backup Statistics
-----------------------------------------------------------------------------------------------------------------------------
 
    INSERT INTO #ChangeCollationObjectsBackupTbl
        (SchemaID, TableID, ObjectName, ObjectType, CreateScript, DropScript, ExistsScript, Processed)
    SELECT CCC.SchemaID
          ,CCC.TableID
          ,STA.name
          ,'Statistics'
          ,NULL
          ,'DROP STATISTICS' + QUOTEname(CCC.SchemaName) + '.' + QUOTEname(CCC.TableName) + '.' + QUOTEname(STA.name)
          ,' EXISTS ( SELECT * FROM sys.stats WHERE name = ''' + STA.name + ''' AND object_id = ' + CONVERT(VARCHAR(50),STA.object_id) + ')'
          , 0
      FROM sys.stats_columns STAC
      JOIN #ChangeCollationColumns CCC
        ON STAC.object_id = CCC.TableID 
       AND STAC.column_id = CCC.ColumnID
      JOIN sys.stats STA
        ON STA.stats_id    = STAC.stats_id
       AND STA.object_id      = STAC.object_id
 
 
---------------------------------------------------------------------------------------------------------------------------
-- Backup Indexes
---------------------------------------------------------------------------------------------------------------------------
    IF OBJECT_ID('#CollationIDXTable','U') IS NOT NULL
    BEGIN
 
        DROP TABLE #CollationIDXTable
    END
 
        CREATE TABLE #CollationIDXTable 
        (
             Schema_ID        INT
            ,Object_ID        INT
            ,Index_ID        INT
            ,SchemaName        sysname
            ,TableName        sysname
            ,Indexname        sysname
            ,IsPrimaryKey   BIT
            ,IndexType        INT
            ,CreateScript    VARCHAR(MAX)    NULL
            ,DropScript        VARCHAR(MAX)    NULL
            ,ExistsScript    VARCHAR(MAX)    NULL
            ,Processed        BIT                NULL
        )
     
    INSERT INTO [dbo].[#CollationIDXTable]
        (
         Schema_ID        
        ,Object_ID        
        ,Index_ID        
        ,SchemaName        
        ,TableName        
        ,Indexname        
        ,IsPrimaryKey  
        ,IndexType 
        )
    SELECT DISTINCT ST.schema_id
          ,ST.object_id
          ,SI.index_id
          ,SCH.name
          ,ST.name
          ,SI.name
          ,SI.is_primary_key
          ,SI.type
      FROM sys.indexes SI
      JOIN sys.tables  ST
        ON SI.object_id = ST.object_id
      JOIN sys.schemas SCH
        ON SCH.schema_id = ST.schema_id
      JOIN sys.index_columns SIC
          ON SIC.object_id = SI.object_id
       AND SIC.index_id  = SI.index_id
       --AND SIC.is_included_column = 0
      JOIN #ChangeCollationColumns CCC
        ON SIC.column_id = CCC.ColumnID
       AND ST.object_id  = CCC.TableID
       AND ST.schema_id     = CCC.SchemaID
      WHERE SI.type IN (1,2)
       
    UNION
    SELECT DISTINCT ST.schema_id
          ,ST.object_id
          ,SI.index_id
          ,SCH.name
          ,ST.name
          ,SI.name
          ,SI.is_primary_key
          ,SI.type
      FROM sys.indexes SI
      JOIN sys.tables  ST
        ON SI.object_id = ST.object_id
      JOIN sys.schemas SCH
        ON SCH.schema_id = ST.schema_id
      JOIN sys.index_columns SIC
          ON SIC.object_id = SI.object_id
       AND SIC.index_id  = SI.index_id
       --AND SIC.is_included_column = 0
      JOIN #ChangeCollationTables CCC
        ON ST.object_id  = CCC.TableID
       AND ST.schema_id     = CCC.SchemaID
      JOIN sys.columns   SC
        ON SC.object_id  = CCC.TableID
       AND SC.column_id  = SIC.column_id
       AND SC.is_computed = 1
      WHERE SI.Type IN (1,2)
   
   
   
  SELECT @CreateSQL = ''
  SELECT @IndexColsSQL = ''
  SELECT @WithSQL = ''
  SELECT @IncludeSQL = ''
  SELECT @WhereSQL = ''
   
   
    WHILE EXISTS(SELECT 1
                   FROM [dbo].[#CollationIDXTable]
                  WHERE CreateScript IS NULL)
    BEGIN
     
        SELECT TOP 1 @SchemaID = Schema_ID
              ,@TableID  = Object_ID
              ,@IndexID  = Index_ID
              ,@isPrimaryKey = IsPrimaryKey
              ,@Indexname     = Indexname
              ,@IndexType     = IndexType
              ,@SchemaName     = SchemaName
              ,@TableName     = TableName
          FROM [dbo].[#CollationIDXTable]
         WHERE CreateScript IS NULL
           --AND SchemaName = @SchemaName
           --AND TableName  = @TableName
         ORDER BY Index_ID
     
        SELECT @TblSchemaName = QUOTEname(@SchemaName) + '.' + QUOTEname(@TableName)
          
        IF @isPrimaryKey = 1
        BEGIN
         
            SELECT @ExistsSQL = ' EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N''' + @TblSchemaName + ''') AND name = N''' + @Indexname + ''')'
             
            SELECT @DropSQL =   ' ALTER TABLE '+ @TblSchemaName + ' DROP CONSTRAINT [' + @Indexname + ']'
        END
        ELSE
        BEGIN
 
            SELECT @ExistsSQL = ' EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N''' + @TblSchemaName + ''') AND name = N''' + @Indexname + ''')'
            SELECT @DropSQL =  ' DROP INDEX [' + @Indexname  + '] ON ' + @TblSchemaName + 
                              CASE
                              WHEN @IndexType IN (1,2) THEN ' WITH ( ONLINE = OFF )'
                              ELSE ''
                              END
        END
         
        IF @IndexType IN (1,2)
        BEGIN
                SELECT @CreateSQL = CASE
                                    WHEN SI.is_primary_key = 1 THEN
                                        'ALTER TABLE ' + @TblSchemaName + ' ADD  CONSTRAINT [' + @Indexname + '] PRIMARY KEY ' + SI.type_desc
                                    WHEN SI.Type IN (1,2) THEN
                                        ' CREATE ' + CASE SI.is_unique WHEN 1 THEN ' UNIQUE ' ELSE '' END + SI.type_desc + ' INDEX ' + QUOTEname(SI.name) + ' ON ' + @TblSchemaName
                                    END
                      ,@IndexColsSQL =  ( SELECT SC.name + ' '
                                 + CASE SIC.is_descending_key
                                   WHEN 0 THEN ' ASC '
                                   ELSE 'DESC'
                                   END +  ','
                            FROM sys.index_columns SIC
                            JOIN sys.columns SC
                              ON SIC.object_id = SC.object_id
                             AND SIC.column_id = SC.column_id
                          WHERE SIC.object_id = SI.object_id
                            AND SIC.index_id  = SI.index_id
                            AND SIC.is_included_column = 0
                          ORDER BY SIC.key_ordinal
                           FOR XML PATH('')
                        ) 
                        ,@WithSQL =' WITH (PAD_INDEX  = ' + CASE SI.is_padded WHEN 1 THEN 'ON' ELSE 'OFF' END + ',' + CHAR(13) +
                                   ' IGNORE_DUP_KEY = ' + CASE SI.ignore_dup_key WHEN 1 THEN 'ON' ELSE 'OFF' END + ',' + CHAR(13) +
                                   ' ALLOW_ROW_LOCKS = ' + CASE SI.allow_row_locks WHEN 1 THEN 'ON' ELSE 'OFF' END + ',' + CHAR(13) +
                                   ' ALLOW_PAGE_LOCKS = ' + CASE SI.allow_page_locks WHEN 1 THEN 'ON' ELSE 'OFF' END + ',' + CHAR(13) +
                                   CASE SI.type WHEN 2 THEN 'SORT_IN_TEMPDB = OFF,DROP_EXISTING = OFF,' ELSE '' END + 
                                   CASE WHEN SI.fill_factor > 0 THEN ' FILLFACTOR = ' + CONVERT(VARCHAR(3),SI.fill_factor) + ',' ELSE '' END +
                                   ' STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, ONLINE = OFF) ON ' + QUOTEname(SFG.name)
                        ,@IncludeSQL =  ( SELECT QUOTEname(SC.name) +  ','
                                            FROM sys.index_columns SIC
                                            JOIN sys.columns SC
                                              ON SIC.object_id = SC.object_id
                                             AND SIC.column_id = SC.column_id
                                          WHERE SIC.object_id = SI.object_id
                                            AND SIC.index_id  = SI.index_id
                                            AND SIC.is_included_column = 1
                                          ORDER BY SIC.key_ordinal
                                           FOR XML PATH('')
                                        ) 
                        ,@WhereSQL  = SI.filter_definition
                  FROM sys.indexes SI
                  JOIN sys.filegroups SFG
                    ON SI.data_space_id =SFG.data_space_id
                 WHERE object_id = @TableID
                   AND index_id  = @IndexID
                    
                   SELECT @IndexColsSQL = '(' + SUBSTRING(@IndexColsSQL,1,LEN(@IndexColsSQL)-1) + ')'
                    
                   IF LTRIM(RTRIM(@IncludeSQL)) <> ''
                        SELECT @IncludeSQL   = ' INCLUDE (' + SUBSTRING(@IncludeSQL,1,LEN(@IncludeSQL)-1) + ')'
                 
                   IF LTRIM(RTRIM(@WhereSQL)) <> ''
                       SELECT @WhereSQL        = ' WHERE (' + @WhereSQL + ')'
         
        END
         
         
           SELECT @CreateSQL = @CreateSQL 
                               + @IndexColsSQL + CASE WHEN @IndexColsSQL <> '' THEN CHAR(13) ELSE '' END
                               + ISNULL(@IncludeSQL,'') + CASE WHEN @IncludeSQL <> '' THEN CHAR(13) ELSE '' END
                               + ISNULL(@WhereSQL,'') + CASE WHEN @WhereSQL <> '' THEN CHAR(13) ELSE '' END
                               + @WithSQL 
 
     
            UPDATE [dbo].[#CollationIDXTable]
               SET CreateScript = @CreateSQL
                  ,DropScript   = @DropSQL
                  ,ExistsScript = @ExistsSQL
             WHERE Schema_ID = @SchemaID
               AND Object_ID = @TableID
               AND Index_ID  = @IndexID
                
     END  
 
 
     INSERT INTO #ChangeCollationObjectsBackupTbl
    (SchemaID, TableID, ObjectName, ObjectType, CreateScript, DropScript, ExistsScript, Processed)
     SELECT Schema_ID,Object_ID,Indexname,'Index-'
            + CASE IndexType 
              WHEN 1 THEN 'Clustered'
              WHEN 2 THEN 'NonClustered'
              ELSE ''
              END
           ,CreateScript, DropScript, ExistsScript, 0 
       FROM [#CollationIDXTable]
     
     
 
-----------------------------------------------------------------------------------------------------------------------------
-- Backup Check Constraints
-----------------------------------------------------------------------------------------------------------------------------
 
INSERT INTO #ChangeCollationObjectsBackupTbl
    (SchemaID, TableID, ObjectName, ObjectType, CreateScript, DropScript, ExistsScript, Processed)
    SELECT CCC.SchemaID 
          ,CCC.TableID
          ,SCC.name
          ,'ComputedColumn'
          ,'ALTER TABLE ' + QUOTEname(CCC.SchemaName) + '.' + QUOTEname(CCC.TableName) + 
           ' ADD  CONSTRAINT  ' + QUOTEname(SCC.name) + ' CHECK ' + SCC.definition
          ,'ALTER TABLE ' + QUOTEname(CCC.SchemaName) + '.' + QUOTEname(CCC.TableName) + 
           ' DROP CONSTRAINT  ' + QUOTEname(SCC.name) 
          ,'EXISTS (SELECT 1 
                      FROM sys.check_constraints SCC
                      JOIN sys.tables ST
                        ON ST.object_id = SCC.Parent_object_id
                      JOIN sys.schemas SCH
                        ON ST.schema_id = SCH.schema_id
                      WHERE SCC.name =''' + SCC.name  + '''
                        AND ST.name  =''' + CCC.TableName + '''
                        AND SCH.name =''' + CCC.SchemaName + ''')'
          ,0
      FROM sys.check_constraints SCC
      JOIN #ChangeCollationTables CCC
        ON SCC.parent_object_id = CCC.TableID
      JOIN sys.tables ST
        ON ST.object_id = CCC.TableID
       AND ST.schema_id = CCC.SchemaID
 
 
 
-----------------------------------------------------------------------------------------------------------------------------
-- Backup Foreignkey Constraints
-----------------------------------------------------------------------------------------------------------------------------
    INSERT INTO #ChangeCollationObjectsBackupTbl
        (SchemaID, TableID, ObjectName, ObjectType, CreateScript, DropScript, ExistsScript, Processed)
    SELECT STP.schema_id
          ,STP.object_id
          ,SF.name
          ,'Foreign Key'
          ,' ALTER TABLE ' + QUOTEname(SCHEMA_name(STP.schema_id)) + '.' + QUOTEname(STP.name) 
          +'  WITH CHECK ADD  CONSTRAINT ' + QUOTEname(SF.name) + ' FOREIGN KEY(' + 
          STUFF
            (
            (
            SELECT ',' + QUOTEname(SC.name)
              FROM sys.foreign_key_columns SFC
              JOIN sys.columns SC
                ON SC.object_id = SFC.parent_object_id
               AND SC.column_id = SFC.parent_column_id
             WHERE SFC.constraint_object_id = SF.object_id
             ORDER BY SC.column_id
             FOR XML PATH ('')
             ),1,1,'') 
             + ') REFERENCES ' + QUOTEname(SCHEMA_name(STC.schema_id)) + '.' + QUOTEname(STC.name) 
             + ' (' +
             + STUFF
                (
                (
                SELECT ',' + QUOTEname(SC.name)
                  FROM sys.foreign_key_columns SFC
                  JOIN sys.columns SC
                    ON SC.object_id = SFC.referenced_object_id
                   AND SC.column_id = SFC.referenced_column_id
                 WHERE SFC.constraint_object_id = SF.object_id
                 ORDER BY SC.column_id
                 FOR XML PATH ('')
                 ),1,1,'')
             + ')'
 
             ,'ALTER TABLE ' + QUOTEname(SCHEMA_name(STP.schema_id)) + '.' + QUOTEname(STP.name)  + ' DROP CONSTRAINT [' + SF.name + ']'
             ,' EXISTS ( SELECT 1 FROM sys.FOREIGN_KEYS WHERE name =''' + SF.name + ''' and parent_object_id = ' + CONVERT(varchar(50),SF.parent_object_id) + ')'
             ,0
      FROM sys.foreign_keys SF
      JOIN sys.tables STP
        ON STP.object_id = SF.parent_object_id
      JOIN sys.tables STC
        ON STC.object_id = SF.referenced_object_id
     WHERE EXISTS (
                   SELECT 1 
                     FROM sys.foreign_key_columns SFCIn
                     JOIN #ChangeCollationColumns CCC
                       ON SFCIn.parent_object_id = CCC.TableID
                      AND SFCIn.parent_column_id = CCC.ColumnID
                    WHERE SFCIn.constraint_object_id = SF.object_id
                  )    
 
    UNION
     
    SELECT STP.schema_id
              ,STP.object_id
              ,SF.name
              ,'Foreign Key'
              ,' ALTER TABLE ' + QUOTEname(SCHEMA_name(STC.schema_id)) + '.' + QUOTEname(STC.name) 
              +'  WITH CHECK ADD  CONSTRAINT ' + QUOTEname(SF.name) + ' FOREIGN KEY(' + 
              STUFF
                (
                (
                SELECT ',' + QUOTEname(SC.name)
                  FROM sys.foreign_key_columns SFC
                  JOIN sys.columns SC
                    ON SC.object_id = SFC.parent_object_id
                   AND SC.column_id = SFC.parent_column_id
                 WHERE SFC.constraint_object_id = SF.object_id
                 ORDER BY SC.column_id
                 FOR XML PATH ('')
                 ),1,1,'') 
                 + ') REFERENCES ' + QUOTEname(SCHEMA_name(STP.schema_id)) + '.' + QUOTEname(STP.name) 
                 + ' (' +
                 + STUFF
                    (
                    (
                    SELECT ',' + QUOTEname(SC.name)
                      FROM sys.foreign_key_columns SFC
                      JOIN sys.columns SC
                        ON SC.object_id = SFC.referenced_object_id
                       AND SC.column_id = SFC.referenced_column_id
                     WHERE SFC.constraint_object_id = SF.object_id
                     ORDER BY SC.column_id
                     FOR XML PATH ('')
                     ),1,1,'')
                 + ')'
 
                 ,'ALTER TABLE ' + QUOTEname(SCHEMA_name(STC.schema_id)) + '.' + QUOTEname(STC.name)  + ' DROP CONSTRAINT [' + SF.name + ']'
                 ,' EXISTS ( SELECT 1 FROM sys.FOREIGN_KEYS WHERE name =''' + SF.name + ''' and parent_object_id = ' + CONVERT(varchar(50),SF.parent_object_id) + ')'
                 ,0
              FROM sys.foreign_keys SF
          JOIN sys.tables STP
            ON STP.object_id = SF.referenced_object_id
          JOIN sys.tables STC
            ON STC.object_id = SF.parent_object_id 
         WHERE EXISTS (
                       SELECT 1 
                         FROM sys.foreign_key_columns SFCIn
                         JOIN #ChangeCollationColumns CCC
                           ON SFCIn.referenced_object_id = CCC.TableID
                          AND SFCIn.referenced_column_id = CCC.ColumnID
                        WHERE SFCIn.constraint_object_id = SF.object_id
                      )    
 
 
-----------------------------------------------------------------------------------------------------------------------------
-- Loop  through Tables to change Collation
-----------------------------------------------------------------------------------------------------------------------------
    DECLARE @BackupID int
    DECLARE @ObjectType VARCHAR(50)
    DECLARE @ObjectName sysname
 
 
-----------------------------------------------------------------------------------------------------------------------------
-- Inner Loop  -- Drop the objects
-----------------------------------------------------------------------------------------------------------------------------
 
 
    UPDATE [dbo].[#ChangeCollationTables]
        SET Processed = 0
      
    WHILE EXISTS(SELECT 1
                   FROM #ChangeCollationTables
                  WHERE ISNULL(Processed,0) = 0 
                      )
    BEGIN
     
        SELECT @sql = ''
     
        SELECT TOP 1 @SchemaID = SchemaID
              ,@TableID           = TableID
              ,@TableName       = TableName
              ,@SchemaName       = SchemaName
              --,@sql = 'IF ' + ExistsScript + CHAR(13) + DropScript + CHAR(13)
          FROM [dbo].[#ChangeCollationTables]
         WHERE ISNULL(Processed,0) = 0
         ORDER BY RunRank DESC, SchemaID ASC,TableID ASC
 
          
 
                UPDATE #ChangeCollationObjectsBackupTbl
                   SET Processed = 0 
                 WHERE SchemaID  = @SchemaID
                   AND TableID   = @TableID
 
          
                WHILE EXISTS(SELECT 1
                                FROM #ChangeCollationObjectsBackupTbl
                                WHERE ISNULL(Processed,0) = 0 
                                  AND SchemaID = @SchemaID
                                  AND TableID  = @TableID
                                    )
                BEGIN
     
                    SELECT @sql = ''
     
                    SELECT TOP 1 @BackupID = BackupID
                            ,@ObjectName   = ObjectName
                            ,@ObjectType   = ObjectType
                            ,@sql = 'IF ' + ExistsScript + CHAR(13) + DropScript + CHAR(13)
                        FROM #ChangeCollationObjectsBackupTbl
                        WHERE ISNULL(Processed,0) = 0
                          AND SchemaID = @SchemaID
                          AND TableID  = @TableID
                        ORDER BY BackupID DESC
          
                        IF @GenerateScriptsOnly = 1
                        BEGIN
                            PRINT @sql
                        END
                        ELSE
                        BEGIN
                             
                                PRINT @sql
                            EXEC (@sql)
                        END
          
         
          
                        UPDATE #ChangeCollationObjectsBackupTbl
                         SET Processed = 1
                        WHERE SchemaID    = @SchemaID
                        AND TableID        = @TableID
                        AND BackupID    = @BackupID
             
                END
 
         UPDATE [dbo].[#ChangeCollationTables]
             SET Processed = 1
          WHERE SchemaID = @SchemaID
            AND TableID = @TableID
     
    END
 
     
 -----------------------------------------------------------------------------------------------------------------------------
-- Apply the collation changes
-----------------------------------------------------------------------------------------------------------------------------
     
    UPDATE [dbo].[#ChangeCollationTables]
        SET Processed = 0
      
    WHILE EXISTS(SELECT 1
                   FROM #ChangeCollationTables
                  WHERE ISNULL(Processed,0) = 0 
                      )
    BEGIN
     
        SELECT @sql = ''
     
        SELECT TOP 1 @SchemaID = SchemaID
              ,@TableID           = TableID
              ,@TableName       = TableName
              ,@SchemaName       = SchemaName
              --,@sql = 'IF ' + ExistsScript + CHAR(13) + DropScript + CHAR(13)
          FROM [dbo].[#ChangeCollationTables]
         WHERE ISNULL(Processed,0) = 0
         ORDER BY RunRank DESC, SchemaID ASC,TableID ASC
 
 
        SELECT @sql = ''
 
         SELECT @sql = @sql + AlterScript + CHAR(13)
           FROM #ChangeCollationColumns
          WHERE SchemaID = @SchemaID
            AND TableID = @TableID
          
        IF @GenerateScriptsOnly = 1
        BEGIN
            PRINT @sql
        END
        ELSE
        BEGIN
            PRINT @sql
                             
            EXEC (@sql)
        END
         
 
         UPDATE [dbo].[#ChangeCollationTables]
             SET Processed = 1
          WHERE SchemaID = @SchemaID
            AND TableID = @TableID
     
    END
         
         
-----------------------------------------------------------------------------------------------------------------------------
-- Inner Loop  -- ReApply the objects
-----------------------------------------------------------------------------------------------------------------------------
 
    UPDATE [dbo].[#ChangeCollationTables]
        SET Processed = 0
      
    WHILE EXISTS(SELECT 1
                   FROM #ChangeCollationTables
                  WHERE ISNULL(Processed,0) = 0 
                      )
    BEGIN
     
        SELECT @sql = ''
     
        SELECT TOP 1 @SchemaID = SchemaID
              ,@TableID           = TableID
              ,@TableName       = TableName
              ,@SchemaName       = SchemaName
              --,@sql = 'IF ' + ExistsScript + CHAR(13) + DropScript + CHAR(13)
          FROM [dbo].[#ChangeCollationTables]
         WHERE ISNULL(Processed,0) = 0
         ORDER BY RunRank asc, SchemaID ASC,TableID ASC
 
          
 
                UPDATE #ChangeCollationObjectsBackupTbl
                   SET Processed = 0 
                 WHERE SchemaID  = @SchemaID
                   AND TableID   = @TableID
 
          
          
                WHILE EXISTS(SELECT 1
                                FROM #ChangeCollationObjectsBackupTbl
                                WHERE ISNULL(Processed,0) = 0 
                                  AND SchemaID = @SchemaID
                                  AND TableID  = @TableID
                                  AND CreateScript IS NOT NULL
                                    )
                BEGIN
     
                    SELECT @sql = ''
     
                    SELECT TOP 1 @BackupID = BackupID
                            ,@ObjectName   = ObjectName
                            ,@ObjectType   = ObjectType
                            ,@sql = CASE ObjectType
                                    WHEN 'View' THEN CreateScript + CHAR(13)
                                    ELSE 'IF NOT ' + ExistsScript + CHAR(13) + CreateScript + CHAR(13)
                                    END
                        FROM #ChangeCollationObjectsBackupTbl
                        WHERE ISNULL(Processed,0) = 0
                          AND SchemaID = @SchemaID
                          AND TableID  = @TableID
                          AND CreateScript IS NOT NULL
                        ORDER BY BackupID ASC
          
                        IF @GenerateScriptsOnly = 1
                        BEGIN
                            PRINT @sql
                        END
                        ELSE
                        BEGIN
                            PRINT @sql
                            EXEC (@sql)
                        END
          
         
          
                        UPDATE #ChangeCollationObjectsBackupTbl
                         SET Processed = 1
                        WHERE SchemaID    = @SchemaID
                        AND TableID        = @TableID
                        AND BackupID    = @BackupID
             
                END
 
             UPDATE [dbo].[#ChangeCollationTables]
                 SET Processed = 1
              WHERE SchemaID = @SchemaID
                AND TableID = @TableID
     
        END
  
GO