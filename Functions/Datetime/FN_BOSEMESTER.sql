IF OBJECT_ID (N'FN_BOSEMESTER') IS NOT NULL
    DROP FUNCTION FN_BOSEMESTER;
GO

CREATE FUNCTION FN_BOSEMESTER 
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

    DECLARE @Result DATE = DATEFROMPARTS(YEAR(@Date),IIF(@Semester = 1,1,7),1);

    RETURN @Result;
END
GO