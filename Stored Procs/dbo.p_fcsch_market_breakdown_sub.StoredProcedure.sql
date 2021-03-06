/****** Object:  StoredProcedure [dbo].[p_fcsch_market_breakdown_sub]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_fcsch_market_breakdown_sub]
GO
/****** Object:  StoredProcedure [dbo].[p_fcsch_market_breakdown_sub]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--USE [acceptance]
--GO
--/****** Object:  StoredProcedure [dbo].[p_fcsch_market_breakdown_sub]    Script Date: 04/03/2014 15:22:34 ******/
--SET ANSI_NULLS ON
--GO
--SET QUOTED_IDENTIFIER ON
--GO

CREATE PROC [dbo].[p_fcsch_market_breakdown_sub] @campaign_no	integer
    
as

--drop table #screening_summary
--declare @campaign_no int 
--set @campaign_no = 208155

declare		@product_desc 				varchar(100),
				@film_market_no			integer,
				@screened						integer,
				@bonus								integer,
				@screened_not_movie		integer,
				@charge_rate					decimal(18,2),
				@screening_date				datetime,
				@screening_month			varchar(30),
				@screening_period			varchar(30),
				@benchmark_end				datetime

begin

/*
 * Create Temporary Tables
 */
 
 create table #screening_summary
(	
	film_market_no		 	int,
	screened						integer,
	bonus							integer,
	charge_rate					decimal(18,2),
	screening_date			datetime,
	screening_month			varchar(30),
	screening_period			varchar(30),
	benchmark_end			datetime
)


select		@product_desc = product_desc
from			film_campaign 
where		campaign_no = @campaign_no


/*
 * Declare cursors
 */

declare		market_csr cursor static for
select		fm.film_market_no, 
				benchmark_end
from			campaign_spot spot,
				film_market fm,
				complex cmpl,
				film_screening_date_xref as fsdx
where		spot.complex_id = cmpl.complex_id
and 			cmpl.film_market_no = fm.film_market_no
and			spot.campaign_no = @campaign_no
and			fsdx.screening_date = spot.screening_date
and			spot_status <> 'D'
and			spot_type not in ('M','V', 'R')
group by	fm.film_market_no, 
				benchmark_end
union
select		fm.film_market_no, 
				benchmark_end
from			cinelight_spot spot,
				cinelight cl,
				film_market fm,
				complex cmpl,
				film_screening_date_xref as fsdx
where		spot.cinelight_id = cl.cinelight_id
and			cl.complex_id = cmpl.complex_id
and 			cmpl.film_market_no = fm.film_market_no
and			spot.campaign_no = @campaign_no
and			fsdx.screening_date = spot.screening_date
and			spot_status <> 'D'
and			spot_type not in ('M','V', 'R')
group by	fm.film_market_no, 
				benchmark_end
union
select		fm.film_market_no, 
				benchmark_end
from			inclusion_spot spot,
				film_market fm,
				complex cmpl,
				film_screening_date_xref as fsdx
where		spot.complex_id = cmpl.complex_id
and 			cmpl.film_market_no = fm.film_market_no
and			spot.campaign_no = @campaign_no
and			fsdx.screening_date = spot.screening_date
and			spot_status <> 'D'
and			spot_type not in ('M','V', 'R')
and			inclusion_id in (select		inclusion_id 
										from			inclusion 
										where		campaign_no = @campaign_no 
										and			inclusion_type = 5)
group by	fm.film_market_no, 
				benchmark_end
order by	fm.film_market_no, 
				benchmark_end

open market_csr
fetch market_csr into @film_market_no, @benchmark_end
while(@@fetch_status = 0)
begin
	
	select		@screened = count(distinct spot.spot_id)
	from			campaign_spot spot,
					complex cmpl,
					film_screening_date_xref as fsdx
	where		spot.campaign_no = @campaign_no 
	and			spot.complex_id = cmpl.complex_id 
	and			cmpl.film_market_no = @film_market_no 
	and			fsdx.screening_date = spot.screening_date 
	and			spot.spot_status not in ('D') 
	and			spot.spot_type not in ('M', 'V', 'B', 'R')
	and			fsdx.benchmark_end = @benchmark_end

	select		@bonus = count(distinct spot.spot_id)
	from			campaign_spot spot,
					complex cmpl,
					film_screening_date_xref as fsdx
	where		spot.campaign_no = @campaign_no 
	and			spot.complex_id = cmpl.complex_id 
	and			fsdx.screening_date = spot.screening_date 
	and			cmpl.film_market_no = @film_market_no 
	and			spot.spot_status not in ('D') 
	and			spot.spot_type in ('B')
	and			fsdx.benchmark_end = @benchmark_end

	select		@charge_rate = isnull(sum(charge_rate) ,0)
	from			campaign_spot,   
					complex,
					film_screening_date_xref as fsdx
	where		campaign_spot.complex_id = complex.complex_id 
	and			campaign_spot.campaign_no = @campaign_no 
	and			complex.film_market_no = @film_market_no 
	and			fsdx.screening_date = campaign_spot.screening_date 
	and			campaign_spot.spot_status not in ('D') 
	and			campaign_spot.spot_type not in ('M', 'V')
	and			fsdx.benchmark_end = @benchmark_end
				 
	select		@screened = @screened + count(distinct spot.spot_id)
	from			cinelight_spot spot,
					complex cmpl,
					film_screening_date_xref as fsdx,
					cinelight cl
	where		spot.campaign_no = @campaign_no 
	and			spot.cinelight_id = cl.cinelight_id
	and			cl.complex_id = cmpl.complex_id
	and 			cmpl.film_market_no = @film_market_no 
	and			fsdx.screening_date = spot.screening_date 
	and			spot.spot_status not in ('D') 
	and			spot.spot_type not in ('M', 'V', 'B', 'R')
	and			fsdx.benchmark_end = @benchmark_end
	
	select		@bonus = @bonus + count(distinct spot.spot_id)
	from			cinelight_spot spot,
					complex cmpl,
					film_screening_date_xref as fsdx,
					cinelight cl
	where		spot.campaign_no = @campaign_no 
	and			spot.cinelight_id = cl.cinelight_id
	and			cl.complex_id = cmpl.complex_id
	and 			fsdx.screening_date = spot.screening_date 
	and			cmpl.film_market_no = @film_market_no 
	and			spot.spot_status not in ('D') 
	and			spot.spot_type in ('B')
	and			fsdx.benchmark_end = @benchmark_end
	
	select		@charge_rate = @charge_rate + isnull(sum(charge_rate) ,0)
	from			cinelight_spot,   
					complex,
					film_screening_date_xref as fsdx,
					cinelight cl
	where		cinelight_spot.campaign_no = @campaign_no 
	and			cinelight_spot.cinelight_id = cl.cinelight_id
	and			cl.complex_id = complex.complex_id
	and 			complex.film_market_no = @film_market_no 
	and			fsdx.screening_date = cinelight_spot.screening_date 
	and			cinelight_spot.spot_status not in ('D') 
	and			cinelight_spot.spot_type not in ('M', 'V')
	and			fsdx.benchmark_end = @benchmark_end
	
	select		@screened = @screened + count(distinct spot.spot_id)
	from			inclusion_spot spot,
					complex cmpl,
					film_screening_date_xref as fsdx
	where		spot.campaign_no = @campaign_no 
	and			spot.complex_id = cmpl.complex_id 
	and			cmpl.film_market_no = @film_market_no 
	and			fsdx.screening_date = spot.screening_date 
	and			spot.spot_status not in ('D') 
	and			spot.spot_type not in ('M', 'V', 'B', 'R')
	and			fsdx.benchmark_end = @benchmark_end
	and 			inclusion_id in (select inclusion_id from inclusion where inclusion_type = 5) 
	
	select		@bonus = @bonus + count(distinct spot.spot_id)
	from			inclusion_spot spot,
					complex cmpl,
					film_screening_date_xref as fsdx
	where		spot.campaign_no = @campaign_no 
	and			spot.complex_id = cmpl.complex_id 
	and			fsdx.screening_date = spot.screening_date 
	and			cmpl.film_market_no = @film_market_no 
	and			spot.spot_status not in ('D') 
	and			spot.spot_type in ('B')
	and			fsdx.benchmark_end = @benchmark_end
	and 			inclusion_id in (select inclusion_id from inclusion where inclusion_type = 5) 
	
	select		@charge_rate = @charge_rate + isnull(sum(charge_rate) ,0)
	from			inclusion_spot,   
					complex,
					film_screening_date_xref as fsdx
	where		inclusion_spot.complex_id = complex.complex_id 
	and			inclusion_spot.campaign_no = @campaign_no 
	and			complex.film_market_no = @film_market_no 
	and			fsdx.screening_date = inclusion_spot.screening_date 
	and			inclusion_spot.spot_status not in ('D') 
	and			inclusion_spot.spot_type not in ('M', 'V')
	and			fsdx.benchmark_end = @benchmark_end
	and 			inclusion_id in (select inclusion_id from inclusion where inclusion_type = 5) 	

	select		@screening_month = (DateName( month , DateAdd( month , period_no , -1))),
					@screening_period = (convert(char(6), start_date, 106) + ' - ' + convert(char(6), end_date, 106))
	from			accounting_period
	where		@benchmark_end = end_date
		 
	insert into #screening_summary
	(film_market_no, screened, bonus, charge_rate, screening_date, screening_month,screening_period, benchmark_end) 
	values ( @film_market_no, @screened, @bonus, @charge_rate, @screening_date, @screening_month, @screening_period, @benchmark_end)
		

		 
	fetch market_csr into @film_market_no, @benchmark_end
end 
	
deallocate market_csr 

select	@product_desc as 'product_desc',
		film_market_no,
		screened,
		bonus,
		charge_rate,
	--	sum(isnull(screened,0)) as screened,
	--	sum(isnull(bonus,0)) as bonus,
	--	sum(isnull(charge_rate,0)) as charge_rate,
	--	screening_date,
		screening_month,
		screening_period,
		YEAR(benchmark_end) as [year]
from	#screening_summary		
--group by film_market_no,
--		screened,
--		bonus,
--		charge_rate,
--		screening_date,
--		screening_month,
--		screening_period
order by film_market_no,screening_date--, screening_month, screening_period

end
GO
