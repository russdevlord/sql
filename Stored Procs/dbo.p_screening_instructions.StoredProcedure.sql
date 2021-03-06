/****** Object:  StoredProcedure [dbo].[p_screening_instructions]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_screening_instructions]
GO
/****** Object:  StoredProcedure [dbo].[p_screening_instructions]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_screening_instructions] 	@campaign_no 		int,
												@screening_date	    datetime,
												@package_id			int
as
				
DECLARE	@scheduled_scr		INT
DECLARE	@standby_scr		INT
DECLARE	@scr_missed			INT
DECLARE	@scr_makeups		INT
DECLARE	@next_scheduled_scr	INT
DECLARE @next_standby_scr	INT

select	@scheduled_scr = SUM( CASE When spot.screening_date = @screening_date Then 
				( CASE When spot.spot_status IN ('P','A','X') and spot.spot_type IN ('S','B','C','D','N') Then 1 Else 0 End) Else 0 End),
		@next_scheduled_scr = SUM( CASE When spot.screening_date = dateadd(wk, 1, @screening_date) Then 
				( CASE When spot.spot_status IN ('P','A','X') and spot.spot_type IN ('S','B','C','D','N') Then 1 Else 0 End) Else 0 End),
		@scr_missed = SUM( CASE When spot.screening_date <= @screening_date Then 
				( CASE When spot.spot_status IN ('N','U') Then 1 Else 0 End) Else 0 End),
		@scr_makeups = SUM( CASE When spot.screening_date <= @screening_date Then 
				( CASE When spot.spot_status IN ('X') and spot.spot_type IN ('M','V') Then 1 Else 0 End) Else 0 End)				
from	campaign_spot spot
where	spot.campaign_no = @campaign_no and
		spot.package_id = @package_id
	
select	@standby_scr = COUNT( CASE When film_plan_dates.screening_date = @screening_date Then film_plan_complex.max_screens Else NULL End),
		@next_standby_scr = COUNT( CASE When film_plan_dates.screening_date = dateadd(wk, 1, @screening_date) Then film_plan_complex.max_screens Else NULL End)
from	film_plan, 
		film_plan_dates, 
		film_plan_complex
where	film_plan.film_plan_id = film_plan_dates.film_plan_id and
		film_plan.film_plan_id = film_plan_complex.film_plan_id and
		film_plan.campaign_no = @campaign_no and
		film_plan.package_id = @package_id
		
select	fc.campaign_no,   
		fc.rep_id,
		fc.product_desc,
		fc.client_id,   
		fc.agency_id,
		fc.start_date,
		fc.end_date,
		fc.makeup_deadline,
		fc.campaign_type,
		fc.commission,
		fc.confirmed_cost,
		fc.confirmed_value,
		cp.package_code,
		cp.package_desc,
		cp.prints,   
		cp.product_category,   
		cp.screening_position,   
		cp.screening_trailers,   
		cp.school_holidays,   
		cp.movie_brief,
		cp.used_by_date,   
		cp.duration,
		cp.follow_film,
		cp.movie_mix,   
		cp.movie_bands,   
		fc.allow_market_makeups,
		fc.allow_pack_clashing,
		cp.start_date,
		cp.follow_film_restricted,
		cp.client_diff_product,
		cp.client_clash,
		cp.allow_product_clashing,
		scheduled_scr = CASE When @screening_date IS NULL Then -1 Else @scheduled_scr End,
		standby_scr = CASE When @screening_date IS NULL Then -1 Else @standby_scr End,
		scr_missed = CASE When @screening_date IS NULL Then -1 Else @scr_missed End,
		scr_makeups = CASE When @screening_date IS NULL Then -1 Else @scr_makeups End,
		next_scheduled_scr = CASE When @screening_date IS NULL Then -1 Else @next_scheduled_scr End,
		next_standby_scr = CASE When @screening_date IS NULL Then -1 Else @next_standby_scr End,
		cp.package_id,
		screening_date = @screening_date,
		cp.media_product_id,
		fc.contact,
		fc.phone,
		fc.email,
		cp.allow_3d,
		cp.dimension_preference,
		product_subcategory = CONVERT(VARCHAR(30), NULL),--cp.product_subcategory,				-- DYI 2012-09-13
		allow_subcategory_clashing = CONVERT(VARCHAR(1), NULL)--cp.allow_subcategory_clashing		-- DYI 2012-09-13
from	film_campaign fc,
		campaign_package cp
where	fc.campaign_no = cp.campaign_no and 
		fc.campaign_no = @campaign_no and
		cp.package_id = @package_id

return 0
GO
