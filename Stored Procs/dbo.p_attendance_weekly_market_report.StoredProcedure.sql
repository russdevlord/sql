/****** Object:  StoredProcedure [dbo].[p_attendance_weekly_market_report]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_attendance_weekly_market_report]
GO
/****** Object:  StoredProcedure [dbo].[p_attendance_weekly_market_report]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE proc [dbo].[p_attendance_weekly_market_report] 	@screening_date		datetime,
												@country_code		char(1)

as

declare		@error						integer,
			@film_market_no				integer,
			@film_market_desc			varchar(30),
			@attendance					integer,
			@attendance_prev			integer,
			@attendance_ytd				integer,
			@attendance_prev_ytd		integer,
			@country_name				varchar(30),
			@prev_screening_date		datetime,
			@attendance_period_no		int,
			@year_start					datetime,
			@prev_year_start			datetime,
			@total_screens				int,
			@actual_screens				int,
			@prev_total_screens			int,
			@prev_actual_screens		int,
			@total_ytd_screens			int,
			@actual_ytd_screens			int,
			@prev_total_ytd_screens		int,
			@prev_actual_ytd_screens	int

set nocount on

select 	@attendance_period_no = attendance_period_no
from	film_screening_dates
where 	screening_date = @screening_date 

select 	@prev_screening_date = max(screening_date)
from	film_screening_dates
where	attendance_period_no = @attendance_period_no
and		screening_date < @screening_date

select 	@year_start = min(screening_date)
from	film_screening_dates 
where	attendance_year_end in (select 	attendance_year_end 
								from 	film_screening_dates
								where 	screening_date = @screening_date)

select 	@prev_year_start = min(screening_date)
from	film_screening_dates 
where	attendance_year_end in (select 	attendance_year_end 
								from 	film_screening_dates
								where 	screening_date = @prev_screening_date)

create table #attendance_report (	
	film_market_no				integer			not null,
	film_market_desc			varchar(30)		not null,
	attendance					integer			not null,
	attendance_prev				integer			not null,
	attendance_ytd				integer			not null,
	attendance_prev_ytd			integer			not null,
	country_code				char(1)			not null,
	country_name				varchar(30)		not null,
	screening_date				datetime		not null,
	prev_screening_date			datetime		not null,
	year_start					datetime		not null,
	prev_year_start				datetime		not null,
	total_screens				int				not null,
	actual_screens				int				not null
)

declare		market_csr cursor static forward_only for 
select		distinct film_market.film_market_no,
			film_market.film_market_desc,
			branch.country_code
from		complex,
			movie_history,
			film_market,
			branch
where		complex.complex_id = movie_history.complex_id
and			(movie_history.screening_date = @screening_date
or			movie_history.screening_date = @prev_screening_date)
and			complex.film_market_no = film_market.film_market_no
and			complex.branch_code = branch.branch_code
and			movie_history.country = @country_code
group by 	film_market.film_market_no,
			film_market.film_market_desc,
			branch.country_code

open market_csr
fetch market_csr into @film_market_no, @film_market_desc, @country_code
while(@@fetch_Status=0)
begin

	select 	@country_name = country_name
	from	country
	where	country_code = @country_code

	select 	@attendance = sum(attendance)
	from	movie_history,
			complex
	where	screening_date = @screening_date
	and		complex.complex_id = movie_history.complex_id
	and		complex.film_market_no = @film_market_no
	
	select 	@actual_screens = SUM(no_cinemas) --sum(slide_screens)
	from	complex
	where	complex.complex_id in (	select distinct complex_id from movie_history where attendance_type = 'A'
									and		screening_date = @screening_date)
	and		complex.film_market_no = @film_market_no

 	select 	@total_screens = SUM(no_cinemas) --sum(slide_screens)
	from	complex
	where	complex.complex_id in (select distinct complex_id from movie_history where screening_date = @screening_date)
	and		complex.film_market_no = @film_market_no

	select 	@attendance_prev = sum(attendance)
	from	movie_history,
			complex
	where	screening_date = @prev_screening_date
	and		complex.complex_id = movie_history.complex_id
	and		complex.film_market_no = @film_market_no
	
	select 	@attendance_ytd = sum(attendance)
	from	movie_history,
			complex
	where	screening_date <= @screening_date
	and		screening_date >= @year_start
	and		complex.complex_id = movie_history.complex_id
	and		complex.film_market_no = @film_market_no

	select 	@attendance_prev_ytd = sum(attendance)
	from	movie_history,
			complex
	where	screening_date <= @prev_screening_date
	and		screening_date >= @prev_year_start
	and		complex.complex_id = movie_history.complex_id
	and		complex.film_market_no = @film_market_no


insert into #attendance_report (
		film_market_no,
		film_market_desc,
		attendance,
		attendance_prev,
		attendance_ytd,
		attendance_prev_ytd,
		country_code,
		country_name,
		screening_date,
		prev_screening_date,
		year_start,
		prev_year_start,
		total_screens,
		actual_screens	)
values (
		@film_market_no,
		@film_market_desc,
		isnull(@attendance,0),
		isnull(@attendance_prev,0),
		isnull(@attendance_ytd,0),
		isnull(@attendance_prev_ytd,0),
		@country_code,
		@country_name,
		@screening_date,
		@prev_screening_date,
		@year_start,
		@prev_year_start,
		isnull(@total_screens,0),
		isnull(@actual_screens,0)
	)
	
	fetch market_csr into @film_market_no, @film_market_desc, @country_code
end

deallocate market_csr

select * from #attendance_report order by film_market_no

return 0
GO
