/****** Object:  View [dbo].[v_dw_fact_campaign_cinatt]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_dw_fact_campaign_cinatt]
GO
/****** Object:  View [dbo].[v_dw_fact_campaign_cinatt]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE VIEW [dbo].[v_dw_fact_campaign_cinatt]
AS
    select  camp.campaign_no as campaign_no,
            camp.campaign_name as campaign_name,
            camp.client_name as client_name,
            camp.agency_name as agency_name,
            camp.branch_code as branch_code,
            camp.campaign_cost as campaign_cost,
            camp.campaign_start_date as campaign_start_date,
            camp.first_screening_week as first_screening_week,
            camp.billed_screening_weeks as billed_screening_weeks,
            camp.billed_weeks_on_screen as billed_weeks_on_screen,
            spots.screening_date as screening_date,
            spots.complex_name as complex_name,
            spots.complex_id as complex_id,
            spots.movie_id as movie_id,
            spots.movie_name as movie_name,
            sum(cinatt.attendance_per_print) as total_attendance
    from    v_dw_dim_campaigns camp,
            v_dw_dim_campaign_movie_spots spots,
            v_cinatt_mh_total_attendance cinatt
    where   camp.campaign_no = spots.campaign_no
    and     spots.campaign_no = cinatt.campaign_no
    and     spots.screening_date = cinatt.screening_date
    and     spots.complex_id = cinatt.complex_id
    and     spots.movie_id = cinatt.movie_id
    group by camp.campaign_no,
            camp.campaign_name,
            camp.client_name,
            camp.agency_name,
            camp.branch_code,
            camp.campaign_cost,
            camp.campaign_start_date,
            camp.first_screening_week,
            camp.billed_screening_weeks,
            camp.billed_weeks_on_screen,
            spots.screening_date,
            spots.complex_name,
            spots.complex_id,
            spots.movie_id,
            spots.movie_name
GO
