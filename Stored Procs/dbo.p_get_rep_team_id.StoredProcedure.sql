USE [production]
GO
/****** Object:  StoredProcedure [dbo].[p_get_rep_team_id]    Script Date: 11/03/2021 2:30:34 PM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create PROC [dbo].[p_get_rep_team_id]   @rep_id         integer,
                                @rep_date       datetime
                                        
as
set nocount on 

declare @team_id integer

select  @team_id = team_reps.team_id
from    team_reps, team_rep_dates
where   team_reps.team_rep_id = team_rep_dates.team_rep_id
and     team_reps.rep_id = @rep_id
and     team_rep_dates.start_period <= @rep_date
and     isnull(team_rep_dates.end_period,'31-dec-3000') >= @rep_date


return @team_id
GO
