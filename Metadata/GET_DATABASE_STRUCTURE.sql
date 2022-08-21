SET NOCOUNT ON;

DECLARE @Database_Name NVARCHAR(128) = 'AdventureWorks2017';

IF NOT EXISTS (
    SELECT *
    FROM [master].[sys].[databases]
    WHERE [name] = @Database_Name)

    BEGIN
        SET NOCOUNT OFF;
        THROW 50000, 'Database does not exist.', 1;
    END

DECLARE @SQL_Initial NVARCHAR(MAX);
DECLARE @SQL_FINAL NVARCHAR(MAX) = '';
DECLARE @SQL_Tables NVARCHAR(MAX);
DECLARE @SQL_Views NVARCHAR(MAX);
DECLARE @SQL_Triggers NVARCHAR(MAX);
DECLARE @SQL_Functions NVARCHAR(MAX);
DECLARE @SQL_Stored_Procedures NVARCHAR(MAX);
DECLARE @SQL_Sequences NVARCHAR(MAX);
DECLARE @SQL_Indexes NVARCHAR(MAX);
DECLARE @SQL_UDDTs NVARCHAR(MAX);

SET @SQL_Initial = 'USE ' + QUOTENAME(@Database_Name) + ';';

EXEC sp_executesql @SQL_Initial;

SET @SQL_Tables = '(SELECT CAST(COUNT([name]) AS NVARCHAR(128)) AS [Tables]' + CHAR(13) + 
                   'FROM ' + QUOTENAME(@Database_Name) + '.[sys].[tables]' + CHAR(13) + 
                   'WHERE [type] = ''U'')';

SET @SQL_Views = '(SELECT CAST(COUNT([name]) AS NVARCHAR(128)) AS [Views]' + CHAR(13) + 
                  'FROM ' + QUOTENAME(@Database_Name) + '.[sys].[objects]' + CHAR(13) + 
                  'WHERE [type] = ''V'')';

SET @SQL_Triggers = '(SELECT CAST(COUNT([name]) AS NVARCHAR(128)) AS [Triggers]' + CHAR(13) + 
                     'FROM ' + QUOTENAME(@Database_Name) + '.[sys].[triggers])';

SET @SQL_Functions = '(SELECT CAST(COUNT([ROUTINE_NAME]) AS NVARCHAR(128)) AS [Functions]' + CHAR(13) + 
                     'FROM ' + QUOTENAME(@Database_Name) + '.[INFORMATION_SCHEMA].[ROUTINES]' + CHAR(13) + 
                     'WHERE [ROUTINE_TYPE] = ''FUNCTION'')';

SET @SQL_Stored_Procedures = '(SELECT CAST(COUNT([ROUTINE_NAME]) AS NVARCHAR(128)) AS [Stored procedures]' + CHAR(13) + 
                              'FROM ' + QUOTENAME(@Database_Name) + '.[INFORMATION_SCHEMA].[ROUTINES]' + CHAR(13) + 
                              'WHERE [ROUTINE_TYPE] = ''PROCEDURE'')';

SET @SQL_Sequences = '(SELECT CAST(COUNT([name]) AS NVARCHAR(128)) AS [Sequences]' + CHAR(13) + 
                      'FROM ' + QUOTENAME(@Database_Name) + '.[sys].[sequences])';

SET @SQL_Indexes = '(SELECT CAST(COUNT(DISTINCT [I].[name]) AS NVARCHAR(128)) AS [Indexes]' + CHAR(13) + 
                    'FROM ' + QUOTENAME(@Database_Name) + '.[sys].[tables] AS [T]' + CHAR(13) + 
                         'INNER JOIN ' + QUOTENAME(@Database_Name) + '.[sys].[indexes] AS [I] ON [T].[object_id] = [I].[object_id]' + CHAR(13) + 
                         'INNER JOIN ' + QUOTENAME(@Database_Name) + '.[sys].[index_columns] AS [IC] ON [I].[object_id] = [IC].[object_id]' + CHAR(13) + 
                         'INNER JOIN ' + QUOTENAME(@Database_Name) + '.[sys].[all_columns] AS [AC] ON [T].[object_id] = [AC].[object_id]' + CHAR(13) + 
                                                                                                 'AND [IC].[column_id] = [AC].[column_id]'+ CHAR(13) + 
                    'WHERE [T].[is_ms_shipped] = 0' + CHAR(13) + 
                      'AND [I].[type_desc] <> ''HEAP'')';

SET @SQL_UDDTs = '(SELECT CAST(COUNT([name]) AS NVARCHAR(128)) AS [UDDTs]' + CHAR(13) + 
                 'FROM ' + QUOTENAME(@Database_Name) + '.[sys].[types]' + CHAR(13) + 
                 'WHERE [is_user_defined] = 1)';

SET @SQL_FINAL = '(SELECT 1 AS [N], ''Database'' AS [Object], ''' + @Database_Name + ''' AS [Value])' + CHAR(13) + 
                 'UNION ALL' + CHAR(13) + 
                 '(SELECT 2, ''Tables'',' + @SQL_Tables + ')' + CHAR(13) + 
                 'UNION ALL' + CHAR(13) +  
                 '(SELECT 3, ''Views'',' + @SQL_Views + ')' + CHAR(13) + 
                 'UNION ALL' + CHAR(13) + 
                 '(SELECT 4, ''Triggers'',' + @SQL_Triggers + ')' + CHAR(13) + 
                 'UNION ALL' + CHAR(13) + 
                 '(SELECT 5, ''Functions'',' + @SQL_Functions + ')' + CHAR(13) + 
                 'UNION ALL' + CHAR(13) + 
                 '(SELECT 6, ''Stored procedures'',' + @SQL_Stored_Procedures + ')' + CHAR(13) + 
                 'UNION ALL' + CHAR(13) + 
                 '(SELECT 7, ''Sequences'',' + @SQL_Sequences + ')' + CHAR(13) + 
                 'UNION ALL' + CHAR(13) + 
                 '(SELECT 8, ''Indexes'',' + @SQL_Indexes + ')' + CHAR(13) + 
                 'UNION ALL' + CHAR(13) + 
                 '(SELECT 9, ''UDDTs'',' + @SQL_UDDTs + ')';

EXEC sp_executesql @SQL_FINAL;

SET NOCOUNT OFF;