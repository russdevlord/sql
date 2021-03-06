/****** Object:  StoredProcedure [dbo].[p_activity_rep_smry_finyr_rpt]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_activity_rep_smry_finyr_rpt]
GO
/****** Object:  StoredProcedure [dbo].[p_activity_rep_smry_finyr_rpt]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create PROC [dbo].[p_activity_rep_smry_finyr_rpt]  @activity_type  char(1),
                                        @start_date        datetime,
                                        @end_date       datetime,
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
        @start_date 'start_date',
        @end_date   'end_date',
        sum(ars.calls_phone)          'calls_phone'   ,
        sum(ars.calls_face)            'calls_face'  ,
        sum(ars.appts_phone)           'appts_phone'  ,
        sum(ars.appts_face)            'appts_face'  ,
        sum(ars.presentations_kept_phone) 'presentations_kept_phone'     ,
        sum(ars.presentations_kept_face)  'presentations_kept_face'    ,
        sum(ars.presentations_cancelled) 'presentations_cancelled',
        sum(ars.sales_qty)               'sales_qty',
        sum(ars.sales_value)             'sales_value',
        sum(ars.future_appts_phone)      'future_appts_phone',
        sum(ars.future_appts_face)       'future_appts_face',
        sum(ars.poster_deliveries)       'poster_deliveries',
        sum(ars.artwork_approvals)       'artwork_approvals',
        sum(ars.servicing_calls_phone)   'servicing_calls_phone',
        sum(ars.servicing_calls_face)    'servicing_calls_face'
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
group by srep.first_name,
        srep.last_name,
        team.branch_code,
        team.rep_id,
        srep.status ,
        srep.start_date ,
        srep.end_date,
        team.team_id,
        team.area_id,
        team.region_id

return 0
GO
