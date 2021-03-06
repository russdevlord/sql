/****** Object:  StoredProcedure [dbo].[p_certificate_gen_details]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_certificate_gen_details]
GO
/****** Object:  StoredProcedure [dbo].[p_certificate_gen_details]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_certificate_gen_details]		@complex_id				integer,
																				@screening_date		datetime  
as

/*
 * Declare Variables
 */

declare	@error															int,
				@errorode														int,
				@count														int,
				@state_code     										char(3),
				@country_code										char(1),
				@school_holidays			    						char(1),
				@certificate_type   								tinyint,
				@trailers													char(1),
				@end_tag													int,
				@tap_min_ads											int,
				@tap_max_ads											int,
				@tap_priority_level									int,
				@tap_market_percent								numeric(6,4),
				@tap_permitted_variance_low				numeric(6,4),
				@tap_permitted_variance_high				numeric(6,4),
				@xml_count												int

/*
 * Get Country and State of the Cinema Complex
 */

select		@certificate_type = complex.certificate_type,
				@trailers = complex.include_trailers,
				@state_code = state.state_code,
				@country_code = state.country_code
from			complex,
				state
where		complex.complex_id = @complex_id 
and			complex.state_code = state.state_code

/*
 * Determine if its School Holidays 
 */

select		@count = isnull(count(screening_date),0)
from			school_holiday_xref
where		state_code = @state_code 
and			screening_date = @screening_date

if (@count > 0)
	select @school_holidays = 'Y'
else
	select @school_holidays = 'N'

/*
 * Get End Tag based on Contractor
 */

select		@end_tag = sc.end_tag
from			screen_contractor sc,
				complex c
where		c.contractor_code = sc.contractor_code 
and			c.complex_id = @complex_id

/*
 * Get TAP Settings for the week
 */

select			@tap_min_ads = spot_min_no,
					@tap_max_ads = spot_max_no,
					@tap_priority_level	 = priority_level,
					@tap_market_percent = percent_market
from				cinetam_complex_date_settings
where			complex_id = @complex_id
and				screening_date = @screening_date					

select			@tap_permitted_variance_low = 0.95
select			@tap_permitted_variance_high = 1.25

/*
 * Determine if complex is getting xml certificates or not
 */

select			@xml_count = count(*)
from				complex_ftp_path
where			complex_id = @complex_id

/*
 * Return Dataset
 */

select			campaign_safety_limit,
					clash_safety_limit,
					movie_target,
					session_target,
					max_ads,
					max_time,
					mg_max_ads,
					mg_max_time,
					cplx_max_ads,
					cplx_max_time,
					@school_holidays,
					@country_code,
					@certificate_type,
					@trailers,
					@end_tag,
					@tap_min_ads,
					@tap_max_ads,
					@tap_priority_level,
					@tap_market_percent,
					@tap_permitted_variance_low,
					@tap_permitted_variance_high,
					@xml_count
from 			complex_date
where 			complex_id = @complex_id 
and				screening_date = @screening_date
GO
