/****** Object:  StoredProcedure [dbo].[p_cinetam_post_analysis_attendance_pool]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cinetam_post_analysis_attendance_pool]
GO
/****** Object:  StoredProcedure [dbo].[p_cinetam_post_analysis_attendance_pool]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_cinetam_post_analysis_attendance_pool]					@campaign_no											integer,
																																				@attendance_estimate_fifty_two			numeric(30,20) OUTPUT

as

declare			@screening_date																datetime,
						@metro_total																		int,
						@regional_total																	int,
						@cinetam_reporting_demographics_id					integer,
						@market																				varchar(30),
						@start_date																		datetime,
						@end_date																			datetime,
						@country_code																	char(1)
														
						
set nocount on						

/*
 * Initiliase Variables
 */ 

select				@market = cinetam_campaign_settings.market,
							@start_date = film_campaign.start_date,
							@country_code = cinetam_campaign_settings.country_code,
							@cinetam_reporting_demographics_id = cinetam_campaign_settings.cinetam_reporting_demographics_id
from					cinetam_campaign_settings,
							film_campaign
where				film_campaign.campaign_no = @campaign_no
and						film_campaign.campaign_no = cinetam_campaign_settings.campaign_no

select				@end_date = dateadd(wk, 51, @start_date)

/*
 * Determine Attendance Based on Reach Freq Mode
 */

declare		screening_date_csr cursor static for
select		screening_date
from			film_screening_dates
where		screening_date between @start_date and @end_date
order by	screening_date

open screening_date_csr
fetch screening_date_csr into @screening_date
while(@@fetch_status = 0)
begin

	select		@metro_total = 	 isnull(sum(isnull(total_attendance,0)),0)
	from			v_cinetam_movie_history_rfmkt,
						cinetam_reachfreq_market_xref
	where		cinetam_reachfreq_market_xref.film_market_no = v_cinetam_movie_history_rfmkt.film_market_no
	and				v_cinetam_movie_history_rfmkt.screening_date =  dbo.f_prev_attendance_screening_date(@screening_date)
	and				v_cinetam_movie_history_rfmkt.complex_region_class = 'M'
	and				cinetam_reachfreq_market_xref.market = @market
	and            v_cinetam_movie_history_rfmkt.country = cinetam_reachfreq_market_xref.country_code
	and				v_cinetam_movie_history_rfmkt.country = @country_code
	and				cinetam_reachfreq_market_xref.mode  = 1
	and				v_cinetam_movie_history_rfmkt.cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id
	
	select		@regional_total = isnull(sum(isnull(total_attendance,0)),0)
	from			v_cinetam_movie_history_rfmkt,
						cinetam_reachfreq_market_xref
	where		cinetam_reachfreq_market_xref.film_market_no = v_cinetam_movie_history_rfmkt.film_market_no
	and				v_cinetam_movie_history_rfmkt.screening_date =  dbo.f_prev_attendance_screening_date(@screening_date)
	and				v_cinetam_movie_history_rfmkt.complex_region_class != 'M'
	and				cinetam_reachfreq_market_xref.market = @market
	and				cinetam_reachfreq_market_xref.mode  = 1
	and            v_cinetam_movie_history_rfmkt.country = cinetam_reachfreq_market_xref.country_code
	and				v_cinetam_movie_history_rfmkt.country = @country_code
	and				v_cinetam_movie_history_rfmkt.cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id

	select 		@attendance_estimate_fifty_two = isnull(@attendance_estimate_fifty_two,0) +  @metro_total + @regional_total
	
	fetch screening_date_csr into @screening_date
end
	
		
return 0
GO
