SET NOCOUNT ON;

DECLARE @Database_Name NVARCHAR(128) = 'AdventureWorks2017';

IF NOT EXISTS (
    SELECT *
    FROM [master].[sys].[databases]
    WHERE [name] = @Database_Name)

    BEGIN
        SET NOCOUNT OFF;
        RAISERROR('Database does not exist.',11,1);
    END
ELSE
    BEGIN
        DECLARE @SQL_FINAL NVARCHAR(MAX) = '';

        DECLARE @SQL_Tables NVARCHAR(MAX) = '(SELECT COUNT([name]) AS [Tables]' + CHAR(13) + 
                                             'FROM [' + @Database_Name + '].[sys].[tables]' + CHAR(13) + 
                                             'WHERE [type] = ''U'')';

		DECLARE @SQL_Views NVARCHAR(MAX) = '(SELECT COUNT([name]) AS [Views]' + CHAR(13) + 
											'FROM [' + @Database_Name + '].[sys].[objects]' + CHAR(13) + 
											'WHERE [type] = ''V'')';

		DECLARE @SQL_Triggers NVARCHAR(MAX) = '(SELECT COUNT([name]) AS [Triggers]' + CHAR(13) + 
											  'FROM [' + @Database_Name + '].[sys].[triggers])';

		DECLARE @SQL_Functions NVARCHAR(MAX) = '(SELECT COUNT([ROUTINE_NAME]) AS [Functions]' + CHAR(13) + 
										        'FROM [' + @Database_Name + '].[INFORMATION_SCHEMA].[ROUTINES]' + CHAR(13) + 
												'WHERE [ROUTINE_TYPE] = ''FUNCTION'')';

		DECLARE @SQL_Stored_Procedures NVARCHAR(MAX) = '(SELECT COUNT([ROUTINE_NAME]) AS [Stored procedures]' + CHAR(13) + 
										        'FROM [' + @Database_Name + '].[INFORMATION_SCHEMA].[ROUTINES]' + CHAR(13) + 
												'WHERE [ROUTINE_TYPE] = ''PROCEDURE'')';

		DECLARE @SQL_Sequences NVARCHAR(MAX) = '(SELECT COUNT([name]) AS [Sequences]' + CHAR(13) + 
										        'FROM [' + @Database_Name + '].[sys].[sequences])';

		DECLARE @SQL_Indexes NVARCHAR(MAX) = '(SELECT COUNT(DISTINCT [I].[name]) AS [Indexes]' + CHAR(13) + 
											  'FROM [' + @Database_Name + '].[sys].[tables] AS [T]' + CHAR(13) + 
											      'INNER JOIN [' + @Database_Name + '].[sys].[indexes] AS [I] ON [T].[object_id] = [I].[object_id]' + CHAR(13) + 
												  'INNER JOIN [' + @Database_Name + '].[sys].[index_columns] AS [IC] ON [I].[object_id] = [IC].[object_id]' + CHAR(13) + 
												  'INNER JOIN [' + @Database_Name + '].[sys].[all_columns] AS [AC] ON [T].[object_id] = [AC].[object_id]' + CHAR(13) + 
																											     'AND [IC].[column_id] = [AC].[column_id]'+ CHAR(13) + 
											  'WHERE [T].[is_ms_shipped] = 0' + CHAR(13) + 
											    'AND [I].[type_desc] <> ''HEAP'')';

		SET @SQL_FINAL = '(SELECT 1 as [N], ''Tables'' AS [Object],' + @SQL_Tables + 'AS [Count])' + CHAR(13) + 
						 'UNION' + CHAR(13) +  
						 '(SELECT 2, ''Views'',' + @SQL_Views + ')' + CHAR(13) + 
						 'UNION' + CHAR(13) + 
						 '(SELECT 3, ''Triggers'',' + @SQL_Triggers + ')' + CHAR(13) + 
						 'UNION' + CHAR(13) + 
						 '(SELECT 4, ''Functions'',' + @SQL_Functions + ')' + CHAR(13) + 
						 'UNION' + CHAR(13) + 
						 '(SELECT 5, ''Stored procedures'',' + @SQL_Stored_Procedures + ')' + CHAR(13) + 
						 'UNION' + CHAR(13) + 
						 '(SELECT 6, ''Sequences'',' + @SQL_Sequences + ')' + CHAR(13) + 
						 'UNION' + CHAR(13) + 
						 '(SELECT 7, ''Indexes'',' + @SQL_Indexes + ');'

		EXEC sp_executesql @SQL_FINAL;
	END

SET NOCOUNT OFF;