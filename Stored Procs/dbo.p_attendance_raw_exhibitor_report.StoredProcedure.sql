/****** Object:  StoredProcedure [dbo].[p_attendance_raw_exhibitor_report]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_attendance_raw_exhibitor_report]
GO
/****** Object:  StoredProcedure [dbo].[p_attendance_raw_exhibitor_report]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_attendance_raw_exhibitor_report] 	@screening_date		datetime,
													@country_code		char(1)

as

declare		@error						integer,
			@exhibitor_id				integer,
			@exhibitor_name				varchar(30),	
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
			@actual_screens				int

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

create table #attendance_report
(
	exhibitor_id				integer			not null,
	exhibitor_name				varchar(30)		not null,	
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

declare		exhibitor_csr cursor static forward_only for
select		distinct complex.exhibitor_id,
			exhibitor_name
from		complex,
			exhibitor,
			attendance_raw,
            branch
where		complex.complex_id = attendance_raw.complex_id
and			(attendance_raw.screening_date <= @screening_date
or			attendance_raw.screening_date >= @prev_year_start)
and			complex.exhibitor_id = exhibitor.exhibitor_id
and         complex.branch_code = branch.branch_code
and			branch.country_code = @country_code
group by 	complex.exhibitor_id,
			exhibitor_name

open exhibitor_csr
fetch exhibitor_csr into @exhibitor_id, @exhibitor_name
while(@@fetch_status=0)
begin

	declare		market_csr cursor static forward_only for 
	select		distinct film_market.film_market_no,
				film_market.film_market_desc,
				branch.country_code
	from		complex,
				attendance_raw,
				film_market,
				branch
	where		complex.complex_id = attendance_raw.complex_id
	and			(attendance_raw.screening_date <= @screening_date
	or			attendance_raw.screening_date >= @prev_year_start)
	and			complex.film_market_no = film_market.film_market_no
	and			complex.branch_code = branch.branch_code
	and			exhibitor_id = @exhibitor_id
	and 		branch.country_code = @country_code
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

		select 	@actual_screens = count(distinct complex_id)
		from	complex
		where	complex.complex_id in (	select distinct complex_id from attendance_raw 
										where	screening_date <= @screening_date
                                        and     screening_date >= @year_start)
		and		complex.film_market_no = @film_market_no
		and		complex.exhibitor_id = @exhibitor_id
	
		select 	@total_screens = count(distinct complex_id)
		from	complex
		where	complex.complex_id in (	select distinct complex_id from attendance_raw 
										where	screening_date <= @prev_screening_date
                                        and     screening_date >= @prev_year_start)
		and		complex.film_market_no = @film_market_no
		and		complex.exhibitor_id = @exhibitor_id
	
		select 	@attendance = sum(attendance)
		from	attendance_raw,
				complex
		where	screening_date = @screening_date
		and		complex.complex_id = attendance_raw.complex_id
		and		complex.exhibitor_id = @exhibitor_id
		and		complex.film_market_no = @film_market_no
        		
		select 	@attendance_prev = sum(attendance)
		from	attendance_raw,
				complex
		where	screening_date = @prev_screening_date
		and		complex.complex_id = attendance_raw.complex_id
		and		complex.exhibitor_id = @exhibitor_id
		and		complex.film_market_no = @film_market_no
        		
		select 	@attendance_ytd = sum(attendance)
		from	attendance_raw,
				complex
		where	screening_date <= @screening_date
		and		screening_date >= @year_start
		and		complex.complex_id = attendance_raw.complex_id
		and		complex.exhibitor_id = @exhibitor_id
		and		complex.film_market_no = @film_market_no
		
		select 	@attendance_prev_ytd = sum(attendance)
		from	attendance_raw,
				complex
		where	screening_date <= @prev_screening_date
		and		screening_date >= @prev_year_start
		and		complex.complex_id = attendance_raw.complex_id
		and		complex.exhibitor_id = @exhibitor_id
		and		complex.film_market_no = @film_market_no
        
        if @attendance_prev_ytd is not null or @attendance_ytd is not null
        begin
		    insert into #attendance_report
		    (
			    exhibitor_id,
			    exhibitor_name,	
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
			    actual_screens
		    )	values
		    (
			    @exhibitor_id,
			    @exhibitor_name,	
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
        end		

		fetch market_csr into @film_market_no, @film_market_desc, @country_code
	end

	deallocate market_csr

	fetch exhibitor_csr into @exhibitor_id, @exhibitor_name
end

deallocate exhibitor_csr
select * from #attendance_report order by exhibitor_name, film_market_no
return 0
GO
