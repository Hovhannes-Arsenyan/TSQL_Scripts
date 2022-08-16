SET NOCOUNT ON;

Use AdventureWorksDW2017;
GO

DECLARE @SQL NVARCHAR(MAX);
DECLARE @YearList as NVARCHAR(1024) = '';
DECLARE @ColumnList as NVARCHAR(1024) = '';
DECLARE @CurrentYear INT;
DECLARE @LoopCounter INT = 1;

DECLARE @Years TABLE (
    [ID] INT NOT NULL IDENTITY(1,1),
    [Year] INT NOT NULL);

DROP TABLE IF EXISTS #Months;
DROP TABLE IF EXISTS #Report;

CREATE TABLE #Months (
    [Month_ID] INT NOT NULL,
    [Month] NVARCHAR(20) NOT NULL);

CREATE TABLE #Report (
    [Month] NVARCHAR(16) NOT NULL,
    [Year] NVARCHAR(4) NOT NULL,
    [Seasonal Percentage] DECIMAL(5,2));

INSERT INTO #Months ([Month_ID],[Month])
VALUES (1,'January'),(2,'February'),(3,'March'),(4,'April'),(5,'May'),(6,'June'),(7,'July'),(8,'August'),(9,'September'),(10,'October'),(11,'November'),(12,'December')

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

        SET @LoopCounter = @LoopCounter + 1;
    End

SET @YearList = LEFT(@YearList,LEN(@YearList) - 1);
SET @ColumnList = LEFT(@ColumnList,LEN(@ColumnList) - 1);

WITH CTE_Temp ([Month], [Year], [Gross Profit])
AS
(
    SELECT [D].[EnglishMonthName] AS [Month],
           [D].[CalendarYear] AS [Year],
           SUM([S].[SalesAmount] - [S].[TotalProductCost]) AS [Gross Profit]
    FROM [AdventureWorksDW2017].[dbo].[FactInternetSales] AS [S]
    INNER JOIN [AdventureWorksDW2017].[dbo].[DimDate] AS [D] ON [S].[OrderDateKey] = [D].[DateKey]
    GROUP BY [D].[CalendarYear], [D].[EnglishMonthName]
)
INSERT INTO #Report ([Month], [Year], [Seasonal Percentage])
SELECT [Month], [Year],
       [Gross Profit] / SUM([Gross Profit]) OVER (PARTITION BY [Year] ORDER BY [YEAR] ASC) * 100 AS [Seasonal Percentage]
FROM CTE_Temp;

SET @SQL = 'SELECT [SQ].*' + CHAR(13) + 
           'FROM ' + CHAR(13) + 
               '(SELECT [Month],' + @ColumnList + CHAR(13) + 
               'FROM (' + CHAR(13) + 
                   'SELECT [Month],' + CHAR(13) + 
                          '[Year],' + CHAR(13) + 
                          '[Seasonal Percentage]' + CHAR(13) + 
                   'FROM #Report' + CHAR(13) + 
               ') AS [Data]' + CHAR(13) + 
               'PIVOT (' + CHAR(13) + 
                   'SUM([Data].[Seasonal Percentage])' + CHAR(13) + 
                   'FOR [Data].[Year] IN (' + @YearList + ')' + CHAR(13) + 
               ') AS [Pivoted_Orders]) AS [SQ]' + CHAR(13) + 
           'INNER JOIN #Months AS [M] ON [SQ].[Month] = [M].[Month]' + CHAR(13) + 
           'ORDER BY [M].[Month_ID] ASC'

EXEC sp_executesql @SQL;

SET NOCOUNT OFF;