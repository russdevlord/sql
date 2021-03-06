/****** Object:  StoredProcedure [dbo].[p_activity_rep_no_activity_rpt]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_activity_rep_no_activity_rpt]
GO
/****** Object:  StoredProcedure [dbo].[p_activity_rep_no_activity_rpt]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create PROC [dbo].[p_activity_rep_no_activity_rpt]  @activity_type  char(1),
                                        @finyear        datetime,
                                        @branch_code    char(2),
                                        @country_code   char(1),
                                        @rep_id         integer,
                                        @team_id        integer,
                                        @area_id        integer,
                                        @region_id      integer
as



declare @error          		integer,
        @start_date             datetime,
        @end_date               datetime

select  @start_date = min(sales_period_start)
from    sales_period
where   finyear_end = @finyear

select  @end_date = max(week_ending)
from    activity_rep_team
where   week_ending < getdate()

select  srep.first_name,
        srep.last_name,
        team.branch_code,
        team.rep_id,
        srep.status 'rep_status',
        srep.start_date 'rep_start_date',
        srep.end_date 'rep_end_date',
        team.team_id,
        team.area_id,
        team.region_id,
        @finyear    'finyear',
        @start_date 'start_date',
        @end_date   'end_date',
        ars.activity_date,
        ars.activity_status
from    activity_rep_daily_summary ars, sales_rep srep, activity_rep_team team, branch br
where   ars.rep_id = srep.rep_id
and     ars.rep_id = team.rep_id
and     ars.week_ending = team.week_ending
and     team.branch_code = br.branch_code
and     (ars.activity_date >= @start_date)
and     (ars.activity_date <= @end_date)
and     (team.branch_code = @branch_code OR @branch_code is null OR @branch_code = '')
and     (team.rep_id = @rep_id OR @rep_id = -1)
and     (team.team_id = @team_id OR @team_id = -1)
and     (team.area_id = @area_id OR @area_id = -1)
and     (team.region_id = @region_id OR @region_id = -1)
and     (br.country_code = @country_code OR @country_code is null OR @country_code = '')
and     ars.activity_status = 'O'

return 0
GO
