/****** Object:  StoredProcedure [dbo].[p_fcsch_cl_market_breakdown_sub]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_fcsch_cl_market_breakdown_sub]
GO
/****** Object:  StoredProcedure [dbo].[p_fcsch_cl_market_breakdown_sub]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/********************************************************************************				
**				
**	DATE:		05/10/2006		
**	SUBMITTER:	Ricci Astudillo
**	DESCRIPTION:	store procedure to print cinelight_market breakdown
**				
**				
**				
********************************************************************************/				

/*
 * p_fcsch_cl_market_breakdown_sub
 * ------------------------
 *
 */

--SET QUOTED_IDENTIFIER OFF
--go
--SET ANSI_NULLS OFF
--go
--IF OBJECT_ID('dbo.p_fcsch_cl_market_breakdown_sub' ) IS NOT NULL
--BEGIN
--    DROP PROCEDURE dbo.p_fcsch_cl_market_breakdown_sub
--    IF OBJECT_ID('dbo.p_fcsch_cl_market_breakdown_sub') IS NOT NULL
--        PRINT '<<< FAILED DROPPING PROCEDURE dbo.p_fcsch_cl_market_breakdown_sub>>>'
--    ELSE
--        PRINT '<<< DROPPED PROCEDURE dbo.p_fcsch_cl_market_breakdown_sub>>>'
--END
--go

CREATE PROC [dbo].[p_fcsch_cl_market_breakdown_sub] @campaign_no	integer
    
as
-- drop table #screening_summary
--declare @campaign_no int
--set @campaign_no = 206259--301492

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
 */ create table #screening_summary
(	film_market_no		 	int,
	screened				integer,
	bonus					integer,
	charge_rate				decimal(18,2),
	screening_date			datetime,
	screening_month		varchar(30),
	screening_period	varchar(30)
)


select  @product_desc = fc.product_desc
from    film_campaign fc
where   fc.campaign_no = @campaign_no


/*
 * Declare cursors
 */

declare	market_csr cursor static for
select			distinct fm.film_market_no
from			cinelight_spot spot,
				cinelight cl,
				film_market fm,
				complex cmpl
where			spot.cinelight_id = cl.cinelight_id 
and				cl.complex_id = cmpl.complex_id
and 			cmpl.film_market_no = fm.film_market_no
and				spot.campaign_no = @campaign_no
union 
select			distinct fm.film_market_no
from			inclusion_spot spot,
				film_market fm,
				complex cmpl
where			spot.complex_id = cmpl.complex_id
and 			cmpl.film_market_no = fm.film_market_no
and				spot.campaign_no = @campaign_no
order by		fm.film_market_no



--declare screening date curser
declare	screening_date_csr cursor static for
select distinct screening_date
		    from cinelight_spot spot
		   where spot.campaign_no = @campaign_no and
   	             spot.spot_status not in ('D') 

open market_csr
fetch market_csr into @film_market_no
while(@@fetch_status = 0)
	begin

		open screening_date_csr
		fetch screening_date_csr into @screening_date
		while(@@fetch_status = 0)
			begin
			

			
				  select @screened = isnull(count(distinct spot.spot_id),0)
					from cinelight_spot spot,
						 cinelight cl,
						 complex cmpl
				   where spot.campaign_no = @campaign_no and
						 spot.cinelight_id = cl.cinelight_id and
						 cl.complex_id = cmpl.complex_id and
						 cmpl.film_market_no = @film_market_no and
   						 spot.spot_status not in ('D') and
						 spot.spot_type not in ('B')
						 and spot.screening_date = @screening_date

				  select @bonus = isnull(count(distinct spot.spot_id),0)
					from cinelight_spot spot,
						 cinelight cl,
						 complex cmpl
				   where spot.campaign_no = @campaign_no and
						 spot.cinelight_id = cl.cinelight_id and
						 cl.complex_id = cmpl.complex_id and
						 cmpl.film_market_no = @film_market_no and
   						 spot.spot_status not in ('D') and
						 spot.spot_type in ('B')
						 and spot.screening_date = @screening_date

				select	@charge_rate = isnull(sum(spot.charge_rate),0) 
				from	cinelight_spot spot,   
						cinelight cl,
						complex cmpl
				where	spot.cinelight_id = cl.cinelight_id and
						cl.complex_id = cmpl.complex_id and  
						spot.campaign_no = @campaign_no and
						cmpl.film_market_no = @film_market_no and
   						 spot.spot_status not in ('D')
   						 and spot.screening_date = @screening_date
				 
				  select @screened = @screened + isnull(count(distinct spot.spot_id),0)
					from inclusion_spot spot,
						 complex cmpl,
						 inclusion inc
				   where spot.campaign_no = @campaign_no and
						 spot.complex_id = cmpl.complex_id and
						 cmpl.film_market_no = @film_market_no and
   						 spot.spot_status not in ('D') and
						 spot.spot_type not in ('B') and
						inc.inclusion_id = spot.inclusion_id and
						inc.inclusion_type = 5
						and spot.screening_date = @screening_date

				  select @bonus = @bonus + isnull(count(distinct spot.spot_id),0)
					from inclusion_spot spot,
						 complex cmpl,
						 inclusion inc
				   where spot.campaign_no = @campaign_no and
						 spot.complex_id = cmpl.complex_id and
						 cmpl.film_market_no = @film_market_no and
   						 spot.spot_status not in ('D') and
						 spot.spot_type in ('B') and
						inc.inclusion_id = spot.inclusion_id and
						inc.inclusion_type = 5
						and spot.screening_date = @screening_date

				select	@charge_rate = @charge_rate + isnull(sum(spot.charge_rate),0)
				from	inclusion_spot spot,   
						complex cmpl,
						 inclusion inc
				where	spot.complex_id = cmpl.complex_id and  
						spot.campaign_no = @campaign_no and
						cmpl.film_market_no = @film_market_no and
   						 spot.spot_status not in ('D') and
						inc.inclusion_id = spot.inclusion_id and
						inc.inclusion_type = 5
						and spot.screening_date = @screening_date


				select 
			  	@screening_month = (DateName( month , DateAdd( month , period_no , -1))),
				@screening_period = (convert(char(6), start_date, 106) + ' - ' + convert(char(6), end_date, 106))
			    from [accounting_period]
			    where @screening_date between start_date and end_date
			   
				insert into #screening_summary
				(film_market_no, screened, bonus, charge_rate, screening_date, screening_month,screening_period) 
				values ( @film_market_no, @screened, @bonus, @charge_rate,@screening_date, @screening_month, @screening_period)
				
				
				fetch screening_date_csr into @screening_date
				
			end 
			
		 close screening_date_csr

		fetch market_csr into @film_market_no
	end 
	
deallocate market_csr 
deallocate screening_date_csr

select			@product_desc as 'product_desc',
				film_market_no,
				screened,
				bonus,
				charge_rate,
				screening_date,
				screening_month,
				screening_period,
				year(screening_date) as [year]
from			#screening_summary		
order by		film_market_no, 
				screening_date

end
--go

--GRANT EXECUTE ON dbo.p_fcsch_cl_market_breakdown_sub TO public
--go
--SET ANSI_NULLS OFF
--go
--SET QUOTED_IDENTIFIER OFF
--go
GO
