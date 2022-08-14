USE AdventureWorksDW2017;
GO

SET NOCOUNT ON;

DECLARE @SQL AS NVARCHAR(MAX);
DECLARE @Bin_Width SMALLINT = 10;
DECLARE @Bin_Step INT = 500;
DECLARE @Loop_Counter_Outer SMALLINT = 1;
DECLARE @Loop_Counter_Inner SMALLINT = 1;
DECLARE @Current_Year SMALLINT;
DECLARE @Current_Bin_Start INT;
DECLARE @Current_Bin_End INT;
DECLARE @Current_Bin_Text NVARCHAR(128);
DECLARE @Current_Count INT;
DECLARE @Year_List NVARCHAR(MAX) = '';
DECLARE @Column_List NVARCHAR(MAX) = '';

DECLARE @Years TABLE 
(
    [ID] INT NOT NULL IDENTITY(1, 1),
    [Year] INT NOT NULL
);

DROP TABLE IF EXISTS ##Report;

IF @Bin_Width * @Bin_Step < (SELECT MAX([SalesAmount])
                             FROM [AdventureWorksDW2017].[dbo].[FactInternetSales])
    BEGIN
        THROW 50000, 'The maximum sales value in the dataset is beyond the observation range. Adjust bin parameters.', 1;
    END

INSERT INTO @Years ([Year])
SELECT DISTINCT [D].[CalendarYear] AS [Year]
FROM [AdventureWorksDW2017].[dbo].[FactInternetSales] AS [S]
INNER JOIN [AdventureWorksDW2017].[dbo].[DimDate] AS [D] ON [S].[OrderDateKey] = [D].[DateKey]
ORDER BY [D].[CalendarYear];

CREATE TABLE ##Report 
(
    [ID] INT NOT NULL IDENTITY(1, 1),
    [Year] SMALLINT NOT NULL,
    [Bin] NVARCHAR(128) NOT NULL,
    [Bin_Start] INT NOT NULL,
    [Bin_End] INT NOT NULL,
    [Count] INT NOT NULL
);

WHILE @Loop_Counter_Outer <= (SELECT COUNT(*) FROM @Years)
    BEGIN
        SET @Current_Year = (SELECT [Year] FROM @Years WHERE [ID] = @Loop_Counter_Outer);

        WHILE @Loop_Counter_Inner <= @Bin_Width
            BEGIN
                SET @Current_Bin_Start = @Loop_Counter_Inner * @Bin_Step - @Bin_Step;
                SET @Current_Bin_End = @Loop_Counter_Inner * @Bin_Step;
                SET @Current_Bin_Text = '[' + CAST(@Current_Bin_Start AS NVARCHAR(128)) + ' - ' + CAST(@Current_Bin_End AS NVARCHAR(128)) + ')';

                SET @Current_Count = (SELECT COUNT([S].[SalesAmount])
                                      FROM [AdventureWorksDW2017].[dbo].[FactInternetSales] AS [S]
                                      INNER JOIN [AdventureWorksDW2017].[dbo].[DimDate] AS [D] ON [S].[OrderDateKey] = [D].[DateKey]
                                      WHERE [D].[CalendarYear] = @Current_Year
                                        AND ([S].[SalesAmount] >= @Current_Bin_Start
                                        AND [S].[SalesAmount] < @Current_Bin_End));

                INSERT INTO ##Report ([Year], [Bin], [Bin_Start], [Bin_End], [Count])
                VALUES (@Current_Year, @Current_Bin_Text, @Current_Bin_Start, @Current_Bin_End, @Current_Count);

                SET @Loop_Counter_Inner = @Loop_Counter_Inner + 1;
            END
        SET @Year_List = @Year_List + QUOTENAME(CAST(@Current_Year as NVARCHAR(20))) + ',';
        SET @Column_List = @Column_List + 'COALESCE(' + QUOTENAME(CAST(@Current_Year as NVARCHAR(20))) + ',0) AS ' + QUOTENAME(CAST(@Current_Year as NVARCHAR(20))) + ',';

        SET @Loop_Counter_Inner = 1;
        SET @Loop_Counter_Outer = @Loop_Counter_Outer + 1;
    END

SET @Year_List = LEFT(@Year_List,LEN(@Year_List) - 1);
SET @Column_List = LEFT(@Column_List,LEN(@Column_List) - 1);

SET @SQL = 'SELECT COUNT(*) OVER(ORDER BY [Bin_Start]) AS [N], ' + CHAR(13) + 
                  '[Bin], ' + CHAR(13) + 
                  '[Bin_Start], ' + CHAR(13) + 
                   '[Bin_End], ' + CHAR(13) + 
                   @Column_List + CHAR(13) + 
           'FROM (' + CHAR(13) + 
               'SELECT [Year], '  + CHAR(13) + 
                      '[Bin], ' + CHAR(13) + 
                      '[Bin_Start], ' + CHAR(13) + 
                      '[Bin_End], ' + CHAR(13) + 
                      '[Count]' + CHAR(13) + 
               'FROM ##Report' + CHAR(13) + 
           ') AS [Counts]' + CHAR(13) + 
           'PIVOT (' + CHAR(13) + 
               'SUM([Count])' + CHAR(13) + 
               'FOR [Year] IN (' + @Year_List + ')' + CHAR(13) + 
           ') AS [Pivoted_Counts]' + CHAR(13) + 
           'ORDER BY [N] ASC;';

EXEC sp_executesql @SQL;

DROP TABLE ##Report;

SET NOCOUNT OFF;