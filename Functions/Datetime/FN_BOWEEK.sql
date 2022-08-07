IF OBJECT_ID (N'FN_BOWEEK') IS NOT NULL
    DROP FUNCTION FN_BOWEEK;
GO

CREATE FUNCTION FN_BOWEEK 
(
    @Date DATE
)
RETURNS DATE
AS
BEGIN
    DECLARE @Day_Of_Week INT = CASE FORMAT(@Date,'ddd')
                                    WHEN 'Mon' THEN 1
                                    WHEN 'Tue' THEN 2
                                    WHEN 'Wed' THEN 3
                                    WHEN 'Thu' THEN 4
                                    WHEN 'Fri' THEN 5
                                    WHEN 'Sat' THEN 6
                                    ELSE 7
                               END;

    DECLARE @Result DATE = DATEADD(day,1-@Day_Of_Week,@Date);

    RETURN @Result;
END
GO