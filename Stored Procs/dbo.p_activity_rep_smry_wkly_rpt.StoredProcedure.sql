/****** Object:  StoredProcedure [dbo].[p_activity_rep_smry_wkly_rpt]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_activity_rep_smry_wkly_rpt]
GO
/****** Object:  StoredProcedure [dbo].[p_activity_rep_smry_wkly_rpt]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create PROC [dbo].[p_activity_rep_smry_wkly_rpt]  @activity_type  char(1),
                                        @week_ending        datetime,
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
        srep.status 'rep_status',
        srep.start_date 'rep_start_date',
        srep.end_date 'rep_end_date',
        team.team_id,
        team.area_id,
        team.region_id,
        @week_ending    'week_ending',
        ars.activity_date       'activity_date',
        ars.activity_status     'activity_status',
        ars.calls_phone          'calls_phone'   ,
        ars.calls_face            'calls_face'  ,
        ars.appts_phone           'appts_phone'  ,
        ars.appts_face            'appts_face'  ,
        ars.presentations_kept_phone 'presentations_kept_phone'     ,
        ars.presentations_kept_face  'presentations_kept_face'    ,
        ars.presentations_cancelled 'presentations_cancelled',
        ars.sales_qty               'sales_qty',
        ars.sales_value             'sales_value',
        ars.future_appts_phone      'future_appts_phone',
        ars.future_appts_face       'future_appts_face',
        ars.poster_deliveries       'poster_deliveries',
        ars.artwork_approvals       'artwork_approvals',
        ars.servicing_calls_phone   'servicing_calls_phone',
        ars.servicing_calls_face    'servicing_calls_face'
from    activity_rep_daily_summary ars, sales_rep srep, activity_rep_team team, branch br
where   ars.rep_id = srep.rep_id
and     ars.rep_id = team.rep_id
and     ars.week_ending = team.week_ending
and     ars.week_ending = @week_ending
and     team.branch_code = br.branch_code
and     (team.branch_code = @branch_code OR @branch_code is null OR @branch_code = '')
and     (team.rep_id = @rep_id OR @rep_id = -1)
and     (team.team_id = @team_id OR @team_id = -1)
and     (team.area_id = @area_id OR @area_id = -1)
and     (team.region_id = @region_id OR @region_id = -1)
and     (br.country_code = @country_code OR @country_code is null OR @country_code = '')

return 0
GO
