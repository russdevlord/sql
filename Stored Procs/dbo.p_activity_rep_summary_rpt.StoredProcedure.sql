/****** Object:  StoredProcedure [dbo].[p_activity_rep_summary_rpt]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_activity_rep_summary_rpt]
GO
/****** Object:  StoredProcedure [dbo].[p_activity_rep_summary_rpt]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create PROC [dbo].[p_activity_rep_summary_rpt]  @activity_type  char(1),
                                        @week_ending    datetime,
                                        @branch_code    char(2),
                                        @country_code   char(1),
                                        @rep_id         integer,
                                        @team_id        integer,
                                        @area_id        integer,
                                        @region_id      integer
as



declare @error          		integer


select  srep.first_name,
        srep.last_name,
        team.branch_code,
        team.rep_id,
        team.team_id,
        team.area_id,
        team.region_id,
        ars.activity_date,
        ars.week_ending             ,
        ars.activity_status         ,
        ars.calls_phone             ,
        ars.calls_face              ,
        ars.appts_phone             ,
        ars.appts_face              ,
        ars.presentations_kept_phone      ,
        ars.presentations_kept_face      ,
        ars.presentations_cancelled ,
        ars.sales_qty               ,
        ars.sales_value             ,
        ars.future_appts_phone      ,
        ars.future_appts_face       ,
        ars.poster_deliveries       ,
        ars.artwork_approvals       ,
        ars.servicing_calls_phone   ,
        ars.servicing_calls_face    
from    activity_rep_daily_summary ars, sales_rep srep, activity_rep_team team, branch br
where   ars.rep_id = srep.rep_id
and     ars.rep_id = team.rep_id
and     ars.week_ending = team.week_ending
and     team.branch_code = br.branch_code
and     (ars.week_ending = @week_ending)
and     (team.branch_code = @branch_code OR @branch_code is null)
and     (team.rep_id = @rep_id OR @rep_id is null)
and     (team.team_id = @team_id OR @team_id is null)
and     (team.area_id = @area_id OR @area_id is null)
and     (team.region_id = @region_id OR @region_id is null)
and     (br.country_code = @country_code OR @country_code is null)


/*

    insert  activity_rep_team(
            rep_id,
            week_ending,
            sales_period,
            branch_code,
            team_id,
            area_id,
            region_id)
    select  rep_id,
            @week_ending,
            sales_period,
            branch_code,
            team_id,
            area_id,
            region_id
    from    rep_slide_targets
    where   sales_period = @sales_period
    and     branch_code = @branch_code


    insert  activity_rep_daily_summary(
                rep_id                  ,
                activity_date           ,
                activity_type           ,
                week_ending             ,
                activity_status         ,
                calls_phone             ,
                calls_face              ,
                appts_phone             ,
                appts_face              ,
                presentations_kept_phone      ,
                presentations_kept_face      ,
                presentations_cancelled ,
                sales_qty               ,
                sales_value             ,
                future_appts_phone      ,
                future_appts_face       ,
                poster_deliveries       ,
                artwork_approvals       ,
                servicing_calls_phone   ,
                servicing_calls_face    )
      select    art.rep_id,
                aday.activity_date,
                @activity_type,
                @week_ending,
                @status_outstanding,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0
      from      activity_rep_team art, #activity_days aday
      where     art.sales_period = @sales_period
      and       art.branch_code = @branch_code
      and       art.week_ending = @week_ending

*/



return 0
GO
