/****** Object:  StoredProcedure [dbo].[p_INTRA_pattern_daily_segment]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_INTRA_pattern_daily_segment]
GO
/****** Object:  StoredProcedure [dbo].[p_INTRA_pattern_daily_segment]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE proc [dbo].[p_INTRA_pattern_daily_segment]		@mode							INT,
														@package_id				INT,
														@spot_id							INT,
														@schedule_mode		int,
														@starttime						time,
														@finishtime						time,
														@interval							int,
														@current_date				datetime

as

DECLARE		@rownum			INT,
							@patt_day			INT,
							@pattern_id		INT,
							@start_date		DATETIME,
							@end_date			DATETIME,
							@fill_flag				INT,
							@burst_valid		int,
              @cinelight_patt_day int

CREATE TABLE #SCHEDULE(
		rownum								INT								NULL,
		hh										INT								NOT NULL,
		mm										INT								NULL,
		start_time							TIME							NULL,
		finish_time						TIME							NULL,
		dd01									DATETIME				NOT NULL,
		dd01dw								INT								NULL,
		dd01_flag							INT								NULL					DEFAULT 0,
		dd01_pattern_id			INT								NULL,
		dd02									DATETIME				NOT NULL,
		dd02dw								INT								NULL,
		dd02_flag							INT								NULL					DEFAULT 0,
		dd02_pattern_id			INT								NULL,
		dd03									DATETIME				NOT NULL,
		dd03dw								INT								NULL,
		dd03_flag							INT								NULL					DEFAULT 0,
		dd03_pattern_id			INT								NULL,
		dd04									DATETIME				NOT NULL,
		dd04dw								INT								NULL,
		dd04_flag							INT								NULL					DEFAULT 0,
		dd04_pattern_id			INT								NULL,
		dd05									DATETIME				NOT NULL,
		dd05dw								INT								NULL,
		dd05_flag							INT								NULL					DEFAULT 0,
		dd05_pattern_id			INT								NULL,
		dd06									DATETIME				NOT NULL,
		dd06dw								INT								NULL,
		dd06_flag							INT								NULL					DEFAULT 0,
		dd06_pattern_id			INT								NULL,
		dd07									DATETIME				NOT NULL,
		dd07dw								INT								NULL,
		dd07_flag							INT								NULL					DEFAULT 0,
		dd07_pattern_id			INT								NULL,
		dd01_end						DATETIME				NULL,
		dd02_end						DATETIME				NULL,
		dd03_end						DATETIME				NULL,
		dd04_end						DATETIME				NULL,
		dd05_end						DATETIME				NULL,
		dd06_end						DATETIME				NULL,
		dd07_end						DATETIME				NULL
		)

If ( @mode = 1 OR @mode = 2 or @mode = 5) -- Outpost
	SELECT @schedule_mode = 7

If ( @mode = 3 OR @mode = 4 or @mode = 6) -- Digilite
	SELECT @schedule_mode = 4

INSERT INTO #SCHEDULE ( rownum, hh, mm, start_time, finish_time,
		dd01, dd01_end, dd01dw,
		dd02, dd02_end, dd02dw,
		dd03, dd03_end, dd03dw,
		dd04, dd04_end, dd04dw,
		dd05, dd05_end, dd05dw,
		dd06, dd06_end, dd06dw,
		dd07, dd07_end, dd07dw
		)

EXECUTE p_INTRA_schedule_TEMPLATE	@schedule_mode, @starttime, @finishtime, @interval, @current_date

If ( @mode = 1 ) or (@mode = 5)  -- Outpost PATTERN
BEGIN
	declare			cur_schedule cursor static for
	select			patt_day,
							start_date,
							end_date,
							pattern_id
	from				outpost_package_intra_pattern
	WHERE		package_id = @package_id
	order by		patt_day,
							start_date,
							end_date
END

If ( @mode = 2 ) -- Outpost DAILY SGEMENT
	BEGIN
		declare cur_schedule cursor static for
		select	DATEPART(DW, start_date) , start_date, end_date, 1
		from	outpost_spot_daily_segment
		WHERE	spot_id = @spot_id
		order by DATEPART(DW, start_date), start_date, end_date
	END

If ( @mode = 3 or @mode = 6 ) -- Digilite PATTERN
	BEGIN
		declare cur_schedule cursor static for
		select	patt_day, start_date, end_date, pattern_id
		from	cinelight_package_intra_pattern
		WHERE	package_id = @package_id
		order by patt_day, start_date, end_date
	END

If ( @mode = 4 ) -- Digilite DAILY SGEMENT
	BEGIN
		declare cur_schedule cursor static for
		select	DATEPART(DW, start_date) , start_date, end_date, 1
		from	cinelight_spot_daily_segment
		WHERE	spot_id = @spot_id
		order by DATEPART(DW, start_date), start_date, end_date
	END

open cur_schedule
fetch cur_schedule into @patt_day, @start_date, @end_date, @pattern_id
while (@@fetch_status = 0)
begin

		if @mode = 5
		begin
			select	@burst_valid = count(*)
			from		outpost_package_burst
			where	package_id = @package_id
			and			start_date <= dateadd(dd, @patt_day - 1, @current_date)
			and			end_date >= dateadd(dd, @patt_day - 1, @current_date)



			if @burst_valid = 0
			begin
				select @patt_day = 0
			end
		end

  	if @mode = 6
		begin

      if @patt_day > 4
        select @cinelight_patt_day = @patt_day - 4
      ELSE
        select @cinelight_patt_day = @patt_day + 3

			select	@burst_valid = count(*)
			from		cinelight_package_burst
			where	package_id = @package_id
			and			start_date <= dateadd(dd, @cinelight_patt_day - 1, @current_date)
			and			end_date >= dateadd(dd, @cinelight_patt_day - 1, @current_date)

			if @burst_valid = 0
			begin
				select @patt_day = 0
			end
		end

		 -- Fully Filled Slot
		SELECT			@fill_flag = 1

		UPDATE			#SCHEDULE
		SET					dd01_pattern_id = @pattern_id,
									dd01_flag = @fill_flag
		WHERE			dd01dw = @patt_day
		and						start_time  >= CONVERT(TIME,@start_date)
		and						start_time < CONVERT(TIME,@end_date)
		and						CONVERT(TIME, dd01_end) <= CONVERT(TIME,@end_date)
		and						CONVERT(TIME, dd01_end) > CONVERT(TIME,@start_date)

		UPDATE			#SCHEDULE
		SET					dd02_pattern_id = @pattern_id,
									dd02_flag = @fill_flag
		WHERE			dd02dw = @patt_day
		and						start_time  >= CONVERT(TIME,@start_date)
		and						start_time < CONVERT(TIME,@end_date)
		and						CONVERT(TIME, dd02_end) <= CONVERT(TIME,@end_date)
		and						CONVERT(TIME, dd02_end) > CONVERT(TIME,@start_date)

		UPDATE			#SCHEDULE
		SET					dd03_pattern_id = @pattern_id,
									dd03_flag = @fill_flag
		WHERE			dd03dw = @patt_day
		and						start_time  >= CONVERT(TIME,@start_date)
		and						start_time < CONVERT(TIME,@end_date)
		and						CONVERT(TIME, dd03_end) <= CONVERT(TIME,@end_date)
		and						CONVERT(TIME, dd03_end) > CONVERT(TIME,@start_date)

		UPDATE			#SCHEDULE
		SET					dd04_pattern_id = @pattern_id,
									dd04_flag = @fill_flag
		WHERE			dd04dw = @patt_day
		and						start_time  >= CONVERT(TIME,@start_date)
		and						start_time < CONVERT(TIME,@end_date)
		and						CONVERT(TIME, dd04_end) <= CONVERT(TIME,@end_date)
		and						CONVERT(TIME, dd04_end) > CONVERT(TIME,@start_date)

		UPDATE #SCHEDULE
		SET dd05_pattern_id = @pattern_id, dd05_flag = @fill_flag
		WHERE dd05dw = @patt_day and
			start_time  >= CONVERT(TIME,@start_date) and start_time < CONVERT(TIME,@end_date) and CONVERT(TIME, dd05_end) <= CONVERT(TIME,@end_date) and CONVERT(TIME, dd05_end) > CONVERT(TIME,@start_date)

		UPDATE #SCHEDULE
		SET dd06_pattern_id = @pattern_id, dd06_flag = @fill_flag
		WHERE dd06dw = @patt_day and
			start_time  >= CONVERT(TIME,@start_date) and start_time < CONVERT(TIME,@end_date) and CONVERT(TIME, dd06_end) <= CONVERT(TIME,@end_date) and CONVERT(TIME, dd06_end) > CONVERT(TIME,@start_date)

		UPDATE #SCHEDULE
		SET dd07_pattern_id = @pattern_id, dd07_flag = @fill_flag
		WHERE dd07dw = @patt_day and
			start_time  >= CONVERT(TIME,@start_date) and start_time < CONVERT(TIME,@end_date) and CONVERT(TIME, dd07_end) <= CONVERT(TIME,@end_date) and CONVERT(TIME, dd07_end) > CONVERT(TIME,@start_date)

		-- Partially Filled Slot
		SELECT @fill_flag = 2
		UPDATE #SCHEDULE
		SET dd01_pattern_id = @pattern_id, dd01_flag = @fill_flag
		WHERE dd01dw = @patt_day
			and ((	CONVERT(TIME,@start_date) <= start_time and CONVERT(TIME,@end_date) > start_time and CONVERT(TIME,@end_date) < CONVERT(TIME, dd01_end) )
			OR 	( 	CONVERT(TIME,@start_date) > start_time and CONVERT(TIME,@start_date) < CONVERT(TIME, dd01_end) and CONVERT(TIME,@end_date) > CONVERT(TIME, dd01_end) )
			OR 	( 	CONVERT(TIME,@start_date) > start_time	and CONVERT(TIME,@start_date) <= CONVERT(TIME, dd01_end) and CONVERT(TIME,@end_date) > start_time and CONVERT(TIME,@end_date) <= CONVERT(TIME, dd01_end) ))

		UPDATE #SCHEDULE
		SET dd02_pattern_id = @pattern_id, dd02_flag = @fill_flag
		WHERE dd02dw = @patt_day
			and ((	CONVERT(TIME,@start_date) <= start_time and CONVERT(TIME,@end_date) > start_time and CONVERT(TIME,@end_date) < CONVERT(TIME, dd02_end) )
			OR 	( 	CONVERT(TIME,@start_date) > start_time and CONVERT(TIME,@start_date) < CONVERT(TIME, dd02_end) and CONVERT(TIME,@end_date) > CONVERT(TIME, dd02_end) )
			OR 	( 	CONVERT(TIME,@start_date) > start_time	and CONVERT(TIME,@start_date) <= CONVERT(TIME, dd02_end) and CONVERT(TIME,@end_date) > start_time and CONVERT(TIME,@end_date) <= CONVERT(TIME, dd02_end) ))

		UPDATE #SCHEDULE
		SET dd03_pattern_id = @pattern_id, dd03_flag = @fill_flag
		WHERE dd03dw = @patt_day
			and ((	CONVERT(TIME,@start_date) <= start_time and CONVERT(TIME,@end_date) > start_time and CONVERT(TIME,@end_date) < CONVERT(TIME, dd03_end) )
			OR 	( 	CONVERT(TIME,@start_date) > start_time and CONVERT(TIME,@start_date) < CONVERT(TIME, dd03_end) and CONVERT(TIME,@end_date) > CONVERT(TIME, dd03_end) )
			OR 	( 	CONVERT(TIME,@start_date) > start_time	and CONVERT(TIME,@start_date) <= CONVERT(TIME, dd03_end) and CONVERT(TIME,@end_date) > start_time and CONVERT(TIME,@end_date) <= CONVERT(TIME, dd03_end) ))


		UPDATE #SCHEDULE
		SET dd04_pattern_id = @pattern_id, dd04_flag = @fill_flag
		WHERE dd04dw = @patt_day
			and ((	CONVERT(TIME,@start_date) <= start_time and CONVERT(TIME,@end_date) > start_time and CONVERT(TIME,@end_date) < CONVERT(TIME, dd04_end) )
			OR 	( 	CONVERT(TIME,@start_date) > start_time and CONVERT(TIME,@start_date) < CONVERT(TIME, dd04_end) and CONVERT(TIME,@end_date) > CONVERT(TIME, dd04_end) )
			OR 	( 	CONVERT(TIME,@start_date) > start_time	and CONVERT(TIME,@start_date) <= CONVERT(TIME, dd04_end) and CONVERT(TIME,@end_date) > start_time and CONVERT(TIME,@end_date) <= CONVERT(TIME, dd04_end) ))

		UPDATE #SCHEDULE
		SET dd05_pattern_id = @pattern_id, dd05_flag = @fill_flag
		WHERE dd05dw = @patt_day
			and ((	CONVERT(TIME,@start_date) <= start_time and CONVERT(TIME,@end_date) > start_time and CONVERT(TIME,@end_date) < CONVERT(TIME, dd05_end) )
			OR 	( 	CONVERT(TIME,@start_date) > start_time and CONVERT(TIME,@start_date) < CONVERT(TIME, dd05_end) and CONVERT(TIME,@end_date) > CONVERT(TIME, dd05_end) )
			OR 	( 	CONVERT(TIME,@start_date) > start_time	and CONVERT(TIME,@start_date) <= CONVERT(TIME, dd05_end) and CONVERT(TIME,@end_date) > start_time and CONVERT(TIME,@end_date) <= CONVERT(TIME, dd05_end) ))

		UPDATE #SCHEDULE
		SET dd06_pattern_id = @pattern_id, dd06_flag = @fill_flag
		WHERE dd06dw = @patt_day
			and ((	CONVERT(TIME,@start_date) <= start_time and CONVERT(TIME,@end_date) > start_time and CONVERT(TIME,@end_date) < CONVERT(TIME, dd06_end) )
			OR 	( 	CONVERT(TIME,@start_date) > start_time and CONVERT(TIME,@start_date) < CONVERT(TIME, dd06_end) and CONVERT(TIME,@end_date) > CONVERT(TIME, dd06_end) )
			OR 	( 	CONVERT(TIME,@start_date) > start_time	and CONVERT(TIME,@start_date) <= CONVERT(TIME, dd06_end) and CONVERT(TIME,@end_date) > start_time and CONVERT(TIME,@end_date) <= CONVERT(TIME, dd06_end) ))

		UPDATE #SCHEDULE
		SET dd07_pattern_id = @pattern_id, dd07_flag = @fill_flag
		WHERE dd07dw = @patt_day
			and ((	CONVERT(TIME,@start_date) <= start_time and CONVERT(TIME,@end_date) > start_time and CONVERT(TIME,@end_date) < CONVERT(TIME, dd07_end) )
			OR 	( 	CONVERT(TIME,@start_date) > start_time and CONVERT(TIME,@start_date) < CONVERT(TIME, dd07_end) and CONVERT(TIME,@end_date) > CONVERT(TIME, dd07_end) )
			OR 	( 	CONVERT(TIME,@start_date) > start_time	and CONVERT(TIME,@start_date) <= CONVERT(TIME, dd07_end) and CONVERT(TIME,@end_date) > start_time and CONVERT(TIME,@end_date) <= CONVERT(TIME, dd07_end) ))

		fetch cur_schedule into @patt_day, @start_date, @end_date, @pattern_id
	end

deallocate cur_schedule

-- Set default to 1 (i.e. selected) for package_id = 0
SELECT 	rownum, hh, mm,
		CONVERT(VARCHAR(5),start_time) AS start_time,
		CONVERT(VARCHAR(5),finish_time) AS finish_time,
		dd01, CASE When @package_id = 0 Then ( case When rownum = 0 Then 0 Else 1 End ) Else dd01_flag End, dd01dw,
		dd02, CASE When @package_id = 0 Then ( case When rownum = 0 Then 0 Else 1 End ) Else dd02_flag End, dd02dw,
		dd03, CASE When @package_id = 0 Then ( case When rownum = 0 Then 0 Else 1 End ) Else dd03_flag End, dd03dw,
		dd04, CASE When @package_id = 0 Then ( case When rownum = 0 Then 0 Else 1 End ) Else dd04_flag End, dd04dw,
		dd05, CASE When @package_id = 0 Then ( case When rownum = 0 Then 0 Else 1 End ) Else dd05_flag End, dd05dw,
		dd06, CASE When @package_id = 0 Then ( case When rownum = 0 Then 0 Else 1 End ) Else dd06_flag End, dd06dw,
		dd07, CASE When @package_id = 0 Then ( case When rownum = 0 Then 0 Else 1 End ) Else dd07_flag End, dd07dw,
		dd01_pattern_id,
		dd02_pattern_id,
		dd03_pattern_id,
		dd04_pattern_id,
		dd05_pattern_id,
		dd06_pattern_id,
		dd07_pattern_id,
		dd01_end,
		dd02_end,
		dd03_end,
		dd04_end,
		dd05_end,
		dd06_end,
		dd07_end
FROM #SCHEDULE

DROP TABLE #SCHEDULE

return 0
GO
