/****** Object:  StoredProcedure [dbo].[p_fcsch_cm_market_breakdown_sub]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_fcsch_cm_market_breakdown_sub]
GO
/****** Object:  StoredProcedure [dbo].[p_fcsch_cm_market_breakdown_sub]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--USE [acceptance]
--GO
--/****** Object:  StoredProcedure [dbo].[p_fcsch_cm_market_breakdown_sub]    Script Date: 04/03/2014 13:35:19 ******/
--SET ANSI_NULLS ON
--GO
--SET QUOTED_IDENTIFIER ON
--GO



CREATE PROC [dbo].[p_fcsch_cm_market_breakdown_sub] @campaign_no	integer
    
as
--drop table #screening_summary
--declare @campaign_no int

--set @campaign_no = 400615

declare @product_desc 			varchar(100),
		@film_market_no			integer,
		@screened				integer,
		@bonus					integer,
		@screened_not_movie		integer,
		@charge_rate			decimal(18,2),
		@screening_date			datetime,
		@screening_month		varchar(30),
		@screening_period		varchar(30)

begin

/*
 * Create Temporary Tables
 */ 
 
create table #screening_summary
(	
	film_market_no		 	int,
	screened				integer,
	bonus					integer,
	charge_rate				decimal(18,2),
	screening_date			datetime,
	screening_month			varchar(30),
	screening_period		varchar(30)
)


select  @product_desc = fc.product_desc
from    film_campaign fc
where   fc.campaign_no = @campaign_no

/*
 * Declare cursors
 */
declare			market_csr cursor static for
select			distinct fm.film_market_no
from			inclusion_spot spot,
				film_market fm,
				complex cmpl,
				inclusion inc
where			spot.complex_id = cmpl.complex_id
and				cmpl.film_market_no = fm.film_market_no
and				spot.inclusion_id = inc.inclusion_id
and				spot.campaign_no = @campaign_no
and				spot_status <> 'D'
and				spot_type not in ('M','V')
and				inc.inclusion_type = 5
order by		fm.film_market_no


--declare screening date curser
declare	screening_date_csr cursor static for
select distinct screening_date
from inclusion_spot spot
where spot.campaign_no = @campaign_no and
spot.spot_status not in ('D') and
spot.spot_type not in ('M', 'V', 'B', 'R') 


open market_csr
fetch market_csr into @film_market_no
while(@@fetch_status = 0)
	begin
	
	--print @film_market_no
	
	open screening_date_csr
		fetch screening_date_csr into @screening_date
		while(@@fetch_status = 0)
			begin
			
				
				  select @screened = count(distinct spot.spot_id)
					from inclusion_spot spot,
						 complex cmpl,
						 inclusion inc
				   where spot.campaign_no = @campaign_no and
						 spot.complex_id = cmpl.complex_id and
						 cmpl.film_market_no = @film_market_no and
   						 spot.spot_status not in ('D') and
						 spot.spot_type not in ('M', 'V', 'B', 'R') and
						 spot.inclusion_id = inc.inclusion_id and 
						 inc.inclusion_type = 5
						 and spot.screening_date = @screening_date

				  select @bonus = count(distinct spot.spot_id)
					from inclusion_spot spot,
						 complex cmpl,
						 inclusion inc
				   where spot.campaign_no = @campaign_no and
						 spot.complex_id = cmpl.complex_id and
						 cmpl.film_market_no = @film_market_no and
   						 spot.spot_status not in ('D') and
						 spot.spot_type in ('B') and
						 spot.inclusion_id = inc.inclusion_id and 
						 inc.inclusion_type = 5
						 and spot.screening_date = @screening_date

				select	@charge_rate = sum(charge_rate) 
				from	inclusion_spot spot,   
						complex,
						inclusion inc
				where	spot.complex_id = complex.complex_id and  
						spot.campaign_no = @campaign_no and
						complex.film_market_no = @film_market_no and
						spot.spot_status not in ('D') and
						spot.spot_type not in ('M', 'V') and
						spot.inclusion_id = inc.inclusion_id and 
						inc.inclusion_type = 5
						and spot.screening_date = @screening_date
						
						
				select 
			  	@screening_month = (DateName( month , DateAdd( month , period_no , -1))),
				@screening_period = (convert(char(6), start_date, 106) + ' - ' + convert(char(6), end_date, 106))
			    from [accounting_period]
			    where @screening_date between start_date and end_date
				 
				insert into #screening_summary (film_market_no, screened, bonus, charge_rate, screening_date, screening_month,screening_period) 
				values ( @film_market_no, @screened, @bonus, @charge_rate, @screening_date,  @screening_month, @screening_period)
				
				fetch screening_date_csr into @screening_date
				
			end 
			
		 close screening_date_csr

		fetch market_csr into @film_market_no
	end 
	
deallocate market_csr 
deallocate screening_date_csr

select			@product_desc as 'product_desc',
				film_market_no,
				sum(isnull(screened,0)) as screened,
				sum(isnull(bonus,0)) as bonus,
				sum(isnull(charge_rate,0)) as charge_rate,
			--	screening_date,
				screening_month,
				screening_period,
				max(YEAR(screening_date)) as [year]
from			#screening_summary
group by		film_market_no,
				screened,
				bonus,
				charge_rate,
				screening_month,
				screening_period
order by		film_market_no, 
				screening_period, 
				screening_month
		

end
GO
