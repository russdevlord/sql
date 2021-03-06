/****** Object:  StoredProcedure [dbo].[p_certificate_makeups_max_screens]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_certificate_makeups_max_screens]
GO
/****** Object:  StoredProcedure [dbo].[p_certificate_makeups_max_screens]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_certificate_makeups_max_screens]	@complex_id			integer,
														@screening_date	   datetime
as

/*
 * Declare Variables
 */

declare @film_market_no             int,
		@bonus_allowed				char(1)

/*
 * Create Makeup Table
 */

create table #makeups
(
	campaign_no				int				null
)

select @film_market_no = film_market_no,
	   @bonus_allowed = bonus_allowed
  from complex
 where complex_id = @complex_id
         
/*
 * Insert Unallocations, No Shows, Makeups and Manuals into table
 */

insert into #makeups
select 	distinct fc.campaign_no
from 	film_campaign fc,
		campaign_spot spot,
		complex cplx
where 	fc.start_date <= @screening_date and
		fc.makeup_deadline >= @screening_date and
		fc.campaign_status = 'L' and
		fc.campaign_no = spot.campaign_no and
		spot.complex_id = cplx.complex_id and
		cplx.film_market_no = @film_market_no and
		fc.allow_market_makeups = 'Y' and
		spot.screening_date < @screening_date and
		spot.film_plan_id is null and
		spot.spot_redirect is null and
		(spot.spot_status = 'U' or
		spot.spot_status = 'N') and
		((@bonus_allowed = 'N' and
		cplx.complex_id = @complex_id) or
		(@bonus_allowed = 'Y' and
		cplx.bonus_allowed = 'Y' and
		@complex_id in (select complex_id from film_campaign_complex where campaign_no = fc.campaign_no) ))
       
insert into #makeups
select distinct fc.campaign_no
  from film_campaign fc,
       campaign_spot spot
 where fc.start_date <= @screening_date and
       fc.makeup_deadline >= @screening_date and
       fc.campaign_status = 'L' and
       fc.campaign_no = spot.campaign_no and
       spot.complex_id = @complex_id and
       fc.allow_market_makeups = 'N' and
       spot.screening_date < @screening_date and
       spot.spot_redirect is null and
	   spot.film_plan_id is null and
     ( spot.spot_status = 'U' or 
       spot.spot_status = 'N'  )       

/*
 * Return Result Set
 */

select		#makeups.campaign_no,
			temp_table.package_id, 
			isnull(max(temp_table.no_spots),0)
FROM	(select 	campaign_spot.campaign_no, 
					screening_date, 
					campaign_spot.package_id,
					count(spot_id) as no_spots
		from 		campaign_spot,
					#makeups
		where		campaign_spot.campaign_no = #makeups.campaign_no
		and			complex_id = @complex_id
		and			spot_type not in ('M','V')
		group by	campaign_spot.campaign_no, 
					campaign_spot.package_id,
					screening_date) as temp_table LEFT OUTER JOIN
					  #makeups ON #makeups.campaign_no = temp_table.campaign_no
group by 	#makeups.campaign_no,
			temp_table.package_id
GO
