/****** Object:  StoredProcedure [dbo].[p_cinelight_weekly_showings]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cinelight_weekly_showings]
GO
/****** Object:  StoredProcedure [dbo].[p_cinelight_weekly_showings]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_cinelight_weekly_showings]  	@campaign_no 		int,
											@screening_date		datetime

as

/*
 * Return Campaign Evaluation
 */

select 		@campaign_no,
			fc.product_desc,   
			fc.campaign_status,
			min(screening_date),
			max(screening_date),
			client_name,
			agency_name,
			country_name,
			country.country_code,
			cinelight_package.package_code,
			package_desc,
			screening_date,
			complex_name,
			cinelight_desc,
			film_market.film_market_no,
			film_market_desc,
			(select isnull(sum(showings),0) from cinelight_attendance_digilite_actuals where cinelight_id = cinelight_spot.cinelight_id and screening_date = cinelight_spot.screening_date and campaign_no = cinelight_spot.campaign_no) as showings,
			(select max(screening_date) from cinelight_attendance_digilite_actuals where campaign_no = cinelight_spot.campaign_no) as showings_date
from 		film_campaign fc,
			agency,
			client,
			cinelight_spot,
			cinelight_package,
			cinelight,
			complex,
			film_market,
			branch,
			country
where 		fc.campaign_no = @campaign_no
and			cinelight_spot.screening_date = @screening_date
and			fc.agency_id = agency.agency_id
and			fc.client_id = client.client_id
and			fc.campaign_no = cinelight_package.campaign_no
and			fc.campaign_no = cinelight_spot.campaign_no
and			cinelight_spot.campaign_no = cinelight_package.campaign_no
and			cinelight_spot.package_id = cinelight_package.package_id
and			cinelight_spot.cinelight_id = cinelight.cinelight_id
and			cinelight.complex_id = complex.complex_id
and			complex.film_market_no = film_market.film_market_no
and			complex.branch_code = branch.branch_code
and			branch.country_code = country.country_code
and			spot_status = 'X'
group by 	fc.product_desc,   
			fc.campaign_status,
			client_name,
			agency_name,
			country_name,
			country.country_code,
			cinelight_package.package_code,
			package_desc,
			screening_date,
			complex_name,
			cinelight_desc,
			film_market.film_market_no,
			film_market_desc,
			cinelight_spot.cinelight_id,
			cinelight_spot.campaign_no

/*
 * Return Success
 */

return 0
GO
