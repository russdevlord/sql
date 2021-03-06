/****** Object:  StoredProcedure [dbo].[p_cinetam_attendance_tracking_report]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cinetam_attendance_tracking_report]
GO
/****** Object:  StoredProcedure [dbo].[p_cinetam_attendance_tracking_report]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_cinetam_attendance_tracking_report]			@screening_date				datetime,
																									@country_code					char(1),
																									@repteam_code				varchar(8),
																									@repteam_name				varchar(50)
																									
as

declare			@error				int,
						@start_date		datetime		

set nocount on

create table #campaign_weeks
(
	campaign_no								int				not null,
	screening_date							datetime		not null
)

create table #all_people_history
(
	campaign_no								int				not null,
	screening_date							datetime		not null,
	spot_type									char(1)		not null,
	attendance									int				not null
)

create table #cinetam_history
(
	campaign_no								int				not null,
	screening_date							datetime		not null,
	spot_type									char(1)		not null,
	attendance									int				not null,
	cinetam_demographics_id		int				not null
)

/*select				@start_date = min(screening_date)
from				campaign_spot,
						film_campaign,
						branch
where				campaign_spot.campaign_no = film_campaign.campaign_no	
and					film_campaign.branch_code = branch.branch_code
and					(film_campaign.campaign_no in (	select 		distinct campaign_no 
																				from 		campaign_spot 
																				where 		screening_date = @screening_date
																				and 			spot_status = 'X')
or						campaign_status = 'L')
and					branch.country_code  = @country_code
and					((left(@repteam_code,	4) = 'REPR'
and					film_campaign.campaign_no in (select 		campaign_no 
																			from 			film_campaign_reps 
																			where 			rep_id = convert(integer, right(@repteam_code,len(@repteam_code) - 4)))) 
or 					(left(@repteam_code,4) = 'TEAM'
and					film_campaign.campaign_no in (	select 		campaign_no 
																				from 		film_campaign_reps,
												 												campaign_rep_teams 
																				where	 	film_campaign_reps.campaign_reps_id = campaign_rep_teams.campaign_reps_id 
																				and 			team_id = convert(integer, right(@repteam_code,len(@repteam_code) - 4)))) 
or						(left(@repteam_code,4) = 'ALLC'))		*/

insert into		#campaign_weeks
select				campaign_spot.campaign_no, 
						screening_date
from				campaign_spot,
						film_campaign,
						branch
where				campaign_spot.campaign_no = film_campaign.campaign_no	
and					film_campaign.branch_code = branch.branch_code
and					(film_campaign.campaign_no in (	select 		distinct campaign_no 
																				from 		campaign_spot 
																				where 		screening_date = @screening_date
																				and 			spot_status = 'X')
or						campaign_status = 'L')
and					branch.country_code  = @country_code
and					((left(@repteam_code,	4) = 'REPR'
and					film_campaign.campaign_no in (select 		campaign_no 
																			from 			film_campaign_reps 
																			where 			rep_id = convert(integer, right(@repteam_code,len(@repteam_code) - 4)))) 
or 					(left(@repteam_code,4) = 'TEAM'
and					film_campaign.campaign_no in (	select 		campaign_no 
																				from 		film_campaign_reps,
												 												campaign_rep_teams 
																				where	 	film_campaign_reps.campaign_reps_id = campaign_rep_teams.campaign_reps_id 
																				and 			team_id = convert(integer, right(@repteam_code,len(@repteam_code) - 4)))) 
or						(left(@repteam_code,4) = 'ALLC'))
group by			campaign_spot.campaign_no, 
						screening_date



insert into		#all_people_history
select				campaign_spot.campaign_no, 
						movie_history.screening_date, 
						campaign_spot.spot_type, 
						isnull(sum(attendance),0) as attendance
from 				movie_history,
						v_certificate_item_distinct,
						campaign_spot,
						#campaign_weeks
where				movie_history.certificate_group = v_certificate_item_distinct.certificate_group
and					v_certificate_item_distinct.spot_reference = campaign_spot.spot_id
and					movie_history.screening_date = #campaign_weeks.screening_date
and					campaign_spot.screening_date = movie_history.screening_date
and					country = @country_code
and					campaign_spot.campaign_no = #campaign_weeks.campaign_no	
and					campaign_spot.screening_date = #campaign_weeks.screening_date
group by			campaign_spot.campaign_no, 
						movie_history.screening_date, 
						campaign_spot.spot_type


/*insert into		#cinetam_history
select				film_campaign.campaign_no, 
						cinetam_movie_history.screening_date, 
						campaign_spot.spot_type, 
						isnull(sum(attendance),0) as attendance,
						cinetam_demographics_id
from 				cinetam_movie_history,
						v_certificate_item_distinct,
						campaign_spot,
						film_campaign,
						branch
where				cinetam_movie_history.certificate_group_id = v_certificate_item_distinct.certificate_group
and					v_certificate_item_distinct.spot_reference = campaign_spot.spot_id
and					campaign_spot.screening_date <= @screening_date
and					campaign_spot.screening_date = cinetam_movie_history.screening_date
and					campaign_spot.campaign_no = film_campaign.campaign_no
and					film_campaign.branch_code = branch.branch_code
and					(film_campaign.campaign_no in (	select 		distinct campaign_no 
																				from 		campaign_spot 
																				where 		screening_date = @screening_date
																				and 			spot_status = 'X')
or						campaign_status = 'L')
and					branch.country_code  = 'A'
and					((left(@repteam_code,	4) = 'REPR'
and					film_campaign.campaign_no in (select 		campaign_no 
																			from 			film_campaign_reps 
																			where 			rep_id = convert(integer, right(@repteam_code,len(@repteam_code) - 4)))) 
or 					(left(@repteam_code,4) = 'TEAM'
and					film_campaign.campaign_no in (	select 		campaign_no 
																				from 		film_campaign_reps,
												 												campaign_rep_teams 
																				where	 	film_campaign_reps.campaign_reps_id = campaign_rep_teams.campaign_reps_id 
																				and 			team_id = convert(integer, right(@repteam_code,len(@repteam_code) - 4)))) 
or						(left(@repteam_code,4) = 'ALLC'))
group by			film_campaign.campaign_no, 
						cinetam_movie_history.screening_date, 
						campaign_spot.spot_type,
						cinetam_demographics_id*/
						
select * from #all_people_history
select * from #cinetam_history

return 0
GO
