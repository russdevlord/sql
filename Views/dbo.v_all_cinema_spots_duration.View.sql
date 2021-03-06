/****** Object:  View [dbo].[v_all_cinema_spots_duration]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_all_cinema_spots_duration]
GO
/****** Object:  View [dbo].[v_all_cinema_spots_duration]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

create view [dbo].[v_all_cinema_spots_duration]

as

select      'onscreen' as type,complex_id,
            screening_date,
            billing_date,
            sum(campaign_spot.charge_rate) as charge_rate_sum,
            sum(campaign_spot.cinema_rate) as cinema_rate_sum,
            count(spot_id) as no_spots,
            spot_type,
            spot_status,
            campaign_spot.campaign_no,
            billing_period,
            duration
from        campaign_spot,
				campaign_package
where		campaign_spot.package_id = campaign_package.package_id
group by    complex_id,
            screening_date,
            billing_date,
            spot_type,
            spot_status,
            campaign_spot.campaign_no,
            billing_period,
            duration
union all
select      'digilite',complex_id,
            screening_date,
            billing_date,
            sum(cinelight_spot.charge_rate),
            sum(cinelight_spot.cinema_rate) as cinema_rate_sum,
            count(spot_id) as no_spots,
            spot_type,
            spot_status,
            cinelight_spot.campaign_no,
            billing_period,
            duration
from        cinelight_spot,
            cinelight,
            cinelight_package
where       cinelight_spot.cinelight_id = cinelight.cinelight_id
and		cinelight_spot.package_id = cinelight_package.package_id
group by    complex_id,
            screening_date,
            billing_date,
            spot_type,
            spot_status,
            cinelight_spot.campaign_no,
            billing_period,
            duration
union all
select      'cinemarketing',complex_id,
            screening_date,
            billing_date,
            sum(charge_rate),
            sum(cinema_rate) as cinema_rate_sum,
            count(spot_id) as no_spots,
            spot_type,
            spot_status,
            campaign_no,
            billing_period,
            0
from        inclusion_spot
where       billing_date is not null
group by    complex_id,
            screening_date,
            billing_date,
            spot_type,
            spot_status,
            campaign_no,
            billing_period
union all
select      'takeouts',1,
            dateadd(dd, -6, revenue_period),
            dateadd(dd, -6, revenue_period),
            (sum(takeout_rate) * - 1),
            (0) as cinema_rate_sum,
            count(spot_id) as no_spots,
            spot_type,
            spot_status,
            campaign_no,
            revenue_period,
            0
from        inclusion_spot
where       takeout_rate <> 0
group by    complex_id,
            revenue_period,
            spot_type,
            spot_status,
            campaign_no
GO
