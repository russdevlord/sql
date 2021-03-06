/****** Object:  StoredProcedure [dbo].[p_attendance_weekly_cumgraph_report]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_attendance_weekly_cumgraph_report]
GO
/****** Object:  StoredProcedure [dbo].[p_attendance_weekly_cumgraph_report]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_attendance_weekly_cumgraph_report] @screening_date		datetime,
											 @country_code			char(1)

as

declare		@error					integer,
			@attendance				integer,
			@attendance_prev		integer,
			@billings				money,
			@billings_prev			money,
			@prev_screening_date	datetime,
			@attendance_period_no	int,
			@year_start				datetime,
			@prev_year_start		datetime,
			@year_end				datetime,
			@prev_year_end			datetime,
			@process_date			datetime,
			@prev_process_date		datetime

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

select 	@year_end = attendance_year_end 
from 	film_screening_dates
where 	screening_date = @screening_date

select 	@prev_year_start = min(screening_date)
from	film_screening_dates 
where	attendance_year_end in (select 	attendance_year_end 
								from 	film_screening_dates
								where 	screening_date = @prev_screening_date)

select 	@prev_year_end = attendance_year_end 
from 	film_screening_dates
where 	screening_date = @prev_screening_date


create table #attendance_report
(
	attendance				integer			not null,
	attendance_prev			integer			not null,
	billings				money			not null,
	billings_prev			money			not null,
	screening_date			datetime		not null,
	prev_screening_date		datetime		not null
)

create table #attendance_billings
(
	screening_date			datetime		not null,
	billings				money			not null
)


insert into #attendance_billings
select      billing_date,
			sum(isnull(cs.charge_rate,0)) 
from        v_spots_non_proposed cs,
            campaign_package cp,
            film_campaign fc,
			branch b
where       cs.billing_date <= @screening_date
and			cs.billing_date >= @prev_year_start
and         cs.package_id = cp.package_id
and         cp.campaign_no = fc.campaign_no
and			fc.branch_code = b.branch_code
and			b.country_code = @country_code
group by 	billing_date

declare		date_csr cursor static forward_only for 
select		distinct screening_date
from		film_screening_dates
where		screening_date <= @screening_date
and			screening_date >= @year_start
order by 	screening_date

select @attendance =0,
@attendance_prev = 0,
@billings = 0,
@billings_prev = 0

open date_csr
fetch date_csr into @process_date
while(@@fetch_Status=0)
begin

	select 	@attendance_period_no = attendance_period_no
	from	film_screening_dates
	where 	screening_date = @process_date 
	
	select 	@prev_process_date = max(screening_date)
	from	film_screening_dates
	where	attendance_period_no = @attendance_period_no
	and		screening_date < @process_date

	select 	@attendance = @attendance + sum(attendance)
	from	movie_history
	where	screening_date = @process_date
	and		country = @country_code
	
	select 	@attendance_prev = @attendance_prev + sum(attendance)
	from	movie_history
	where	screening_date = @prev_process_date
	and		country = @country_code
	
    select      @billings = @billings + billings
    from        #attendance_billings
    where       screening_date = @process_date

    select      @billings_prev = @billings_prev + billings
    from        #attendance_billings
    where       screening_date = @prev_process_date


	insert into #attendance_report
	(
		attendance,
		attendance_prev,
		billings,
		billings_prev,
		screening_date,
		prev_screening_date
	)	values
	(
		isnull(@attendance,0),
		isnull(@attendance_prev,0),
		isnull(@billings,0),
		isnull(@billings_prev,0),
		@process_date,
		@prev_process_date
	)
	

	fetch date_csr into @process_date
end

deallocate date_csr

select *, @year_end, @prev_year_end from #attendance_report order by screening_date
return 0
GO
