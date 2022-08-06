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
        DECLARE @SQL NVARCHAR(MAX) = 'SELECT [ST].[name] AS [Table_Name],' + CHAR(13) + 
                                            'COUNT([IT].[TABLE_NAME]) AS [Column_Count],' + CHAR(13) + 
                                            'SUM([PA].[rows]) AS [Record_Count]' + CHAR(13) + 
		                             'FROM [' + @Database_name + '].[sys].[tables] AS [ST]' + CHAR(13) + 
			                             'INNER JOIN [' + @Database_name + '].[INFORMATION_SCHEMA].[COLUMNS] AS [IT] ON [ST].[name] = [IT].[TABLE_NAME]' + CHAR(13) + 
			                             'INNER JOIN [' + @Database_name + '].[sys].[partitions] AS [PA] ON [ST].[object_id] = [PA].[object_id]' + CHAR(13) + 
		                             'WHERE [type] = ''U''' + CHAR(13) + 
		                             'GROUP BY [ST].[name]' + CHAR(13) + 
		                             'ORDER BY [ST].[name];';

        EXEC sp_executesql @SQL;        
    END
SET NOCOUNT OFF;