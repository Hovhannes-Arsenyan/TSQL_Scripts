SET NOCOUNT ON;

USE [AdventureWorksDW2017];
GO

DECLARE @SQL NVARCHAR(MAX);
DECLARE @YearList as NVARCHAR(1024) = '';
DECLARE @ColumnList as NVARCHAR(1024) = '';
DECLARE @ColumnList_Rank as NVARCHAR(1024) = '';
DECLARE @ColumnList_Rank_Pivoted as NVARCHAR(1024) = '';
DECLARE @CurrentYear INT;
DECLARE @LoopCounter INT = 1;

DECLARE @Years TABLE (
    [ID] INT NOT NULL IDENTITY(1,1),
    [Year] INT NOT NULL);

DROP TABLE IF EXISTS #Temp_Report;

CREATE TABLE #Temp_Report
(
    [Product category] NVARCHAR(255) NOT NULL,
    [Year] SMALLINT NOT NULL,
    [Gross profit] MONEY NOT NULL,
    [Rank] TINYINT NOT NULL
)

INSERT INTO @Years ([Year])
SELECT DISTINCT [D].[CalendarYear] AS [Year]
FROM [AdventureWorksDW2017].[dbo].[FactInternetSales] AS [S]
INNER JOIN [AdventureWorksDW2017].[dbo].[DimDate] AS [D] ON [S].[OrderDateKey] = [D].[DateKey]
ORDER BY [D].[CalendarYear] ASC;

WHILE @LoopCounter <= (SELECT COUNT(*) FROM @Years)
    BEGIN
        SET @CurrentYear = (SELECT [Year] FROM @Years WHERE [ID] = @LoopCounter);
        SET @YearList = @YearList + QUOTENAME(CAST(@CurrentYear as NVARCHAR(20))) + ',';
        SET @ColumnList = @ColumnList + 'COALESCE(' + QUOTENAME(CAST(@CurrentYear as NVARCHAR(20))) + ',0) AS ' + QUOTENAME(CAST(@CurrentYear as NVARCHAR(20))) + ',';
        SET @ColumnList_Rank = @ColumnList_Rank + 'COALESCE('+ QUOTENAME(CAST(@CurrentYear as NVARCHAR(20))) + ',0) AS ' + QUOTENAME('R_' + CAST(@CurrentYear as NVARCHAR(20))) + ',';
        SET @ColumnList_Rank_Pivoted = @ColumnList_Rank_Pivoted + '[R].' + QUOTENAME('R_' + CAST(@CurrentYear as NVARCHAR(20))) + ',';

        SET @LoopCounter = @LoopCounter + 1;
    End

SET @YearList = LEFT(@YearList,LEN(@YearList) - 1);
SET @ColumnList = LEFT(@ColumnList,LEN(@ColumnList) - 1);
SET @ColumnList_Rank = LEFT(@ColumnList_Rank,LEN(@ColumnList_Rank) - 1);
SET @ColumnList_Rank_Pivoted = LEFT(@ColumnList_Rank_Pivoted,LEN(@ColumnList_Rank_Pivoted) - 1);

INSERT INTO #Temp_Report ([Product category], [Year], [Gross profit], [Rank])
SELECT [SQ2].[Product category], [SQ2].[Year], ROUND([SQ2].[Gross profit],0) AS [Gross profit],
       RANK() OVER (PARTITION BY [Year] ORDER BY [Gross profit] DESC) AS [Rank]
FROM
    (SELECT [SQ1].[Product category], [SQ1].[Year], SUM([SQ1].[Gross profit]) AS [Gross profit]
    FROM
        ((SELECT 'Internet sales' AS [Business line],
                [PC].[EnglishProductCategoryName] AS [Product category],
                [D].[CalendarYear] AS [Year],
                SUM(([S].[SalesAmount] - [S].[TotalProductCost]) * [CR].[EndOfDayRate]) AS [Gross profit]
        FROM [AdventureWorksDW2017].[dbo].[FactInternetSales] AS [S]
        INNER JOIN [AdventureWorksDW2017].[dbo].[DimProduct] AS [P] ON [S].[ProductKey] = [P].[ProductKey]
        INNER JOIN [AdventureWorksDW2017].[dbo].[DimProductSubcategory] AS [PSC] ON [P].[ProductSubcategoryKey] = [PSC].ProductSubcategoryKey
        INNER JOIN [AdventureWorksDW2017].[dbo].[DimProductCategory] AS [PC] ON [PSC].[ProductCategoryKey] = [PC].[ProductCategoryKey]
        INNER JOIN [AdventureWorksDW2017].[dbo].[DimDate] AS [D] ON [S].[OrderDateKey] = [D].[DateKey]
        INNER JOIN [AdventureWorksDW2017].[dbo].[DimCurrency] AS [C] ON [S].[CurrencyKey] = [C].[CurrencyKey]
        INNER JOIN [AdventureWorksDW2017].[dbo].[FactCurrencyRate] AS [CR] ON [C].[CurrencyKey] = [CR].[CurrencyKey]
        WHERE [CR].DateKey = [S].[OrderDateKey]
        GROUP BY [PC].[EnglishProductCategoryName], [D].[CalendarYear])
        UNION ALL
        (SELECT 'Reseller sales' AS [Business line],
                [PC].[EnglishProductCategoryName] AS [Product category],
                [D].[CalendarYear] AS [Year],
                SUM(([S].[SalesAmount] - [S].[TotalProductCost]) * [CR].[EndOfDayRate]) AS [Gross profit]
        FROM [AdventureWorksDW2017].[dbo].[FactResellerSales] AS [S]
        INNER JOIN [AdventureWorksDW2017].[dbo].[DimProduct] AS [P] ON [S].[ProductKey] = [P].[ProductKey]
        INNER JOIN [AdventureWorksDW2017].[dbo].[DimProductSubcategory] AS [PSC] ON [P].[ProductSubcategoryKey] = [PSC].ProductSubcategoryKey
        INNER JOIN [AdventureWorksDW2017].[dbo].[DimProductCategory] AS [PC] ON [PSC].[ProductCategoryKey] = [PC].[ProductCategoryKey]
        INNER JOIN [AdventureWorksDW2017].[dbo].[DimDate] AS [D] ON [S].[OrderDateKey] = [D].[DateKey]
        INNER JOIN [AdventureWorksDW2017].[dbo].[DimCurrency] AS [C] ON [S].[CurrencyKey] = [C].[CurrencyKey]
        INNER JOIN [AdventureWorksDW2017].[dbo].[FactCurrencyRate] AS [CR] ON [C].[CurrencyKey] = [CR].[CurrencyKey]
        WHERE [CR].DateKey = [S].[OrderDateKey]
        GROUP BY [PC].[EnglishProductCategoryName], [D].[CalendarYear])) AS [SQ1]
    GROUP BY [SQ1].[Product category], [SQ1].[Year]) AS [SQ2]

SET @SQL = 'SELECT [GP].*, ' + @ColumnList_Rank_Pivoted + CHAR(13) + 
           'FROM'+ CHAR(13) + 
               '(SELECT [Product category],' + @ColumnList + CHAR(13) + 
               'FROM' + CHAR(13) + 
                   '(SELECT [Product category], [Year], [Gross profit]' + CHAR(13) + 
                   'FROM #Temp_Report) AS [Data]' + CHAR(13) + 
               'PIVOT' + CHAR(13) + 
                   '(SUM([Gross profit])' + CHAR(13) + 
                   'FOR [Year] IN (' + @YearList + ')' + CHAR(13) + 
               ') AS [Pivoted_Gross_profit]) AS [GP]' + CHAR(13) + 
           'INNER JOIN (SELECT [Product category],' + @ColumnList_Rank + CHAR(13) + 
                       'FROM' + CHAR(13) + 
                           '(SELECT [Product category], [Year], [Rank]' + CHAR(13) + 
                           'FROM #Temp_Report) AS [Data]' + CHAR(13) + 
                       'PIVOT' + CHAR(13) + 
                           '(SUM([Rank])' + CHAR(13) + 
                           'FOR [Year] IN (' + @YearList + ')' + CHAR(13) + 
                       ') AS [Pivoted_Rank]) AS [R] ON [GP].[Product category] = [R].[Product category]'

EXEC sp_executesql @SQL;

DROP TABLE #Temp_Report;

SET NOCOUNT OFF;