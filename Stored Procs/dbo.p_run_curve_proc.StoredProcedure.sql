/****** Object:  StoredProcedure [dbo].[p_run_curve_proc]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_run_curve_proc]
GO
/****** Object:  StoredProcedure [dbo].[p_run_curve_proc]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create proc [dbo].[p_run_curve_proc]		@start_date								datetime,
									@cinetam_reporting_demographics_id		int,
									@attendance								numeric(30,20),
									@country_code							char(1),
									@film_markets							varchar(max),
									@how_many								int

as

declare			@error										int,
				@cinetam_reporting_demographics_desc		varchar(50),
				@attendance_estimate						numeric(30,20),
				@lower_unique_people						numeric(30,20),
				@lower_unique_transactions					numeric(30,20),
				@higher_unique_people						numeric(30,20),
				@higher_unique_transactions					numeric(30,20),
				@lower_unique_people_2plus					numeric(30,20),
				@lower_unique_transactions_2plus			numeric(30,20),
				@higher_unique_people_2plus					numeric(30,20),
				@higher_unique_transactions_2plus			numeric(30,20),
				@lower_unique_people_3plus					numeric(30,20),
				@lower_unique_transactions_3plus			numeric(30,20),
				@higher_unique_people_3plus					numeric(30,20),
				@higher_unique_transactions_3plus			numeric(30,20),
				@attendance_population						numeric(30,20),
				@reach_threshold							numeric(30,20),
				@frequency_week_one							numeric(30,20),
				@frequency_modifier							numeric(30,20),
				@reach_initial								numeric(30,20),
				@reach_final								numeric(30,20),
				@frequency_initial							numeric(30,20),
				@frequency_final							numeric(30,20),
				@frequency_week_one_2plus					numeric(30,20),
				@frequency_modifier_2plus					numeric(30,20),
				@reach_initial_2plus						numeric(30,20),
				@reach_final_2plus							numeric(30,20),
				@frequency_initial_2plus					numeric(30,20),
				@frequency_final_2plus						numeric(30,20),
				@frequency_week_one_3plus					numeric(30,20),
				@frequency_modifier_3plus					numeric(30,20),
				@reach_initial_3plus						numeric(30,20),
				@reach_final_3plus							numeric(30,20),
				@frequency_initial_3plus					numeric(30,20),
				@frequency_final_3plus						numeric(30,20),
				@national_count								int,
				@metro_count								int,
				@regional_count								int,
				@curve_1plus								int,
				@curve_2plus								int,
				@curve_3plus								int,
				@52_week_total_attendance					numeric(30,20),
				@52_week_weekly_attendance					numeric(30,20),
				@52_week_freqvar							numeric(30,20),
				@52_week_freqvar_2plus						numeric(30,20),
				@52_week_freqvar_3_plus						numeric(30,20),
				@week_num									int

set nocount on

create table #rf_curve_results
(
	weeknum										int					null,
	start_week									datetime			null,
	end_week									datetime			null,
	cinetam_reporting_demographics_desc			varchar(50)			null,
	attendance_estimate							numeric(30,20)		null,
	attendance_population						numeric(30,20)		null,
	reach_threshold								numeric(30,20)		null,
	reach_threshold_week_four					numeric(30,20)		null,
	lower_unique_people							numeric(30,20)		null,
	lower_unique_transactions					numeric(30,20)		null,
	higher_unique_people						numeric(30,20)		null,
	higher_unique_transactions					numeric(30,20)		null,
	frequency_week_one							numeric(30,20)		null,
	frequency_week_four							numeric(30,20)		null,
	frequency_modifier							numeric(30,20)		null,
	reach_initial								numeric(30,20)		null,
	reach_final									numeric(30,20)		null,
	frequency_initial							numeric(30,20)		null,
	frequency_final								numeric(30,20)		null,
)

create table #results
(
	no_weeks				int					null,
	reach_final				numeric(30,20)		null,
	frequency_final			numeric(30,20)		null
)

select @week_num = @how_many

while (@week_num <= 52)
begin
	insert into #rf_curve_results
	exec @error = p_rf_curve_report_2021  @week_num, @start_date, @cinetam_reporting_demographics_id, @attendance, @country_code, @film_markets

	if @error <> 0
	begin		
		raiserror ('Error running curve consolidator procedure', 16, 1)
		return -1
	end

	insert into #results
	select			weeknum, 
					reach_final, 
					frequency_final
	from			#rf_curve_results
	where			weeknum = @week_num

	select @week_num = @week_num + @how_many

	delete #rf_curve_results
end

select * from #results

drop table #results
drop table #rf_curve_results
return 0
GO
