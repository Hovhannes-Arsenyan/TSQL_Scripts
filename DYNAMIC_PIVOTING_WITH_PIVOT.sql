USE [AdventureWorksDW2017];
GO

DECLARE @SQL NVARCHAR(MAX);
DECLARE @YearList as NVARCHAR(1024) = '';
DECLARE @ColumnList as NVARCHAR(1024) = '';
DECLARE @CurrentYear INT;
DECLARE @LoopCounter INT = 1;

DECLARE @Years TABLE (
	[ID] INT NOT NULL IDENTITY(1,1),
	[Year] INT NOT NULL);

INSERT INTO @Years ([Year])
SELECT DISTINCT [D].[CalendarYear] AS [Year]
FROM [AdventureWorksDW2017].[dbo].[FactInternetSales] AS [S]
INNER JOIN [AdventureWorksDW2017].[dbo].[DimDate] AS [D] ON [S].[OrderDateKey] = [D].[DateKey]
ORDER BY [D].[CalendarYear] ASC;

WHILE @LoopCounter <= (SELECT COUNT(*) FROM @Years)
    BEGIN
        SET @CurrentYear = (SELECT [Year] FROM @Years WHERE [ID] = @LoopCounter);
        SET @YearList = @YearList + QUOTENAME(CAST(@CurrentYear as NVARCHAR(20))) + ',';
        SET @ColumnList = @ColumnList + 'COALESCE(ROUND(' + QUOTENAME(CAST(@CurrentYear as NVARCHAR(20))) + ',0),0) AS ' + QUOTENAME(CAST(@CurrentYear as NVARCHAR(20))) + ',';
        SET @LoopCounter = @LoopCounter + 1
    END

SET @YearList = LEFT(@YearList,LEN(@YearList) - 1);
SET @ColumnList = LEFT(@ColumnList,LEN(@ColumnList) - 1);

SET @SQL = 'SELECT [Month],' + @ColumnList + CHAR(13) + 
           'FROM (' + CHAR(13) + 
           '    SELECT [D].[EnglishMonthName] AS [Month],' + CHAR(13) + 
           '           [D].[CalendarYear] AS [Year],' + CHAR(13) + 
           '           [S].[SalesAmount] AS [Sales]' + CHAR(13) + 
           '    FROM [AdventureWorksDW2017].[dbo].[FactInternetSales] AS [S]' + CHAR(13) + 
           '    INNER JOIN [AdventureWorksDW2017].[dbo].[DimDate] AS [D] ON [S].[OrderDateKey] = [D].[DateKey]' + CHAR(13) + 
           ') AS [Orders]' + CHAR(13) + 
           'PIVOT (' + CHAR(13) + 
           '    SUM([Orders].[Sales])' + CHAR(13) + 
           '    FOR [Orders].[Year] IN (' + @YearList + ')' + CHAR(13) + 
           ') AS [Pivoted_Orders]' + CHAR(13) + 
           'ORDER BY CASE [Month]' + CHAR(13) + 
           '              WHEN ''January'' THEN 1' + CHAR(13) + 
           '              WHEN ''February'' THEN 2' + CHAR(13) + 
           '              WHEN ''March'' THEN 3' + CHAR(13) + 
           '              WHEN ''April'' THEN 4' + CHAR(13) + 
           '              WHEN ''May'' THEN 5' + CHAR(13) + 
           '              WHEN ''June'' THEN 6' + CHAR(13) + 
           '              WHEN ''July'' THEN 7' + CHAR(13) + 
           '              WHEN ''August'' THEN 8' + CHAR(13) + 
           '              WHEN ''September'' THEN 9' + CHAR(13) + 
           '              WHEN ''October'' THEN 10' + CHAR(13) + 
           '              WHEN ''November'' THEN 11' + CHAR(13) + 
           '              ELSE 12' + CHAR(13) + 
           '         END ASC;'

EXEC sp_executesql @SQL;