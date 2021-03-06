/****** Object:  StoredProcedure [dbo].[p_certificate_makeups]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_certificate_makeups]
GO
/****** Object:  StoredProcedure [dbo].[p_certificate_makeups]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_certificate_makeups] @complex_id			integer,
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
	campaign_no				int				null,
	campaign_start			datetime		null,
	makeup_deadline	    	datetime		null,
	spot_id					int				null,
    spot_status				char(1)			null,
	spot_type				char(1)			null,
    package_id				int				null,
    screening_date			datetime		null,
    makegood_rate           money           null,
    cinema_rate             money           null,
    charge_rate             money           null,
    same_complex            int             null,
    billing_date				datetime        null,
	campaign_type			int				null,
	film_plan_id				int				null
)

select @film_market_no = film_market_no,
	   @bonus_allowed = bonus_allowed
  from complex
 where complex_id = @complex_id
         
/*
 * Insert Unallocations, No Shows, Makeups and Manuals into table
 */

insert into #makeups
select 	fc.campaign_no,
		fc.start_date,
		fc.makeup_deadline,
		spot.spot_id,
		spot.spot_status,
		spot.spot_type,
		spot.package_id,
		spot.screening_date,
		spot.makegood_rate,
		spot.cinema_rate,
		spot.charge_rate,
		CASE cplx.complex_id WHEN @complex_id THEN 1 ELSE 2 END,
		spot.billing_date,
		fc.campaign_type,
		spot.film_plan_id
from 	film_campaign fc,
		campaign_spot spot,
		complex cplx,
	   campaign_package cp
 where cp.package_id = spot.package_id and
		fc.start_date <= @screening_date and
		fc.makeup_deadline >= @screening_date and
		fc.campaign_status = 'L' and
		fc.campaign_no = spot.campaign_no and
		spot.complex_id = cplx.complex_id and
		cplx.film_market_no = @film_market_no and
		fc.allow_market_makeups = 'Y' and
--		spot.screening_date < @screening_date and
		spot.screening_date <= @screening_date and
		cp.package_id not in (select package_id from inclusion_cinetam_package) and					
		spot.film_plan_id is null and
		spot.spot_redirect is null and
		cp.all_movies = 'S' and
		spot.spot_type not in ('F','T','K', 'A') and
		(spot.spot_status = 'U' or
		spot.spot_status = 'N') and
		((@bonus_allowed = 'N' and
		cplx.complex_id = @complex_id) or
		(@bonus_allowed = 'Y' and
		cplx.bonus_allowed = 'Y' and
		@complex_id in (select complex_id from film_campaign_complex where campaign_no = fc.campaign_no) ))
       
insert into #makeups
select fc.campaign_no,
       fc.start_date,
       fc.makeup_deadline,
       spot.spot_id,
       spot.spot_status,
       spot.spot_type,
       spot.package_id,
       spot.screening_date,
       spot.makegood_rate,
       spot.cinema_rate,
       spot.charge_rate,
       1,
       spot.billing_date,
	   fc.campaign_type,
	   spot.film_plan_id
  from film_campaign fc,
       campaign_spot spot,
	   campaign_package cp
 where cp.package_id = spot.package_id and
		fc.start_date <= @screening_date and
       fc.makeup_deadline >= @screening_date and
       fc.campaign_status = 'L' and
		cp.all_movies = 'S' and
       fc.campaign_no = spot.campaign_no and
       spot.complex_id = @complex_id and
		cp.package_id not in (select package_id from inclusion_cinetam_package) and					
       fc.allow_market_makeups = 'N' and
--       spot.screening_date < @screening_date and
       spot.screening_date <= @screening_date and
       spot.spot_redirect is null and
	   spot.film_plan_id is null and
	   spot.spot_type not in ('F','T','K', 'A') and
     ( spot.spot_status = 'U' or 
       spot.spot_status = 'N'  )       

/*
 * Return Result Set
 */

select 		mk.campaign_no,
			mk.campaign_start,
			mk.makeup_deadline,
			mk.package_id,
			cp.screening_position,
			cp.movie_brief,
			cp.school_holidays,
			fc.client_id,
			cp.follow_film,
			cp.client_clash,
			cp.certificate_priority,
			null,
			cp.media_product_id,
			mk.makegood_rate,
			mk.cinema_rate,
			mk.charge_rate,
			mk.spot_id,
			cp.follow_film_restricted,
			fc.allow_pack_clashing,
			cp.allow_product_clashing,
			mk.billing_date,
			fc.test_campaign,
			mk.same_complex,
			cp.premium_screen_type,
			cp.all_movies,
			cp.cinema_exclusive,
			cp.movie_band_variable,
			cp.used_by_date,
			cp.client_diff_product,
			cp.start_date,
			cp.screening_trailers,
			cp.movie_mix,
			cp.movie_bands,
			mk.campaign_type,
			0 as remove_row,
			mk.film_plan_id
from 		#makeups mk,
			film_campaign fc,
			campaign_package cp
where		mk.campaign_no = fc.campaign_no and
			fc.campaign_no = cp.campaign_no and
			cp.package_id not in (select package_id from inclusion_cinetam_package) and					
			cp.package_id = mk.package_id
order by 	mk.same_complex,
			fc.campaign_no,
			cp.package_id,
			mk.charge_Rate desc
GO
