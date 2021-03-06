/****** Object:  StoredProcedure [dbo].[p_INTRA_schedule_TEMPLATE]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_INTRA_schedule_TEMPLATE]
GO
/****** Object:  StoredProcedure [dbo].[p_INTRA_schedule_TEMPLATE]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE proc [dbo].[p_INTRA_schedule_TEMPLATE]	@schedule_mode int, @starttime time, @finishtime time, @interval int, @current_date datetime

as

If @schedule_mode IS NULL OR @schedule_mode = 0
	BEGIN
		SET @schedule_mode = 7 -- Retail Week
		--SET  @schedule_mode = 4 -- Onscreen/Digilite Week
	END
	
If @current_date IS NULL
	BEGIN
		SET @current_date = GETDATE()
	END
	
If @starttime IS NULL
	BEGIN
		SET @starttime = '00:00:00'
	END

If @finishtime IS NULL
	BEGIN
		SET @finishtime = '23:59:59'
	END
	
If @interval IS NULL
	BEGIN
		SET @interval = 30
	END

-- Set The First Day of The week
SET DATEFIRST @schedule_mode

-- Select first date of the processing week
SELECT @current_date = DATEADD( WEEK, 0, (DATEADD(DD, 1 - DATEPART(DW, @current_date), @current_date)))

CREATE TABLE #SCHEDULE(
		rownum			INT			IDENTITY(0,1),
		hh				INT			NOT NULL,		
		mm				INT			NOT NULL,
		start_time		TIME		NULL,
		finish_time		TIME		NULL,
		dd01			DATETIME	NULL,
		dd01dw			INT			NULL,
		dd01_end		DATETIME	NULL,
		dd02			DATETIME	NULL,
		dd02dw			INT			NULL,
		dd02_end		DATETIME	NULL,
		dd03			DATETIME	NULL,
		dd03dw			INT			NULL,
		dd03_end		DATETIME	NULL,
		dd04			DATETIME	NULL,
		dd04dw			INT			NULL,
		dd04_end		DATETIME	NULL,
		dd05			DATETIME	NULL,
		dd05dw			INT			NULL,
		dd05_end		DATETIME	NULL,
		dd06			DATETIME	NULL,
		dd06dw			INT			NULL,
		dd06_end		DATETIME	NULL,
		dd07			DATETIME	NULL,
		dd07dw			INT			NULL,
		dd07_end		DATETIME	NULL
		)

-- HEADER ROW - Dates ONLY
INSERT INTO #SCHEDULE( hh, mm, dd01,dd02,dd03,dd04,dd05,dd06,dd07)
SELECT	-1, -1,
		CONVERT(DATETIME, CONVERT( DATE, DATEADD(DD, 0, @current_date))),
		CONVERT(DATETIME, CONVERT( DATE, DATEADD(DD, 1, @current_date))),
		CONVERT(DATETIME, CONVERT( DATE, DATEADD(DD, 2, @current_date))),
		CONVERT(DATETIME, CONVERT( DATE, DATEADD(DD, 3, @current_date))),
		CONVERT(DATETIME, CONVERT( DATE, DATEADD(DD, 4, @current_date))),
		CONVERT(DATETIME, CONVERT( DATE, DATEADD(DD, 5, @current_date))),
		CONVERT(DATETIME, CONVERT( DATE, DATEADD(DD, 6, @current_date)))
		
-- TIME ROWS
INSERT INTO #SCHEDULE( hh, mm, start_time, finish_time)
SELECT	DATEPART(HOUR, CAST( DATEADD(MINUTE, (N1.Number - 1) * @interval, CAST(CAST(CONVERT(DATE, Getdate(), 103) AS DATE) AS DATETIME) + CAST(@starttime AS TIME)) AS TIME)),
		DATEPART(MINUTE, CAST( DATEADD(MINUTE, (N1.Number - 1) * @interval, CAST(CAST(CONVERT(DATE, Getdate(), 103) AS DATE) AS DATETIME) + CAST(@starttime AS TIME)) AS TIME)),
		CAST ( DATEADD(MINUTE, ( N1.Number - 1) * @interval, CAST(CAST(CONVERT(DATE, Getdate(), 103) AS DATE) AS DATETIME) + CAST(@starttime AS TIME)) AS TIME),
		CAST ( DATEADD(MINUTE, ( N1.Number - 1) * @interval + @interval, CAST(CAST(CONVERT(DATE, Getdate(), 103) AS DATE) AS DATETIME) + CAST(@starttime AS TIME)) AS TIME)
FROM	Numbers N1
WHERE	DATEADD(MINUTE, ( N1.Number - 1) * @interval, CAST(CAST(CONVERT(DATE, Getdate(), 103) AS DATE) AS DATETIME) + CAST(@starttime AS TIME))
		BETWEEN CAST(CAST(CONVERT(DATE, Getdate(), 103) AS DATE) AS DATETIME) + CAST(@starttime AS TIME)
		AND CAST(CAST(CONVERT(DATE, Getdate(), 103) AS DATE) AS DATETIME) + CAST(@finishtime AS TIME)

--- Sets DateWeek back to 7 (default, U.S. English) Sunday
SET DATEFIRST 7

-- Populate DateTime Matrix	
UPDATE	SCH2
SET		dd01 = CAST(SCH1.dd01 AS DATETIME) + CAST(SCH2.start_time AS TIME),
		dd02 = CAST(SCH1.dd02 AS DATETIME) + CAST(SCH2.start_time AS TIME),
		dd03 = CAST(SCH1.dd03 AS DATETIME) + CAST(SCH2.start_time AS TIME),
		dd04 = CAST(SCH1.dd04 AS DATETIME) + CAST(SCH2.start_time AS TIME),
		dd05 = CAST(SCH1.dd05 AS DATETIME) + CAST(SCH2.start_time AS TIME),
		dd06 = CAST(SCH1.dd06 AS DATETIME) + CAST(SCH2.start_time AS TIME),
		dd07 = CAST(SCH1.dd07 AS DATETIME) + CAST(SCH2.start_time AS TIME),
		dd01_end = DATEADD(SECOND, -1, DATEADD(MINUTE, @interval, CAST(SCH1.dd01 AS DATETIME) + CAST(SCH2.start_time AS TIME))),
		dd02_end = DATEADD(SECOND, -1, DATEADD(MINUTE, @interval, CAST(SCH1.dd02 AS DATETIME) + CAST(SCH2.start_time AS TIME))),
		dd03_end = DATEADD(SECOND, -1, DATEADD(MINUTE, @interval, CAST(SCH1.dd03 AS DATETIME) + CAST(SCH2.start_time AS TIME))),
		dd04_end = DATEADD(SECOND, -1, DATEADD(MINUTE, @interval, CAST(SCH1.dd04 AS DATETIME) + CAST(SCH2.start_time AS TIME))),
		dd05_end = DATEADD(SECOND, -1, DATEADD(MINUTE, @interval, CAST(SCH1.dd05 AS DATETIME) + CAST(SCH2.start_time AS TIME))),
		dd06_end = DATEADD(SECOND, -1, DATEADD(MINUTE, @interval, CAST(SCH1.dd06 AS DATETIME) + CAST(SCH2.start_time AS TIME))),
		dd07_end = DATEADD(SECOND, -1, DATEADD(MINUTE, @interval, CAST(SCH1.dd07 AS DATETIME) + CAST(SCH2.start_time AS TIME)))
FROM	#SCHEDULE AS SCH1, #SCHEDULE AS SCH2
WHERE	SCH1.rownum = 0 AND SCH2.rownum > 0

-- Update DayofWeek relative to Sunday 
UPDATE	#SCHEDULE
SET		dd01dw = DATEPART(WEEKDAY, dd01),
		dd02dw = DATEPART(WEEKDAY, dd02),
		dd03dw = DATEPART(WEEKDAY, dd03),
		dd04dw = DATEPART(WEEKDAY, dd04),
		dd05dw = DATEPART(WEEKDAY, dd05),
		dd06dw = DATEPART(WEEKDAY, dd06),
		dd07dw = DATEPART(WEEKDAY, dd07)

SELECT 	rownum, hh, mm, start_time, finish_time,
		dd01, dd01_end, dd01dw,
		dd02, dd02_end, dd02dw, 
		dd03, dd03_end,	dd03dw, 
		dd04, dd04_end,	dd04dw, 
		dd05, dd05_end,	dd05dw, 
		dd06, dd06_end, dd06dw, 
		dd07, dd07_end,	dd07dw 
FROM #SCHEDULE
GO
