SET NOCOUNT ON;

USE [AdventureWorksDW2017];
GO

DECLARE @LoopCounter INT = 1,
        @Current_Table NVARCHAR(128),
        @Current_Record_Count BIGINT,
        @Current_PK_Count SMALLINT,
        @Current_FK_Count SMALLINT,
        @SQL NVARCHAR(MAX),
        @SQL_Param_Definition NVARCHAR(MAX);

DROP TABLE IF EXISTS #Report;

CREATE TABLE #Report
(
    [ID] INT NOT NULL IDENTITY(1, 1),
    [SHEMA] NVARCHAR(128) NOT NULL,
    [TABLE] NVARCHAR(128) NOT NULL,
    [COLUMNS] SMALLINT NOT NULL,
    [RECORDS] BIGINT,
    [PRIMARY_KEYS] SMALLINT,
    [FOREIGN_KEYS] SMALLINT
);

INSERT INTO #Report ([SHEMA], [TABLE], [COLUMNS])
SELECT DISTINCT SCHEMA_NAME([T].[schema_id]) AS [SHEMA], 
                [T].[name] AS [TABLE], 
                MAX([C].[ORDINAL_POSITION]) AS [COLUMNS]
FROM [sys].[tables] AS [T]
INNER JOIN [INFORMATION_SCHEMA].[COLUMNS] AS [C] ON [T].[name] = [C].[TABLE_NAME]
WHERE [T].[type] = 'U'
GROUP BY [T].[schema_id], [T].[name]
ORDER BY [SHEMA] ASC, [TABLE] ASC;

WHILE @LoopCounter <= (SELECT COUNT(*) FROM #Report)
    BEGIN
        SET @Current_Table = (SELECT [TABLE] FROM #Report WHERE [ID] = @LoopCounter);

        SET @SQL = N'SET @Current_Record_Count_OUT = (SELECT COUNT(*) FROM ' + @Current_Table + ')';
        SET @SQL_Param_Definition = N'@Current_Record_Count_OUT BIGINT OUTPUT';

        EXEC sp_executesql @SQL, @SQL_Param_Definition, @Current_Record_Count_OUT = @Current_Record_Count OUTPUT;

        SET @Current_PK_Count = (SELECT COUNT(*) FROM [sys].[key_constraints] WHERE OBJECT_NAME([parent_object_id]) = @Current_Table AND [type] = 'PK');
        SET @Current_FK_Count = (SELECT COUNT(*) FROM [sys].[foreign_key_columns] WHERE OBJECT_NAME([parent_object_id]) = @Current_Table);

        UPDATE #Report 
        SET [RECORDS] = @Current_Record_Count,
            [PRIMARY_KEYS] = @Current_PK_Count,
            [FOREIGN_KEYS] = @Current_FK_Count
        WHERE [TABLE] = @Current_Table;

        SET @LoopCounter = @LoopCounter + 1; 
    END

SELECT * FROM #Report;

SET NOCOUNT OFF;