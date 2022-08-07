SET NOCOUNT ON;

DECLARE @Start_Date DATE = '2018-01-01';
DECLARE @End_Date DATE = '2022-12-31';

DECLARE @Date DATE;
DECLARE @Year INT;
DECLARE @Month INT;
DECLARE @Day INT;
DECLARE @Day_Of_Week INT;
DECLARE @Day_Of_Year INT;
DECLARE @Week_Of_Year INT;
DECLARE @Quarter INT;
DECLARE @Semester INT;
DECLARE @Day_Name NVARCHAR(16);
DECLARE @Month_Name NVARCHAR(16);
DECLARE @Quarter_Name NCHAR(2);
DECLARE @Semester_Name NCHAR(2);
DECLARE @Is_Workday NCHAR(1);
DECLARE @Beginning_Of_Year DATE;
DECLARE @End_Of_Year DATE;
DECLARE @Beginning_Of_Semester DATE;
DECLARE @End_Of_Semester DATE;
DECLARE @Beginning_Of_Quarter DATE;
DECLARE @End_Of_Quarter DATE;
DECLARE @Beginning_Of_Month DATE;
DECLARE @End_Of_Month DATE;
DECLARE @Beginning_Of_Week DATE;
DECLARE @End_Of_Week DATE;

IF @Start_Date > @End_Date
    BEGIN
        DECLARE @Swap_Variable DATE;

        SET @Swap_Variable = @Start_Date;
        SET @Start_Date = @End_Date;
        SET @End_Date = @Swap_Variable;
    END

DECLARE @Total_Days_In_Range INT = DATEDIFF(day,@Start_Date,@End_Date) + 1;
DECLARE @Loop_Counter INT = 0;

IF OBJECT_ID('tempdb..#Calendar_Temp') IS NOT NULL
    DROP TABLE #Calendar_Temp;

CREATE TABLE #Calendar_Temp (
    [ID] INT NOT NULL IDENTITY(1,1),
    [Date] DATE NOT NULL,
    [Year] INT NOT NULL,
    [Month] INT NOT NULL,
    [Day] INT NOT NULL,
    [Day_Of_Week] INT NOT NULL,
    [Day_Of_Year] INT NOT NULL,
    [Week_Of_Year] INT NOT NULL,
    [Quarter] INT NOT NULL,
    [Semester] INT NOT NULL,
    [Day_Name] NVARCHAR(16) NOT NULL,
    [Month_Name] NVARCHAR(16) NOT NULL,
    [Quarter_Name] NCHAR(2) NOT NULL,
    [Semester_Name] NCHAR(2) NOT NULL,
    [Is_Workday] NCHAR(1) NOT NULL,
    [Beginning_Of_Year] DATE NOT NULL,
    [End_Of_Year] DATE NOT NULL,
    [Beginning_Of_Semester] DATE NOT NULL,
    [End_Of_Semester] DATE NOT NULL,
    [Beginning_Of_Quarter] DATE NOT NULL,
    [End_Of_Quarter] DATE NOT NULL,
    [Beginning_Of_Month] DATE NOT NULL,
    [End_Of_Month] DATE NOT NULL,
    [Beginning_Of_Week] DATE NOT NULL,
    [End_Of_Week] DATE NOT NULL);

WHILE @Loop_Counter < @Total_Days_In_Range
    BEGIN
        SET @Date = DATEADD(day,@Loop_Counter,@Start_Date);
        SET @Year = YEAR(@Date);
        SET @Month = MONTH(@Date);
        SET @Day = DAY(@Date);

        SET @Day_Of_Week = CASE FORMAT(@Date,'ddd')
                                WHEN 'Mon' THEN 1
                                WHEN 'Tue' THEN 2
                                WHEN 'Wed' THEN 3
                                WHEN 'Thu' THEN 4
                                WHEN 'Fri' THEN 5
                                WHEN 'Sat' THEN 6
                                ELSE 7
                           END;

        SET @Day_Of_Year = DATEPART(dayofyear,@Date);
        SET @Week_Of_Year = DATEPART(week,@Date);
        SET @Quarter = DATEPART(quarter,@Date);

        SET @Semester = CASE 
                             WHEN @Quarter IN (1,2) THEN 1
                             ELSE 2
                        END;

        SET @Day_Name = FORMAT(@Date,'ddd');
        SET @Month_Name = FORMAT(@Date,'MMM');
        SET @Quarter_Name = 'Q' + CAST(@Quarter AS NVARCHAR(1));
        SET @Semester_Name = 'S' + CAST(@Semester AS NVARCHAR(1));

        SET @Is_Workday = CASE
                               WHEN @Day_Of_Week IN (1,2,3,4,5) THEN 'Y'
                               ELSE 'N'
                          END;

        SET @Beginning_Of_Year = DATEFROMPARTS(YEAR(@Date),1,1);
        SET @End_Of_Year = DATEFROMPARTS(YEAR(@Date),12,31);
        SET @Beginning_Of_Semester = DATEFROMPARTS(YEAR(@Date),IIF(@Semester = 1,1,7),1);
        SET @End_Of_Semester = DATEADD(day,-1,DATEADD(month,6,@Beginning_Of_Semester));
        SET @Beginning_Of_Quarter = DATEFROMPARTS(YEAR(@Date),@Quarter * 3 - 2,1);
        SET @End_Of_Quarter = DATEADD(day,-1,DATEADD(month,3,@Beginning_Of_Quarter));
        SET @Beginning_Of_Month = DATEFROMPARTS(@Year,@Month,1);
        SET @End_Of_Month = DATEADD(day,-1,DATEADD(month,1,@Beginning_Of_Month));
        SET @Beginning_Of_Week = DATEADD(day,1-@Day_Of_Week,@Date);
        SET @End_Of_Week = DATEADD(day,6,@Beginning_Of_Week);

        INSERT INTO #Calendar_Temp ([Date],[Year],[Month],[Day],[Day_Of_Week],[Day_Of_Year],[Week_Of_Year],
                                    [Quarter],[Semester],[Day_Name],[Month_Name],[Quarter_Name],[Semester_Name],
                                    [Is_Workday],[Beginning_Of_Year],[End_Of_Year],[Beginning_Of_Semester],
                                    [End_Of_Semester],[Beginning_Of_Quarter],[End_Of_Quarter],[Beginning_Of_Month],
                                    [End_Of_Month],[Beginning_Of_Week],[End_Of_Week])
                            VALUES (@Date,@Year,@Month,@Day,@Day_Of_Week,@Day_Of_Year,@Week_Of_Year,
                                    @Quarter,@Semester,@Day_Name,@Month_Name,@Quarter_Name,@Semester_Name,
                                    @Is_Workday,@Beginning_Of_Year,@End_Of_Year,@Beginning_Of_Semester,
                                    @End_Of_Semester,@Beginning_Of_Quarter,@End_Of_Quarter,@Beginning_Of_Month,
                                    @End_Of_Month,@Beginning_Of_Week,@End_Of_Week);

        SET @Loop_Counter = @Loop_Counter + 1
    END

SET NOCOUNT OFF;
-- SELECT * FROM #Calendar_Temp;