/****** Object:  StoredProcedure [dbo].[p_get_rep_team_ids]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_get_rep_team_ids]
GO
/****** Object:  StoredProcedure [dbo].[p_get_rep_team_ids]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create PROC [dbo].[p_get_rep_team_ids]   @rep_id         integer,
                                 @rep_date       datetime,
                                 @team_id       integer OUTPUT,
                                 @area_id       integer OUTPUT,
                                 @region_id     integer OUTPUT
                                        
as
set nocount on 

select  @team_id = team_reps.team_id
from    team_reps, team_rep_dates
where   team_reps.team_rep_id = team_rep_dates.team_rep_id
and     team_reps.rep_id = @rep_id
and     team_rep_dates.start_period <= @rep_date
and     isnull(team_rep_dates.end_period,'31-dec-3000') >= @rep_date

select  @area_id = area_reps.area_id
from    area_reps, area_rep_dates
where   area_reps.area_rep_id = area_rep_dates.area_rep_id
and     area_reps.rep_id = @rep_id
and     area_rep_dates.start_period <= @rep_date
and     isnull(area_rep_dates.end_period,'31-dec-3000') >= @rep_date

select  @region_id = region_reps.region_id
from    region_reps, region_rep_dates
where   region_reps.region_rep_id = region_rep_dates.region_rep_id
and     region_reps.rep_id = @rep_id
and     region_rep_dates.start_period <= @rep_date
and     isnull(region_rep_dates.end_period,'31-dec-3000') >= @rep_date

return 0
GO
