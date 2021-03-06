/****** Object:  StoredProcedure [dbo].[p_cinelight_programming_report_rep]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cinelight_programming_report_rep]
GO
/****** Object:  StoredProcedure [dbo].[p_cinelight_programming_report_rep]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create PROC [dbo].[p_cinelight_programming_report_rep] 	@campaign_no		integer,
											@screening_date					datetime
    
as

declare @product_desc varchar(100)

/*
 * Retrieve the client programming information
 */

select 	@product_desc = product_desc
from 	film_campaign fc
where 	campaign_no = @campaign_no

/*
 * Return Dataset
 */

select 		@screening_date as screening_date,
			@campaign_no as campaign_no,
			@product_desc as product_desc,
			pack.package_code,
			pack.package_desc,
			spot.spot_id,
			cplx.complex_name,
			cplx.film_market_no,
			cl.cinelight_desc
from 		cinelight_spot spot,
			cinelight_package pack,
			cinelight cl,
			complex cplx
where 		spot.campaign_no = @campaign_no
and			spot.package_id = pack.package_id
and			cl.complex_id = cplx.complex_id
and			spot.screening_date = @screening_date
and			spot.spot_status = 'X'
and			cl.cinelight_id = spot.cinelight_id
group by  	pack.package_code,
			pack.package_desc,
			spot.spot_id,
			cplx.complex_name,
			cplx.film_market_no,
			cl.cinelight_desc
GO
