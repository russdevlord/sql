/****** Object:  StoredProcedure [dbo].[p_inclusion_achievement_detailed]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_inclusion_achievement_detailed]
GO
/****** Object:  StoredProcedure [dbo].[p_inclusion_achievement_detailed]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc			[dbo].[p_inclusion_achievement_detailed]		@rep_code					varchar(20),
																									@screening_date			datetime


with recompile

as



declare				@rep_pos							int,
						@team_pos						int,
						@mode_id						int,
						@team_rep_mode			char(1),
						@arg_rep_code				varchar(20),
						@arg_screening_date		datetime

set nocount on
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


select			@arg_rep_code = @rep_code,
					@arg_screening_date = @screening_date

create table	#argument_campaigns
(
	campaign_no			int				not null
)

select @rep_pos = charindex('REPR', @arg_rep_code, 1)
select @team_pos = charindex('TEAM', @arg_rep_code, 1)

select 	@mode_id = convert(integer,substring(@arg_rep_code, 5, 16))

if @arg_rep_code = 'ALLC'
begin
	insert into #argument_campaigns select distinct campaign_no from inclusion where inclusion_id in (select inclusion_id from inclusion_follow_film_targets where screening_date = @arg_screening_date union all select inclusion_id from inclusion_cinetam_targets where screening_date = @arg_screening_date) and inclusion_status <> 'P' and campaign_no in (select campaign_no from film_campaign where campaign_status <> 'P')
end
else if @arg_rep_code = 'N' or @arg_rep_code = 'V' or @arg_rep_code = 'Q' or @arg_rep_code = 'S' or @arg_rep_code = 'W' or @arg_rep_code = 'T' or @arg_rep_code = 'Z'
begin
	insert into #argument_campaigns select distinct campaign_no from inclusion where inclusion_id in (select inclusion_id from inclusion_follow_film_targets where screening_date = @arg_screening_date union all select inclusion_id from inclusion_cinetam_targets where screening_date = @arg_screening_date) and inclusion_status <> 'P' and campaign_no in (select campaign_no from film_campaign where branch_code = @arg_rep_code and campaign_status <> 'P')
end
else if @rep_pos > 0
begin
	select 	@team_rep_mode = 'R'
	select 	@mode_id = convert(integer,substring(@arg_rep_code, 5, 16))
	insert into #argument_campaigns select campaign_no from film_campaign_reps where  rep_id = @mode_id and control_idc <> 'A' and campaign_no in (select campaign_no from film_campaign where campaign_status <>  'P')
end
else if @team_pos > 0
begin
	select 	@team_rep_mode = 'T'
	select 	@mode_id = convert(integer,substring(@arg_rep_code, 5, 16))
	insert into #argument_campaigns select campaign_no from film_campaign_reps inner join campaign_rep_teams on film_campaign_reps.campaign_reps_id =  campaign_rep_teams.campaign_reps_id where  team_id = @mode_id and control_idc <> 'A' and campaign_no in (select campaign_no from film_campaign where campaign_status <> 'P')
end
else
begin
	return -1        
end

select			campaign_no, 
					inclusion_desc, 
					inclusion_id,
					case right(long_name,3) when ' 3D' then left(long_name, len(long_name) - 3) else long_name end as long_name,
					cinetam_reporting_demographics_desc,
					screening_date,
					sum(adjusted_target_attendance) as adjusted_target_attendance, 
					sum(original_target_attendance) as original_target_attendance, 
					sum(achieved_attendance) as achieved_attendance,
					sum(actual_attendance) as actual_attendance,
					min(temp_table.screening_date) as first_date,
					max(temp_table.screening_date) as max_date,
					inclusion_type_desc,
					sum(four_day_weekend_attendance) as four_day_weekend_attendance,
					sum(full_weekend_actual_attendance) as full_weekend_actual_attendance
from				(SELECT				inclusion.campaign_no, 
												inclusion.inclusion_desc, 
												inclusion_follow_film_targets.screening_date,
												inclusion_follow_film_targets.inclusion_id,
												long_name,
												cinetam_reporting_demographics_desc,
												sum(inclusion_follow_film_targets.target_attendance) as adjusted_target_attendance, 
												sum(inclusion_follow_film_targets.original_target_attendance) as original_target_attendance, 
												sum(inclusion_follow_film_targets.achieved_attendance) as achieved_attendance, 
												(select			sum(attendance) 
												from				inclusion_cinetam_attendance 
												where			inclusion_id = inclusion_follow_film_targets.inclusion_id 
												and				screening_date = inclusion_follow_film_targets.screening_date 
												and				cinetam_reporting_demographics_id = inclusion_follow_film_targets.cinetam_reporting_demographics_id 
												and				inclusion_cinetam_attendance.movie_id = inclusion_follow_film_targets.movie_id
												and				campaign_no in (select campaign_no from #argument_campaigns)) as actual_attendance,
												(select			sum(attendance) 
												from				inclusion_cinetam_attendance_weekend 
												where			inclusion_id = inclusion_follow_film_targets.inclusion_id 
												and				screening_date = inclusion_follow_film_targets.screening_date 
												and				cinetam_reporting_demographics_id = inclusion_follow_film_targets.cinetam_reporting_demographics_id 
												and				inclusion_cinetam_attendance_weekend.movie_id = inclusion_follow_film_targets.movie_id
												and				campaign_no in (select campaign_no from #argument_campaigns)) as four_day_weekend_attendance,
												(select			sum(full_attendance) 
												from				inclusion_cinetam_attendance_weekend 
												where			inclusion_id = inclusion_follow_film_targets.inclusion_id 
												and				screening_date = inclusion_follow_film_targets.screening_date 
												and				cinetam_reporting_demographics_id = inclusion_follow_film_targets.cinetam_reporting_demographics_id 
												and				inclusion_cinetam_attendance_weekend.movie_id = inclusion_follow_film_targets.movie_id
												and				campaign_no in (select campaign_no from #argument_campaigns)) as full_weekend_actual_attendance,
												inclusion_type_desc
					from						inclusion
					inner join				inclusion_follow_film_targets on	inclusion.inclusion_id = inclusion_follow_film_targets.inclusion_id 
					inner join				movie on inclusion_follow_film_targets.movie_id = movie.movie_id
					inner join				cinetam_reporting_demographics on inclusion_follow_film_targets.cinetam_reporting_demographics_id = cinetam_reporting_demographics.cinetam_reporting_demographics_id
					inner join				inclusion_type on inclusion.inclusion_type = inclusion_type.inclusion_type
					WHERE				inclusion_follow_film_targets.screening_date <= @arg_screening_date
					and						inclusion.campaign_no in (select campaign_no from #argument_campaigns)
					group by 				inclusion.campaign_no, 
												inclusion.inclusion_desc, 
												inclusion_follow_film_targets.screening_date,
												inclusion_follow_film_targets.inclusion_id,
												long_name,
												cinetam_reporting_demographics_desc,
												inclusion_follow_film_targets.cinetam_reporting_demographics_id,
												inclusion_follow_film_targets.movie_id,
												inclusion_type_desc
					union all
					SELECT				inclusion.campaign_no, 
												inclusion.inclusion_desc, 
												inclusion_cinetam_targets.screening_date,
												inclusion_cinetam_targets.inclusion_id,
												inclusion_type_desc,
												cinetam_reporting_demographics_desc,
												sum(inclusion_cinetam_targets.target_attendance) as adjusted_target_attendance, 
												sum(inclusion_cinetam_targets.original_target_attendance) as original_target_attendance, 
												sum(inclusion_cinetam_targets.achieved_attendance) as achieved_attendance, 
												(select			sum(attendance) 
												from				inclusion_cinetam_attendance 
												where			inclusion_id = inclusion_cinetam_targets.inclusion_id 
												and				screening_date = inclusion_cinetam_targets.screening_date 
												and				cinetam_reporting_demographics_id = inclusion_cinetam_targets.cinetam_reporting_demographics_id
												and				campaign_no in (select campaign_no from #argument_campaigns)) as actual_attendance,
												(select			sum(attendance) 
												from				inclusion_cinetam_attendance_weekend 
												where			inclusion_id = inclusion_cinetam_targets.inclusion_id 
												and				screening_date = inclusion_cinetam_targets.screening_date 
												and				cinetam_reporting_demographics_id = inclusion_cinetam_targets.cinetam_reporting_demographics_id
												and				campaign_no in (select campaign_no from #argument_campaigns)) as four_day_weekend_attendance,
												(select			sum(full_attendance) 
												from				inclusion_cinetam_attendance_weekend 
												where			inclusion_id = inclusion_cinetam_targets.inclusion_id 
												and				screening_date = inclusion_cinetam_targets.screening_date 
												and				cinetam_reporting_demographics_id = inclusion_cinetam_targets.cinetam_reporting_demographics_id
												and				campaign_no in (select campaign_no from #argument_campaigns)) as full_weekend_actual_attendance,
												inclusion_type_desc
					from						inclusion 
					inner join				inclusion_cinetam_targets on	inclusion.inclusion_id = inclusion_cinetam_targets.inclusion_id 
					inner join				inclusion_type on inclusion.inclusion_type = inclusion_type.inclusion_type
					inner join				cinetam_reporting_demographics on inclusion_cinetam_targets.cinetam_reporting_demographics_id = cinetam_reporting_demographics.cinetam_reporting_demographics_id
					WHERE				inclusion_cinetam_targets.screening_date <= @arg_screening_date
					and						inclusion.campaign_no in (select campaign_no from #argument_campaigns)
					group by				inclusion.campaign_no, 
												inclusion.inclusion_desc, 
												inclusion_cinetam_targets.screening_date,
												inclusion_cinetam_targets.inclusion_id,
												inclusion_type_desc,
												inclusion_cinetam_targets.cinetam_reporting_demographics_id,
												cinetam_reporting_demographics_desc,
												inclusion_cinetam_targets.cinetam_reporting_demographics_id) as temp_table
group by		campaign_no, 
					inclusion_desc, 
					inclusion_id,
					case right(long_name,3) when ' 3D' then left(long_name, len(long_name) - 3) else long_name end ,
					cinetam_reporting_demographics_desc,
					inclusion_type_desc,
					screening_date

return 0
GO
