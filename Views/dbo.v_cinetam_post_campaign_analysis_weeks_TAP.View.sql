/****** Object:  View [dbo].[v_cinetam_post_campaign_analysis_weeks_TAP]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_cinetam_post_campaign_analysis_weeks_TAP]
GO
/****** Object:  View [dbo].[v_cinetam_post_campaign_analysis_weeks_TAP]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO





Create View [dbo].[v_cinetam_post_campaign_analysis_weeks_TAP] As
select				temp_table.screening_date,
						(select				sum(attendance) 
						from					movie_history 
						where				certificate_group in (	select		certificate_group 
																					from			v_certificate_item_distinct 
																					where		spot_reference in (	select		spot_id 
																																	from			campaign_spot 
																																	where		spot_type= 'T' 
																																	and			campaign_spot.campaign_no = temp_table.campaign_no
																																	and			campaign_spot.screening_date = temp_table.screening_date ))) AS total_attendance,
						(select				sum(attendance) 
						from					cinetam_movie_history 
						where				cinetam_demographics_id in (select cinetam_demographics_id from cinetam_reporting_demographics_xref where cinetam_reporting_demographics_id = temp_table.cinetam_reporting_demographics_id)
						and					certificate_group_id in (	select		certificate_group 
																						from			v_certificate_item_distinct 
																						where		spot_reference in (	select		spot_id 
																																		from			campaign_spot 
																																		where		spot_type= 'T' 
																																		and			campaign_spot.campaign_no = temp_table.campaign_no
																																		and			campaign_spot.screening_date = temp_table.screening_date ))) AS demo_attendance,
						temp_table.cinetam_reporting_demographics_id,
						temp_table.campaign_no,
						temp_table.campaign_target as campaign_target,
						temp_table.original_campaign_target as original_campaign_target

from					(SELECT			inclusion_cinetam_targets.screening_date,
												fc.campaign_no,
												inclusion_cinetam_master_target.cinetam_reporting_demographics_id,
												sum(inclusion_cinetam_targets.target_attendance) as campaign_target,
												sum(inclusion_cinetam_targets.original_target_attendance) as original_campaign_target
						FROM            	film_campaign fc inner join
												inclusion on fc.campaign_no = inclusion.campaign_no inner join
												inclusion_cinetam_master_target on inclusion.inclusion_id = inclusion_cinetam_master_target.inclusion_id inner join 
												inclusion_cinetam_targets on  inclusion.inclusion_id = inclusion_cinetam_targets.inclusion_id  
						group by			inclusion_cinetam_targets.screening_date,
												fc.campaign_no,
												inclusion_cinetam_master_target.cinetam_reporting_demographics_id) as temp_table

GO
