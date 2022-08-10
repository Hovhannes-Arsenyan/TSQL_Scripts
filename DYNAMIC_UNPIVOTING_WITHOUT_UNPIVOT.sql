SET NOCOUNT ON;
GO

IF OBJECT_ID('tempdb..#Report') IS NOT NULL
    DROP TABLE #Report;

IF OBJECT_ID('tempdb..#Report_Unpivoted') IS NOT NULL
    DROP TABLE #Report_Unpivoted;

CREATE TABLE #Report (
    [Month] NVARCHAR(20) NOT NULL,
    [Y_2010] MONEY NOT NULL,
    [Y_2011] MONEY NOT NULL,
    [Y_2012] MONEY NOT NULL,
    [Y_2013] MONEY NOT NULL,
    [Y_2014] MONEY NOT NULL,
    [C_TOTAL] MONEY NOT NULL);

INSERT INTO #Report ([Month],[Y_2010],[Y_2011],[Y_2012],[Y_2013],[Y_2014],[C_TOTAL])
VALUES ('January',0,469824,495364,857690,45695,1868573),
       ('February',0,466335,506994,771349,0,1744678),
       ('March',0,485199,373483,1049907,0,1908589),
       ('April',0,502074,400336,1046023,0,1948433),
       ('May',0,561681,358878,1284593,0,2205152),
       ('June',0,737840,555160,1643178,0,2936178),
       ('July',0,596747,444558,1371676,0,2412981),
       ('August',0,614558,523917,1551066,0,2689541),
       ('September',0,603083,486177,1447496,0,2536756),
       ('October',0,708208,535159,1673293,0,2916660),
       ('November',0,660546,537956,1780920,0,2979422),
       ('December',43421,669432,624502,1874360,0,3211715),
       ('R_TOTAL',43421,7075526,5842485,16351550,45695,29358677);

DECLARE @SQL NVARCHAR(MAX) = '';
DECLARE @LoopCounter INT = 1;
DECLARE @CurrentColumnName NVARCHAR(16);

CREATE TABLE #Report_Unpivoted (
    [ID] INT NOT NULL IDENTITY(1,1),
    [Year] NVARCHAR(16) NOT NULL,
    [Month] NVARCHAR(16) NOT NULL,
    [Value] MONEY NOT NULL)

WHILE @LoopCounter <= (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id = OBJECT_ID('tempdb..#Report') AND [name] <> 'Month')
    BEGIN
        SET @CurrentColumnName = (SELECT [Column_Name]
                                  FROM
                                      (SELECT ROW_NUMBER() OVER(ORDER BY [name] ASC) AS [ID],
                                              [name] AS [Column_Name] 
                                       FROM tempdb.sys.columns 
                                       WHERE object_id = OBJECT_ID('tempdb..#Report') 
                                         AND [name] <> 'Month') AS [SQ]
                                  WHERE [ID] = @LoopCounter);

        SET @SQL = 'INSERT INTO #Report_Unpivoted ([Year],[Month],[Value])' + CHAR(13) + 
                   'SELECT ''' + @CurrentColumnName + ''' AS [Year],[Month],' + @CurrentColumnName + ' AS [Value]' + CHAR(13) + 
                   'FROM #Report;';

        EXEC sp_executesql @SQL;

        SET @LoopCounter = @LoopCounter + 1;
    END

SET NOCOUNT OFF;
GO

-- SELECT * FROM #Report_Unpivoted;