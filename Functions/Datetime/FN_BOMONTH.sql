IF OBJECT_ID (N'FN_BOMONTH') IS NOT NULL
    DROP FUNCTION FN_BOMONTH;
GO

CREATE FUNCTION FN_BOMONTH 
(
    @Date DATE
)
RETURNS DATE
AS
BEGIN
    DECLARE @Result DATE = DATEFROMPARTS(YEAR(@Date),MONTH(@Date),1)
 
    RETURN @Result;
END
GO