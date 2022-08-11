USE [AdventureWorksDW2017];
GO

SET NOCOUNT ON;

DROP TABLE IF EXISTS #Report_Sales;
DROP TABLE IF EXISTS #Report_Stats;

CREATE TABLE #Report_Sales (
    [ID] INT NOT NULL IDENTITY(1,1),
    [Month] NVARCHAR(16) NOT NULL,
    [Sales] DECIMAL(38,8) NOT NULL)

CREATE TABLE #Report_Stats (
    [ID] INT NOT NULL,
    [Statistic_Name] NVARCHAR(32) NOT NULL,
    [Statistic_Value] DECIMAL(38,4))

INSERT INTO #Report_Sales ([Month],[Sales])
SELECT [D].[EnglishMonthName] AS [Month],
       CAST(ROUND(SUM([S].[SalesAmount]),0) AS DECIMAL(38,4)) AS [Sales]
FROM [AdventureWorksDW2017].[dbo].[FactInternetSales] AS [S]
INNER JOIN [AdventureWorksDW2017].[dbo].[DimDate] AS [D] ON [S].[OrderDateKey] = [D].[DateKey]
WHERE [D].[CalendarYear] = 2013
GROUP BY [D].[EnglishMonthName]
ORDER BY [Sales] ASC;

DECLARE @CountAll DECIMAL(38,4);
DECLARE @CountData DECIMAL(38,4);
DECLARE @CountNulls DECIMAL(38,4);
DECLARE @CountDistinct DECIMAL(38,4);
DECLARE @Sum DECIMAL(38,4);
DECLARE @Min DECIMAL(38,4);
DECLARE @Max DECIMAL(38,4);
DECLARE @Range DECIMAL(38,4);
DECLARE @Average DECIMAL(38,4);
DECLARE @Median DECIMAL(38,4);
DECLARE @Variance DECIMAL(38,4);
DECLARE @StandardDeviation DECIMAL(38,4);
DECLARE @StandardErrorMean DECIMAL(38,4);
DECLARE @Skewness DECIMAL(38,4);
DECLARE @Kurtosis DECIMAL(38,4);

DECLARE @Mode TABLE (
    [ID] INT NOT NULL IDENTITY(1,1),
    [Mode] DECIMAL(38,4));

SET @CountAll = (SELECT COUNT(*) FROM #Report_Sales);
SET @CountData = (SELECT COUNT([Sales]) FROM #Report_Sales WHERE [Sales] IS NOT NULL);
SET @CountNulls = (SELECT COUNT([Sales]) FROM #Report_Sales WHERE [Sales] IS NULL);
SET @CountDistinct = (SELECT COUNT(DISTINCT [Sales]) FROM #Report_Sales WHERE [Sales] IS NOT NULL);
SET @Sum = (SELECT SUM([Sales]) FROM #Report_Sales WHERE [Sales] IS NOT NULL);
SET @Min = (SELECT Min([Sales]) FROM #Report_Sales WHERE [Sales] IS NOT NULL);
SET @Max = (SELECT Max([Sales]) FROM #Report_Sales WHERE [Sales] IS NOT NULL);
SET @Range = @Max - @Min;
SET @Average = (SELECT AVG([Sales]) FROM #Report_Sales WHERE [Sales] IS NOT NULL);

SET @Median = IIF(@CountData % 2 = 0,(SELECT SUM([SQ].[Sales]) / 2
                                      FROM
                                          (SELECT [Sales], ROW_NUMBER() OVER(ORDER BY [Sales]) AS [Row_ID]
                                           FROM #Report_Sales) AS [SQ]
                                           WHERE [SQ].[Row_ID] >= @CountData / 2
                                             AND [SQ].[Row_ID] <= (@CountData / 2) + 1),
                                     (SELECT [SQ].[Sales]
                                      FROM
                                          (SELECT [Sales], ROW_NUMBER() OVER(ORDER BY [Sales]) AS [Row_ID]
                                           FROM #Report_Sales) AS [SQ]
                                           WHERE [SQ].[Row_ID] = (@CountData / 2) + 1));

IF (SELECT COUNT([SQ].[Sales])
    FROM
       (SELECT [Sales],
               COUNT([Sales]) AS [Mode_Count]
        FROM #Report_Sales
        WHERE [Sales] IS NOT NULL
        GROUP BY [Sales]
        HAVING COUNT([Sales]) > 1) AS [SQ]) > 0
    BEGIN
        INSERT INTO @Mode ([Mode])
        SELECT [Sales]
        FROM #Report_Sales
        WHERE [Sales] IS NOT NULL
        GROUP BY [Sales]
        HAVING COUNT([Sales]) > 1;
    END
ELSE
    BEGIN
        INSERT INTO @Mode ([Mode])
        VALUES (NULL)
    END

SET @Variance = (SELECT VARP([Sales]) FROM #Report_Sales WHERE [Sales] IS NOT NULL);
SET @StandardDeviation = (SELECT STDEVP([Sales]) FROM #Report_Sales WHERE [Sales] IS NOT NULL);
SET @StandardErrorMean = @StandardDeviation / SQRT(@CountData);

SET @Skewness = (SELECT (1.0 / @CountData) * SUM(POWER(([Sales] - @Average) / @StandardDeviation,3)) 
                 FROM #Report_Sales
                 WHERE [Sales] IS NOT NULL);

SET @Kurtosis = (SELECT (SUM(POWER(1.0*[Sales],4)) - 4 * SUM(POWER(1.0*[Sales],3)) * AVG(1.0*[Sales]) + 6 * SUM(POWER(1.0*[Sales],2)) * POWER(AVG(1.0*[Sales]),2) - 4 * SUM(1.0*[Sales]) * POWER(AVG(1.0*[Sales]),3) + @CountData * POWER(AVG(1.0*[Sales]),4))
                         / POWER(STDEV(1.0*[Sales]),4) * COUNT(1.0*[Sales]) * (COUNT(1.0*[Sales]) + 1) / (COUNT(1.0*[Sales]) - 1) / (COUNT(1.0*[Sales]) - 2) / (COUNT(1.0*[Sales]) - 3)
                         - 3.0 * POWER((COUNT(1.0*[Sales]) - 1),2) / (COUNT(1.0*[Sales]) - 2) / (COUNT(1.0*[Sales]) - 3)
                 FROM #Report_Sales
                 WHERE [Sales] IS NOT NULL);

INSERT INTO #Report_Stats ([ID],[Statistic_Name],[Statistic_Value])
(SELECT 1 AS [ID], 'Records' AS [Statistic_Name], @CountAll AS [Statistic_Value])
UNION
(SELECT 2 AS [ID], 'Data' AS [Statistic_Name], @CountData AS [Statistic_Value])
UNION
(SELECT 3 AS [ID], 'NULLs' AS [Statistic_Name], @CountNulls AS [Statistic_Value])
UNION
(SELECT 4 AS [ID], 'Distinct' AS [Statistic_Name], @CountDistinct AS [Statistic_Value])
UNION
(SELECT 5 AS [ID], 'Sum' AS [Statistic_Name], @Sum AS [Statistic_Value])
UNION
(SELECT 6 AS [ID], 'Min' AS [Statistic_Name], @Min AS [Statistic_Value])
UNION
(SELECT 7 AS [ID], 'Max' AS [Statistic_Name], @Max AS [Statistic_Value])
UNION
(SELECT 8 AS [ID], 'Range' AS [Statistic_Name], @Range AS [Statistic_Value])
UNION
(SELECT 9 AS [ID], 'Average' AS [Statistic_Name], @Average AS [Statistic_Value])
UNION
(SELECT 10 AS [ID], 'Median' AS [Statistic_Name], @Median AS [Statistic_Value])

IF ((SELECT COUNT(*) FROM @Mode) > 1)
    BEGIN
        INSERT INTO #Report_Stats ([ID],[Statistic_Name],[Statistic_Value])
        SELECT [ID] + (SELECT MAX([ID]) FROM #Report_Stats), 'Mode ' + CAST([ID] AS NVARCHAR(4)),[Mode]
        FROM @Mode;
    END
ELSE
    BEGIN
        INSERT INTO #Report_Stats ([ID],[Statistic_Name],[Statistic_Value])
        SELECT [ID] + (SELECT MAX([ID]) FROM #Report_Stats), 'Mode',[Mode]
        FROM @Mode;
    END

INSERT INTO #Report_Stats ([ID],[Statistic_Name],[Statistic_Value])
(SELECT 1 + (SELECT MAX([ID]) FROM #Report_Stats) AS [ID], 'Variance' AS [Statistic_Name], @Variance AS [Statistic_Value])
UNION
(SELECT 2 + (SELECT MAX([ID]) FROM #Report_Stats) AS [ID], 'Standard deviation' AS [Statistic_Name], @StandardDeviation AS [Statistic_Value])
UNION
(SELECT 3 + (SELECT MAX([ID]) FROM #Report_Stats) AS [ID], 'Standard error of mean' AS [Statistic_Name], @StandardErrorMean AS [Statistic_Value])
UNION
(SELECT 4 + (SELECT MAX([ID]) FROM #Report_Stats) AS [ID], 'Skewness' AS [Statistic_Name], @Skewness AS [Statistic_Value])
UNION
(SELECT 5 + (SELECT MAX([ID]) FROM #Report_Stats) AS [ID], 'Kurtosis' AS [Statistic_Name], @Kurtosis AS [Statistic_Value])

SET NOCOUNT OFF;

-- SELECT * FROM #Report_Stats;