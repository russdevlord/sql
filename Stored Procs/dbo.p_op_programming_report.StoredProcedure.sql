/****** Object:  StoredProcedure [dbo].[p_op_programming_report]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_op_programming_report]
GO
/****** Object:  StoredProcedure [dbo].[p_op_programming_report]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
create PROC [dbo].[p_op_programming_report] 	@film_campaign_program_id		integer,
											@screening_date					datetime
    
as

declare @campaign_no	integer,
        @product_desc varchar(100)

/*
 * Retrieve the client programming information
 */

select 	@campaign_no = fcp.campaign_no
from 	film_campaign_program fcp
where 	fcp.film_campaign_program_id = @film_campaign_program_id

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
			cplx.outpost_venue_name,
			cplx.market_no,
			cl.outpost_panel_desc
from 		outpost_spot spot,
			outpost_package pack,
			outpost_panel cl,
			outpost_venue cplx
where 		spot.campaign_no = @campaign_no
and			spot.package_id = pack.package_id
and			cl.outpost_venue_id = cplx.outpost_venue_id
and			spot.screening_date = @screening_date
and			spot.spot_status = 'X'
and			cl.outpost_panel_id = spot.outpost_panel_id
group by  	pack.package_code,
			pack.package_desc,
			spot.spot_id,
			cplx.outpost_venue_name,
			cplx.market_no,
			cl.outpost_panel_desc
GO
