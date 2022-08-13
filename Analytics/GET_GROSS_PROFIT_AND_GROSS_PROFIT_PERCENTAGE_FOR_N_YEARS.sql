USE [AdventureWorksDW2017];
GO

SET NOCOUNT ON;

DECLARE @SQL NVARCHAR(MAX);
DECLARE @YearList as NVARCHAR(1024) = '';
DECLARE @ColumnListColumnTotal as NVARCHAR(1024) = '';
DECLARE @ColumnListRowTotal as NVARCHAR(1024) = '';
DECLARE @ColumnListRowColumnTotal as NVARCHAR(1024) = '';
DECLARE @ColumnList as NVARCHAR(1024) = '';
DECLARE @ColumnListGP as NVARCHAR(1024) = '';
DECLARE @ColumnListGPP as NVARCHAR(1024) = '';
DECLARE @CurrentYear INT;
DECLARE @LoopCounter INT = 1;

DECLARE @Months TABLE (
    [Month_ID] INT NOT NULL IDENTITY(1,1),
    [Month] NVARCHAR(20) NOT NULL);

DECLARE @Years TABLE (
    [ID] INT NOT NULL IDENTITY(1,1),
    [Year] INT NOT NULL);

DROP TABLE IF EXISTS ##Report_Temp_Sales_Costs;
DROP TABLE IF EXISTS ##Report_Temp_GP;
DROP TABLE IF EXISTS ##Report_Temp_GPP;

INSERT INTO @Months ([Month])
VALUES ('January'),('February'),('March'),('April'),('May'),('June'),('July'),('August'),('September'),('October'),('November'),('December'),('TOTAL');

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
        SET @ColumnListColumnTotal = @ColumnListColumnTotal + 'COALESCE(ROUND(' + QUOTENAME(CAST(@CurrentYear as NVARCHAR(20))) + ',0),0)' + '+';
        SET @ColumnListRowTotal = @ColumnListRowTotal + 'SUM(' + QUOTENAME(CAST(@CurrentYear as NVARCHAR(20))) + ')' + ',';
        SET @ColumnListRowColumnTotal = @ColumnListRowColumnTotal + 'SUM(' + QUOTENAME(CAST(@CurrentYear as NVARCHAR(20))) + ')' + '+';
        SET @ColumnListGP = @ColumnListGP + '[Sales_Query].' + QUOTENAME(CAST(@CurrentYear as NVARCHAR(20))) + ' - ' + '[Costs_Query].' + QUOTENAME(CAST(@CurrentYear as NVARCHAR(20))) + ' AS ' + QUOTENAME(CAST(@CurrentYear as NVARCHAR(20))) + ',';
        SET @ColumnListGPP = @ColumnListGPP + 'IIF([Sales_Query].' + QUOTENAME(CAST(@CurrentYear as NVARCHAR(20))) + ' = 0, 0, [GP_Query].' + QUOTENAME(CAST(@CurrentYear as NVARCHAR(20))) + ' / [Sales_Query].' + QUOTENAME(CAST(@CurrentYear as NVARCHAR(20))) + ' * 100) AS ' + QUOTENAME(CAST(@CurrentYear as NVARCHAR(20))) + ',';
        SET @LoopCounter = @LoopCounter + 1;
    END

SET @YearList = LEFT(@YearList,LEN(@YearList) - 1);
SET @ColumnList = LEFT(@ColumnList,LEN(@ColumnList) - 1);
SET @ColumnListColumnTotal = LEFT(@ColumnListColumnTotal,LEN(@ColumnListColumnTotal) - 1);
SET @ColumnListRowTotal = LEFT(@ColumnListRowTotal,LEN(@ColumnListRowTotal) - 1);
SET @ColumnListRowColumnTotal = LEFT(@ColumnListRowColumnTotal,LEN(@ColumnListRowColumnTotal) - 1);
SET @ColumnListGP = LEFT(@ColumnListGP,LEN(@ColumnListGP) - 1);
SET @ColumnListGPP = LEFT(@ColumnListGPP,LEN(@ColumnListGPP) - 1);

SET @SQL = 'WITH CTE_Sales ([Month], ' + @YearList + ',[GRAND TOTAL])' + CHAR(13) + 
           'AS' + CHAR(13) + 
           '(' + CHAR(13) + 
               'SELECT [Month],' + @ColumnList + ',' + @ColumnListColumnTotal + 'AS [GRAND TOTAL]' + CHAR(13) + 
               'FROM (' + CHAR(13) + 
                   'SELECT [D].[EnglishMonthName] AS [Month],' + CHAR(13) + 
                          '[D].[CalendarYear] AS [Year],' + CHAR(13) + 
                          '[S].[SalesAmount] AS [Sales]' + CHAR(13) + 
                   'FROM [AdventureWorksDW2017].[dbo].[FactInternetSales] AS [S]' + CHAR(13) + 
                   'INNER JOIN [AdventureWorksDW2017].[dbo].[DimDate] AS [D] ON [S].[OrderDateKey] = [D].[DateKey]' + CHAR(13) + 
               ') AS [Orders]' + CHAR(13) + 
               'PIVOT (' + CHAR(13) + 
                   'SUM([Orders].[Sales])' + CHAR(13) + 
                   'FOR [Orders].[Year] IN (' + @YearList + ')' + CHAR(13) + 
               ') AS [Pivoted_Orders]' + CHAR(13) + 
           ')' + CHAR(13) + 
           '' + CHAR(13) + 
           'SELECT [Type], [Month], ' + @YearList + ',[GRAND TOTAL]' + CHAR(13) + 
           'INTO ##Report_Temp_Sales_Costs' + CHAR(13) + 
           'FROM' + CHAR(13) + 
               '((SELECT ''Sales'' AS [Type], [Month], ' + @YearList + ',[GRAND TOTAL]' + CHAR(13) + 
               'FROM CTE_Sales)' + CHAR(13) + 
               'UNION ALL' + CHAR(13) + 
               '(SELECT ''Sales'' AS [Type],''TOTAL'',' + @ColumnListRowTotal + ',' + @ColumnListRowColumnTotal + CHAR(13) + 
               'FROM CTE_Sales)) AS [SQ];';

EXEC sp_executesql @SQL;

SET @SQL = 'WITH CTE_Costs ([Month], ' + @YearList + ',[GRAND TOTAL])' + CHAR(13) + 
           'AS' + CHAR(13) + 
           '(' + CHAR(13) + 
               'SELECT [Month],' + @ColumnList + ',' + @ColumnListColumnTotal + 'AS [GRAND TOTAL]' + CHAR(13) + 
               'FROM (' + CHAR(13) + 
                   'SELECT [D].[EnglishMonthName] AS [Month],' + CHAR(13) + 
                          '[D].[CalendarYear] AS [Year],' + CHAR(13) + 
                          '[S].[TotalProductCost] AS [Cost]' + CHAR(13) + 
                   'FROM [AdventureWorksDW2017].[dbo].[FactInternetSales] AS [S]' + CHAR(13) + 
                   'INNER JOIN [AdventureWorksDW2017].[dbo].[DimDate] AS [D] ON [S].[OrderDateKey] = [D].[DateKey]' + CHAR(13) + 
               ') AS [Costs]' + CHAR(13) + 
               'PIVOT (' + CHAR(13) + 
                   'SUM([Costs].[Cost])' + CHAR(13) + 
                   'FOR [Costs].[Year] IN (' + @YearList + ')' + CHAR(13) + 
               ') AS [Pivoted_Costs]' + CHAR(13) + 
           ')' + CHAR(13) + 
           '' + CHAR(13) + 
           'INSERT INTO ##Report_Temp_Sales_Costs' + CHAR(13) + 
           'SELECT CAST([Type] AS NVARCHAR(32)), [Month], ' + @YearList + ',[GRAND TOTAL]' + CHAR(13) + 
           'FROM' + CHAR(13) + 
               '((SELECT ''Costs'' AS [Type], [Month], ' + @YearList + ',[GRAND TOTAL]' + CHAR(13) + 
               'FROM CTE_Costs)' + CHAR(13) + 
               'UNION' + CHAR(13) + 
               '(SELECT ''Costs'' AS [Type],''TOTAL'',' + @ColumnListRowTotal + ',' + @ColumnListRowColumnTotal + CHAR(13) + 
               'FROM CTE_Costs)) AS [SQ]';

EXEC sp_executesql @SQL;

SET @SQL = 'SELECT [Sales_Query].[Month], ' + CHAR(13) + 
                   @ColumnListGP + ', ' + CHAR(13) + 
                  '[Sales_Query].[GRAND TOTAL] - [Costs_Query].[GRAND TOTAL] AS [GRAND TOTAL]' + CHAR(13) + 
           'INTO ##Report_Temp_GP' + CHAR(13) + 
           'FROM ' + CHAR(13) + 
               '(SELECT [Month], ' + @YearList + ', [GRAND TOTAL]' + CHAR(13) + 
               'FROM ##Report_Temp_Sales_Costs' + CHAR(13) + 
               'WHERE [Type] = ''Sales'') AS [Sales_Query]' + CHAR(13) + 
           'INNER JOIN ' + CHAR(13) + 
               '(SELECT [Month], ' + @YearList + ', [GRAND TOTAL]' + CHAR(13) + 
               'FROM ##Report_Temp_Sales_Costs' + CHAR(13) + 
               'WHERE [Type] = ''Costs'') AS [Costs_Query] ON [Sales_Query].[Month] = [Costs_Query].[Month]'

EXEC sp_executesql @SQL;

SET @SQL = 'SELECT [GP_Query].[Month], ' + CHAR(13) + 
                   @ColumnListGPP + ', ' + CHAR(13) + 
                  'IIF([Sales_Query].[GRAND TOTAL] = 0,0,[GP_Query].[GRAND TOTAL] / [Sales_Query].[GRAND TOTAL] * 100) AS [GRAND TOTAL]' + CHAR(13) + 
           'INTO ##Report_Temp_GPP' + CHAR(13) + 
           'FROM ' + CHAR(13) + 
               '(SELECT [Month], ' + @YearList + ', [GRAND TOTAL]' + CHAR(13) + 
               'FROM ##Report_Temp_GP) AS [GP_Query]' + CHAR(13) + 
           'INNER JOIN ' + CHAR(13) + 
               '(SELECT [Month], ' + @YearList + ', [GRAND TOTAL]' + CHAR(13) + 
               'FROM ##Report_Temp_Sales_Costs' + CHAR(13) + 
               'WHERE [Type] = ''Sales'') AS [Sales_Query] ON [GP_Query].[Month] = [Sales_Query].[Month]';

EXEC sp_executesql @SQL;

SELECT [R].* 
FROM ##Report_Temp_GP AS [R]
INNER JOIN @Months AS [M] ON [R].[Month] = [M].[Month]
ORDER BY [M].[Month_ID] ASC;

SELECT [R].* 
FROM ##Report_Temp_GPP AS [R]
INNER JOIN @Months AS [M] ON [R].[Month] = [M].[Month]
ORDER BY [M].[Month_ID] ASC;

DROP TABLE ##Report_Temp_Sales_Costs;
DROP TABLE ##Report_Temp_GP;
DROP TABLE ##Report_Temp_GPP;

SET NOCOUNT OFF;