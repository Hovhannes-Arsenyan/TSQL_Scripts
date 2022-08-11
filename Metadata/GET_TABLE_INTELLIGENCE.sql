DECLARE @DatabaseName NVARCHAR(128) = N'AdventureWorksDW2017';
DECLARE @TableName NVARCHAR(128) = N'DimDate';
DECLARE @DBID INT;
DECLARE @SQL NVARCHAR(MAX);
DECLARE @ParamDefinition NVARCHAR(MAX);
DECLARE @LoopCounter INT = 1;
DECLARE @ColumnName NVARCHAR(128);
DECLARE @CountRecords BIGINT;
DECLARE @CountData BIGINT;
DECLARE @CountNULLs BIGINT;
DECLARE @CountNULLsPercent DECIMAL(5,2);
DECLARE @CountDistinct BIGINT;
DECLARE @CountDistinctPercent DECIMAL(5,2);

IF NOT EXISTS 
    (SELECT * FROM [master].[sys].[databases] WHERE [name] = @DatabaseName)
    THROW 50000, 'Database does not exist.',1;

SET @SQL = 'IF NOT EXISTS' + CHAR(13) + 
               '(SELECT * FROM ' + QUOTENAME(@DatabaseName) + '.[INFORMATION_SCHEMA].[COLUMNS]' + CHAR(13) + 
                'WHERE [TABLE_NAME] = ''' + @TableName + ''')' + CHAR(13) + 
                'THROW 50000, ''Table does not exist.'',1;';

EXEC sp_executesql @SQL;

SET @DBID = (SELECT [database_id]
             FROM [master].[sys].[databases]
             WHERE [name] = @DatabaseName); 

SET NOCOUNT ON;

IF OBJECT_ID('tempdb..#Table_Report') IS NOT NULL
    DROP TABLE #Table_Report;

CREATE TABLE #Table_Report (
    [ID] INT NOT NULL IDENTITY(1,1),
    [Column_Name] NVARCHAR(128) NOT NULL,
    [Position] INT NOT NULL,
    [Data_Type] NVARCHAR(128) NOT NULL,
    [IS_Nullable] NVARCHAR(3) NOT NULL,
    [IS_Identity] NVARCHAR(3) NOT NULL,
    [IS_RowGUID] NVARCHAR(3) NOT NULL,
    [IS_Computed] NVARCHAR(3) NOT NULL,
    [IS_Filestream] NVARCHAR(3) NOT NULL,
    [IS_XML] NVARCHAR(3) NOT NULL,
    [IS_Hidden] NVARCHAR(3) NOT NULL,
    [IS_Masked] NVARCHAR(3) NOT NULL,
    [IS_Encrypted] NVARCHAR(3) NOT NULL,
    [IS_PK] NVARCHAR(3) NOT NULL,
    [IS_FK] NVARCHAR(3) NOT NULL,
    [Records] BIGINT,
    [Data] BIGINT,
    [NULLs] BIGINT,
    [NULLs_Percent] DECIMAL (5,2),
    [Distinct_Data] BIGINT,
    [Distinct_Percent] DECIMAL (5,2))

SET @SQL = 'INSERT INTO #Table_Report ([Column_Name],[Position],[Data_Type],[IS_Nullable],[IS_Identity],[IS_RowGUID],[IS_Computed],[IS_Filestream],[IS_XML],[IS_Hidden],[IS_Masked],[IS_Encrypted],[IS_PK],[IS_FK])' + CHAR(13) + 
           'SELECT [ISC].[COLUMN_NAME] AS [Column_Name],' + CHAR(13) + 
                  '[ISC].[ORDINAL_POSITION] AS [Position],' + CHAR(13) + 
                  'UPPER([ISC].[DATA_TYPE]) + IIF([ISC].[CHARACTER_MAXIMUM_LENGTH] IS NULL,'''',''('' + CAST([ISC].[CHARACTER_MAXIMUM_LENGTH] AS NVARCHAR(16)) + '')'') AS [Data_Type],' + CHAR(13) + 
                  '[ISC].[IS_NULLABLE] AS [IS_Nullable],' + CHAR(13) + 
                  'IIF([SSC].[is_identity] = 1,''YES'',''NO'') AS [IS_Identity],' + CHAR(13) + 
                  'IIF([SSC].[is_rowguidcol] = 1,''YES'',''NO'') AS [IS_RowGUID],' + CHAR(13) + 
                  'IIF([SSC].[is_computed] = 1,''YES'',''NO'') AS [IS_Computed],' + CHAR(13) + 
                  'IIF([SSC].[is_filestream] = 1,''YES'',''NO'') AS [IS_Filestream],' + CHAR(13) + 
                  'IIF([SSC].[is_xml_document] = 1,''YES'',''NO'') AS [IS_XML],' + CHAR(13) + 
                  'IIF(CAST(RIGHT(LEFT(@@VERSION,LEN(''Microsoft SQL Server'') + 5),CHARINDEX('' '',REVERSE(LEFT(@@VERSION,LEN(''Microsoft SQL Server'') + 5)))-1) AS INT) <= 2017,''NO'',IIF([SSC].[is_hidden] = 0,''NO'',''YES'')) AS [IS_Hidden],' + CHAR(13) + 
                  'IIF(CAST(RIGHT(LEFT(@@VERSION,LEN(''Microsoft SQL Server'') + 5),CHARINDEX('' '',REVERSE(LEFT(@@VERSION,LEN(''Microsoft SQL Server'') + 5)))-1) AS INT) <= 2017,''NO'',IIF([SSC].[is_masked] = 0,''NO'',''YES'')) AS [IS_Masked],' + CHAR(13) + 
                  'IIF([SSC].[encryption_type] IS NOT NULL,''YES'',''NO'') AS [IS_Encrypted],' + CHAR(13) + 
                  'IIF((SELECT [ISTC].[CONSTRAINT_TYPE]' + CHAR(13) + 
                       'FROM ' + QUOTENAME(@DatabaseName) + '.[INFORMATION_SCHEMA].[COLUMNS] AS [ISC2]' + CHAR(13) + 
                       'INNER JOIN ' + QUOTENAME(@DatabaseName) + '.[INFORMATION_SCHEMA].[KEY_COLUMN_USAGE] AS [ISKCU] ON [ISC2].[TABLE_NAME] = [ISKCU].[TABLE_NAME]' + CHAR(13) + 
                                                                                                                     'AND [ISC2].[COLUMN_NAME] = [ISKCU].[COLUMN_NAME]' + CHAR(13) + 
                       'INNER JOIN ' + QUOTENAME(@DatabaseName) + '.[INFORMATION_SCHEMA].[TABLE_CONSTRAINTS] AS [ISTC] ON [ISTC].[TABLE_NAME] = [ISKCU].[TABLE_NAME]' + CHAR(13) + 
                                                                                                                     'AND [ISTC].[CONSTRAINT_NAME] = [ISKCU].[CONSTRAINT_NAME]' + CHAR(13) + 
                                                                                                                     'AND [ISTC].[CONSTRAINT_TYPE] = N''PRIMARY KEY''' + CHAR(13) + 
                       'WHERE [ISC2].[TABLE_CATALOG] = [ISC].[TABLE_CATALOG]' + CHAR(13) + 
                         'AND [ISC2].[TABLE_NAME] = [ISC].[TABLE_NAME]' + CHAR(13) + 
                         'AND [ISC2].[COLUMN_NAME] = [ISC].[COLUMN_NAME]) IS NOT NULL, ''YES'',''NO'') AS [IS_PK],' + CHAR(13) + 
                  'IIF((SELECT [ISTC].[CONSTRAINT_TYPE]' + CHAR(13) + 
                       'FROM ' + QUOTENAME(@DatabaseName) + '.[INFORMATION_SCHEMA].[COLUMNS] AS [ISC3]' + CHAR(13) + 
                       'INNER JOIN ' + QUOTENAME(@DatabaseName) + '.[INFORMATION_SCHEMA].[KEY_COLUMN_USAGE] AS [ISKCU] ON [ISC3].[TABLE_NAME] = [ISKCU].[TABLE_NAME]' + CHAR(13) + 
                                                                                                                     'AND [ISC3].[COLUMN_NAME] = [ISKCU].[COLUMN_NAME]' + CHAR(13) + 
                       'INNER JOIN ' + QUOTENAME(@DatabaseName) + '.[INFORMATION_SCHEMA].[TABLE_CONSTRAINTS] AS [ISTC] ON [ISTC].[TABLE_NAME] = [ISKCU].[TABLE_NAME]' + CHAR(13) + 
                                                                                                                     'AND [ISTC].[CONSTRAINT_NAME] = [ISKCU].[CONSTRAINT_NAME]' + CHAR(13) + 
                                                                                                                     'AND [ISTC].[CONSTRAINT_TYPE] = N''FOREIGN KEY''' + CHAR(13) + 
                       'WHERE [ISC3].[TABLE_CATALOG] = [ISC].[TABLE_CATALOG]' + CHAR(13) + 
                         'AND [ISC3].[TABLE_NAME] = [ISC].[TABLE_NAME]' + CHAR(13) + 
                         'AND [ISC3].[COLUMN_NAME] = [ISC].[COLUMN_NAME]) IS NOT NULL, ''YES'',''NO'') AS [IS_FK]' + CHAR(13) + 
           'FROM ' + QUOTENAME(@DatabaseName) + '.[INFORMATION_SCHEMA].[COLUMNS] AS [ISC]' + CHAR(13) + 
           'INNER JOIN ' + QUOTENAME(@DatabaseName) + '.[sys].[columns] AS [SSC] ON OBJECT_ID([ISC].[TABLE_NAME],''U'') = [SSC].[object_id]' + CHAR(13) + 
                                                                               'AND [ISC].[COLUMN_NAME] = [SSC].[name]' + CHAR(13) + 
           'WHERE [ISC].[TABLE_CATALOG] = ''' + @DatabaseName + '''' + CHAR(13) + 
             'AND [ISC].[TABLE_NAME] = ''' + @TableName + ''';';

EXEC sp_executesql @SQL;

SET @SQL = 'SET @CountRecordsOUT = (SELECT COUNT(*)' + CHAR(13) + 
                                   'FROM ' + QUOTENAME(@DatabaseName) + '.' + QUOTENAME(OBJECT_SCHEMA_NAME(OBJECT_ID(@TableName,'U'),@DBID)) + '.' + QUOTENAME(@TableName) + ');';

SET @ParamDefinition = N'@CountRecordsOUT BIGINT OUTPUT';

EXEC sp_executesql @SQL, @ParamDefinition, @CountRecordsOUT = @CountRecords OUTPUT;

UPDATE #Table_Report
SET [Records] = @CountRecords;

WHILE @LoopCounter < = (SELECT COUNT(*) FROM #Table_Report)
    BEGIN
        SET @ColumnName = (SELECT [Column_Name] FROM #Table_Report WHERE [ID] = @LoopCounter);

        IF (SELECT [IS_Nullable] FROM #Table_Report WHERE [Column_Name] = @ColumnName) = 'NO'
            SET @CountData = @CountRecords;
        ELSE
            BEGIN
                SET @SQL = 'SET @CountDataOUT = (SELECT COUNT(' + QUOTENAME(@ColumnName) + ')' + CHAR(13) + 
                                                'FROM ' + QUOTENAME(@DatabaseName) + '.' + QUOTENAME(OBJECT_SCHEMA_NAME(OBJECT_ID(@TableName,'U'),@DBID)) + '.' + QUOTENAME(@TableName) + CHAR(13) + 
                                                'WHERE ' + QUOTENAME(@ColumnName) + ' IS NOT NULL);';

                SET @ParamDefinition = N'@CountDataOUT BIGINT OUTPUT';

                EXEC sp_executesql @SQL, @ParamDefinition, @CountDataOUT = @CountData OUTPUT;
        END

        SET @CountNULLs = @CountRecords - @CountData;
        SET @CountNULLsPercent = ROUND(CAST(@CountNULLs AS DECIMAL(16,2)) / CAST(@CountRecords AS DECIMAL(16,2)) * 100,2);

        SET @SQL = 'SET @CountDistinctOUT = (SELECT COUNT(DISTINCT ' + QUOTENAME(@ColumnName) + ')' + CHAR(13) + 
                                            'FROM ' + QUOTENAME(@DatabaseName) + '.' + QUOTENAME(OBJECT_SCHEMA_NAME(OBJECT_ID(@TableName,'U'),@DBID)) + '.' + QUOTENAME(@TableName) + CHAR(13) + 
                                            'WHERE ' + QUOTENAME(@ColumnName) + ' IS NOT NULL);';

        SET @ParamDefinition = N'@CountDistinctOUT BIGINT OUTPUT';

        EXEC sp_executesql @SQL, @ParamDefinition, @CountDistinctOUT = @CountDistinct OUTPUT;

        SET @CountDistinctPercent = ROUND(CAST(@CountDistinct AS DECIMAL(16,2)) / CAST(@CountRecords AS DECIMAL(16,2)) * 100,2);

        UPDATE #Table_Report
        SET [Data] = @CountData,
            [NULLs] = @CountNULLs,
            [NULLs_Percent] = @CountNULLsPercent,
            [Distinct_Data] = @CountDistinct,
            [Distinct_Percent] = @CountDistinctPercent
        WHERE [Column_Name] = @ColumnName;

        SET @LoopCounter = @LoopCounter + 1
    END

SET NOCOUNT OFF;

-- SELECT * FROM #Table_Report;