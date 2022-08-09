SET NOCOUNT ON;
GO

USE [AdventureWorksDW2017];
GO

DECLARE @SQL NVARCHAR(MAX) = '';
DECLARE @CurrentYear INT;
DECLARE @CurrentMonth NVARCHAR(20);
DECLARE @LoopCounter INT = 1;
DECLARE @InnerLoopCounter INT = 1;
DECLARE @OuterLoopCounter INT = 1;
DECLARE @CurrentAmount MONEY;
DECLARE @AccumulatedAmount MONEY = 0;

IF OBJECT_ID('tempdb..#Report') IS NOT NULL
    DROP TABLE #Report;

CREATE TABLE #Report (
    [Month] NVARCHAR(20) NOT NULL);

DECLARE @Years TABLE (
    [Year_ID] INT NOT NULL IDENTITY(1,1),
    [Year] INT NOT NULL);

DECLARE @Months TABLE (
    [Month_ID] INT NOT NULL IDENTITY(1,1),
    [Month] NVARCHAR(20) NOT NULL);

INSERT INTO @Years ([Year])
SELECT DISTINCT [D].[CalendarYear] AS [Year]
FROM [AdventureWorksDW2017].[dbo].[FactInternetSales] AS [S]
INNER JOIN [AdventureWorksDW2017].[dbo].[DimDate] AS [D] ON [S].[OrderDateKey] = [D].[DateKey]
ORDER BY [D].[CalendarYear] ASC;

INSERT INTO @Months ([Month])
VALUES ('January'),('February'),('March'),('April'),('May'),('June'),('July'),('August'),('September'),('October'),('November'),('December');

INSERT INTO #Report ([Month])
SELECT [Month]
FROM @Months;

WHILE @LoopCounter <= (SELECT COUNT(*) FROM @Years)
    BEGIN
        SET @CurrentYear = (SELECT [Year] FROM @Years WHERE [Year_ID] = @LoopCounter);

        SET @SQL = 'ALTER TABLE #Report' + CHAR(13) + 
                       'ADD Y_' + CAST(@CurrentYear AS NVARCHAR(4)) + ' MONEY;';

        EXEC sp_executesql @SQL;

        SET @LoopCounter = @LoopCounter + 1
    END

ALTER TABLE #Report
    ADD C_TOTAL MONEY;

INSERT INTO #Report ([Month])
VALUES ('R_TOTAL');

WHILE @OuterLoopCounter <= (SELECT COUNT(*) + 1 FROM @Months)
    BEGIN
        IF @OuterLoopCounter < 13
            SET @CurrentMonth = (SELECT [Month] FROM @Months WHERE [Month_ID] = @OuterLoopCounter);
        ELSE
            SET @CurrentMonth = 'R_TOTAL';

        SET @InnerLoopCounter = 0;

        WHILE @InnerLoopCounter <= (SELECT COUNT(*) FROM @Years)
            BEGIN
                SET @CurrentYear = (SELECT [Year] FROM @Years WHERE [Year_ID] = @InnerLoopCounter);

                IF @OuterLoopCounter < 13
                    SELECT @CurrentAmount = COALESCE(ROUND(SUM([S].[SalesAmount]),0),0)
                    FROM [AdventureWorksDW2017].[dbo].[FactInternetSales] AS [S]
                    INNER JOIN [AdventureWorksDW2017].[dbo].[DimDate] AS [D] ON [S].[OrderDateKey] = [D].[DateKey]
                    WHERE [D].[EnglishMonthName] = @CurrentMonth
                      AND [D].[CalendarYear] = @CurrentYear;
                ELSE
                    SELECT @CurrentAmount = COALESCE(ROUND(SUM([S].[SalesAmount]),0),0)
                    FROM [AdventureWorksDW2017].[dbo].[FactInternetSales] AS [S]
                    INNER JOIN [AdventureWorksDW2017].[dbo].[DimDate] AS [D] ON [S].[OrderDateKey] = [D].[DateKey]
                    WHERE [D].[CalendarYear] = @CurrentYear;

                SET @SQL = 'UPDATE #Report' + CHAR(13) + 
                           'SET Y_' + CAST(@CurrentYear AS NVARCHAR(4)) + ' = ' + CAST(@CurrentAmount AS NVARCHAR(32)) + CHAR(13) + 
                           'WHERE [Month] = ''' + @CurrentMonth + ''';';

                EXEC sp_executesql @SQL;

                SET @AccumulatedAmount = @AccumulatedAmount + @CurrentAmount;
                SET @InnerLoopCounter = @InnerLoopCounter + 1
            END
		
        UPDATE #Report
        SET [C_TOTAL] = @AccumulatedAmount
        WHERE [Month] = @CurrentMonth;

        SET @AccumulatedAmount = 0;
        SET @OuterLoopCounter = @OuterLoopCounter + 1;
    END

SELECT *
FROM #Report;

SET NOCOUNT OFF;