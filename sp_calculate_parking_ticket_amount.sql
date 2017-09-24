-- Provide Datbase Name
-- USE Datbase_Name 
GO

/****** Object:  StoredProcedure [dbo].[Calculate_Parking_Ticket_Amount]    Script Date: 9/24/2017 5:26:08 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

Create Procedure [dbo].[Calculate_Parking_Ticket_Amount]
@EntryDate DATETIME,
@ExitDate DATETIME

AS
DECLARE 
		@ManipulatingDate DATETIME,
		@TimeTag	TIME,
		@DayDifference INT,
		@CountStart INT,
		@ManipulatingDateTimeTag DATETIME,
		@StartTimeMinutes INT

DECLARE @DayCal TABLE ([Seq_No] INT IDENTITY(1,1), 
[Date] DATETIME, 
[Day] NVARCHAR(15), 
[DayType] NVARCHAR(15), 
[Hours] INT, 
[Minutes] INT, 
[TotalHours] INT,
[Amount] MONEY)

--SET @EntryDate = '2015-02-06 18:48:25.930'
--SET @ExitDate = '2015-02-15 18:48:25.930'
SET @TimeTag	= '00:00:00.000'
SET @CountStart = 0

SELECT @DayDifference = DATEDIFF(dd,@EntryDate,@ExitDate) 
SET @ManipulatingDate = @EntryDate

IF (@DayDifference < 1)
BEGIN 

	INSERT INTO @DayCal
	([Date], [Day], [DayType],[Hours],[Minutes],[TotalHours])
	SELECT @ManipulatingDate,
	DATENAME(dw, @ManipulatingDate) DayofWeek,
	CHOOSE(DATEPART(dw, @ManipulatingDate), 'Weekend','Weekday',
	'Weekday','Weekday','Weekday','Weekday','Weekend') WorkDay,
	DATEDIFF(hh,@ManipulatingDate, @ExitDate),
	DATEPART(mi,@ExitDate)-DATEPART(mi,@ManipulatingDate),
	CASE 
	WHEN DATEPART(mi,@ExitDate)-DATEPART(mi,@ManipulatingDate) >= 1 THEN DATEDIFF(hh,@ManipulatingDate, @ExitDate)+1 
	ELSE DATEDIFF(hh,@ManipulatingDate, @ExitDate) 
	END
	
END
ELSE IF (@DayDifference >= 1)
BEGIN
	WHILE (@CountStart < @DayDifference AND @ManipulatingDate <= @ExitDate)
	BEGIN 

		SELECT @ManipulatingDateTimeTag = CONVERT(VARCHAR(10), @ManipulatingDate+1, 20) + ' ' + CAST(@TimeTag AS VARCHAR(12))

		INSERT INTO @DayCal
		([Date], [Day], [DayType],[Hours],[Minutes],[TotalHours])
		SELECT @ManipulatingDate,
		DATENAME(dw, @ManipulatingDate) DayofWeek,
		CHOOSE(DATEPART(dw, @ManipulatingDate), 'Weekend','Weekday',
		'Weekday','Weekday','Weekday','Weekday','Weekend') WorkDay,
		DATEDIFF(hh,@ManipulatingDate, @ManipulatingDateTimeTag),
		DATEPART(mi,@ManipulatingDateTimeTag)-DATEPART(mi,@ManipulatingDate),
		CASE 
		WHEN DATEPART(mi,@ManipulatingDateTimeTag)-DATEPART(mi,@ManipulatingDate) >= 1 THEN DATEDIFF(hh,@ManipulatingDate, @ManipulatingDateTimeTag)+1 
		ELSE DATEDIFF(hh,@ManipulatingDate, @ManipulatingDateTimeTag) 
		END

		SET @ManipulatingDate = @ManipulatingDateTimeTag
		SET @CountStart = @CountStart + 1
	END
	WHILE (@CountStart = @DayDifference AND @ManipulatingDate <= @ExitDate)
	BEGIN 

		SELECT @StartTimeMinutes = [Minutes] FROM @DayCal WHERE Seq_no = 1

		INSERT INTO @DayCal
		([Date], [Day], [DayType],[Hours],[Minutes],[TotalHours])
		SELECT @ExitDate,
		DATENAME(dw, @ManipulatingDate) DayofWeek,
		CHOOSE(DATEPART(dw, @ManipulatingDate), 'Weekend','Weekday',
		'Weekday','Weekday','Weekday','Weekday','Weekend') WorkDay,
		DATEDIFF(hh,@ManipulatingDate, @ExitDate),
		@StartTimeMinutes+DATEPART(mi,@ExitDate),
		CASE 
		WHEN @StartTimeMinutes+DATEPART(mi,@ExitDate) <= 0 THEN DATEDIFF(hh,@ManipulatingDate, @ExitDate)
		ELSE DATEDIFF(hh,@ManipulatingDate, @ExitDate)+1
		END

		SET @ManipulatingDate = @ManipulatingDateTimeTag
		SET @CountStart = @CountStart + 1
	END
END

UPDATE @DayCal SET Amount = CASE WHEN DayType = 'Weekday' THEN TotalHours * 10 ELSE TotalHours * 20 END

SELECT * FROM @DayCal
SELECT SUM(TotalHours) TotalHours,SUM(Amount) TotalAmountToBePaid FROM @DayCal



GO


