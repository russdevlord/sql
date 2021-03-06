/****** Object:  StoredProcedure [dbo].[p_attendance_raw_market]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_attendance_raw_market]
GO
/****** Object:  StoredProcedure [dbo].[p_attendance_raw_market]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create proc [dbo].[p_attendance_raw_market]		@start_date			datetime,
										@end_date			datetime,
										@country_code		char(1)

as

declare 		@error						int,
				@attendance					int,
				@attendance_py				int,
				@film_market_no				int,
				@film_market_desc			varchar(30),
				@start_period_no			int,
				@end_period_no				int,
				@prev_start_date			datetime,
				@prev_end_date				datetime,
				@start_year_end				datetime,
				@end_year_end				datetime

				
set nocount on

create table #raw_market
(
	start_date			datetime		null,
	end_date			datetime		null,
	prev_start_date		datetime		null,
	prev_end_date		datetime		null,
	country_code		char(1)			null,
	film_market_no		int				null,
	film_market_desc	varchar(30)		null,
	attendance			int				null,
	attendance_py		int				null
)

select 		@start_period_no = attendance_period_no,
			@start_year_end = attendance_year_end
from		film_screening_dates 
where		screening_date = @start_date

select 		@end_period_no = attendance_period_no,
			@end_year_end = attendance_year_end
from		film_screening_dates 
where		screening_date = @end_date

select 		@prev_start_date = screening_date
from		film_screening_dates
where		attendance_year_end < @start_year_end
and			attendance_period_no = @start_period_no 

select 		@prev_end_date = screening_date
from		film_screening_dates
where		attendance_year_end < @end_year_end
and			attendance_period_no = @end_period_no 

declare		market_csr cursor static forward_only for
select 		film_market_no,
			film_market_desc
from		film_market
where		film_market_no in (select film_market_no from complex, branch where complex.branch_code = branch.branch_code and country_code = @country_code)
order by 	film_market_no

open market_csr
fetch market_csr into @film_market_no, @film_market_desc
while(@@fetch_status=0)
begin

	select 		@attendance = sum(attendance_raw.attendance)
	from		attendance_raw,   
				complex,
				branch
	where 		attendance_raw.complex_id = complex.complex_id
	and			complex.film_market_no = @film_market_no
	and         attendance_raw.screening_date >= @start_date
	and         attendance_raw.screening_date <= @end_date
	and			complex.branch_code = branch.branch_code
	and			branch.country_code = @country_code

	select 		@attendance_py = sum(attendance_raw.attendance)
	from		attendance_raw,   
				complex,
				branch
	where 		attendance_raw.complex_id = complex.complex_id
	and			complex.film_market_no = @film_market_no
	and         attendance_raw.screening_date >= @prev_start_date
	and         attendance_raw.screening_date <= @prev_end_date
	and			complex.branch_code = branch.branch_code
	and			branch.country_code = @country_code

	insert into #raw_market
	(
	start_date,
	end_date,
	prev_start_date,
	prev_end_date,
	country_code,
	film_market_no,
	film_market_desc,
	attendance,
	attendance_py	
	) values
	(
	@start_date,
	@end_date,
	@prev_start_date,
	@prev_end_date,
	@country_code,
	@film_market_no,
	@film_market_desc,
	@attendance,
	@attendance_py
	)

	fetch market_csr into @film_market_no, @film_market_desc
end

deallocate market_csr

select * from #raw_market
return 0
GO
