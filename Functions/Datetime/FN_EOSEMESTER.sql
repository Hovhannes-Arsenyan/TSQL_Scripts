IF OBJECT_ID (N'FN_EOSEMESTER') IS NOT NULL
    DROP FUNCTION FN_EOSEMESTER;
GO

CREATE FUNCTION FN_EOSEMESTER 
(
    @Date DATE
)
RETURNS DATE
AS
BEGIN
    DECLARE @Quarter INT = DATEPART(quarter,@Date);
    DECLARE @Semester INT = CASE
                                 WHEN @Quarter IN (1,2) THEN 1
                                 ELSE 2
                            END

    DECLARE @Beginning_Of_Semester DATE = DATEFROMPARTS(YEAR(@Date),IIF(@Semester = 1,1,7),1);
    DECLARE @Result DATE = DATEADD(day,-1,DATEADD(month,6,@Beginning_Of_Semester));

    RETURN @Result;
END
GO