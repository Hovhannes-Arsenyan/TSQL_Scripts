IF OBJECT_ID (N'FN_EOQUARTER') IS NOT NULL
    DROP FUNCTION FN_EOQUARTER;
GO

CREATE FUNCTION FN_EOQUARTER 
(
    @Date DATE
)
RETURNS DATE
AS
BEGIN

    DECLARE @Result DATE = DATEADD(day,-1,DATEADD(month,3,DATEFROMPARTS(YEAR(@Date),DATEPART(quarter,@Date) * 3 - 2,1)));

    RETURN @Result;
END
GO