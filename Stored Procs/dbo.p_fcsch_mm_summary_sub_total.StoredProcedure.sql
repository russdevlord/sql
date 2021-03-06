/****** Object:  StoredProcedure [dbo].[p_fcsch_mm_summary_sub_total]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_fcsch_mm_summary_sub_total]
GO
/****** Object:  StoredProcedure [dbo].[p_fcsch_mm_summary_sub_total]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_fcsch_mm_summary_sub_total]			@campaign_no			int

as

declare		@error								int,
				@met_aus_count				int,
				@reg_aus_count				int,
				@met_3main_count			int,
				@met_5main_count			int,
				@reg_nz_count				int,
				@aus_count						int,
				@nz_count						int,
				@aus_esb_count				int,
				@met_aus_bool				bit,
				@reg_aus_bool				bit,
				@met_3main_bool			bit,
				@met_5main_bool			bit,
				@reg_nz_bool					bit,
				@aus_bool						bit,
				@nz_bool							bit,
				@individual_bool				bit,
				@aus_esb_bool				bit,
				@inclusion_count				int,
				@inclusion_id					int,
				@movie_id						int,
				@movie_name					varchar(50),
				@attendance					int,				
				@markets							varchar(500),
				@movies							varchar(500),
				@inclusion_desc				varchar(255),
				@prints							varchar(500),
				@print_id							int,
				@print_name					varchar(50),
				@market							varchar(10),
				@country_code				char(1),
				@start_date					datetime,
				@end_date						datetime,
				@product_desc				varchar(100),
				@revision_no					int,
				@business_unit_id			int,
				@market_count				int,
				@disclaimer						int,
				@inclusion_type				varchar(30),
				@cinetam_reporting_demographics_desc			varchar(30)


if @campaign_no = 215194
begin
	select			inclusion_type_desc,
					614938,
					cinetam_reporting_demographics_desc
	from			inclusion,
					inclusion_cinetam_targets,
					inclusion_type,
					cinetam_reporting_demographics
	where			inclusion.inclusion_id = 	inclusion_cinetam_targets.inclusion_id
	and				inclusion.campaign_no = @campaign_no
	and				inclusion_type.inclusion_type = inclusion.inclusion_type
	and				inclusion_type_group = 'S'
	and				inclusion_type.inclusion_type <> 29
	and				inclusion_cinetam_targets.cinetam_reporting_demographics_id = cinetam_reporting_demographics.cinetam_reporting_demographics_id
	group by		inclusion_type_desc,
					cinetam_reporting_demographics_desc
	order by		inclusion_type_desc	
end
else
begin	
	select			inclusion_type_desc,
					sum(inclusion_cinetam_targets.original_target_attendance),
					cinetam_reporting_demographics_desc
	from			inclusion,
					inclusion_cinetam_targets,
					inclusion_type,
					cinetam_reporting_demographics
	where			inclusion.inclusion_id = 	inclusion_cinetam_targets.inclusion_id
	and				inclusion.campaign_no = @campaign_no
	and				inclusion_type.inclusion_type = inclusion.inclusion_type
	and				inclusion_type_group = 'S'
	and				inclusion_type.inclusion_type <> 29
	and				inclusion_cinetam_targets.cinetam_reporting_demographics_id = cinetam_reporting_demographics.cinetam_reporting_demographics_id
	group by		inclusion_type_desc,
					cinetam_reporting_demographics_desc
	order by		inclusion_type_desc	
end


return 0
GO
