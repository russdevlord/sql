/****** Object:  View [dbo].[v_all_cinema_spots]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_all_cinema_spots]
GO
/****** Object:  View [dbo].[v_all_cinema_spots]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO






create view [dbo].[v_all_cinema_spots]

as

select      'onscreen' as type,complex_id,
            screening_date,
            billing_date,
            sum(rate) as rate_sum,
            sum(charge_rate) as charge_rate_sum,
            sum(cinema_rate) as cinema_rate_sum,
            count(spot_id) as no_spots,
            spot_type,
            spot_status,
            campaign_no,
            billing_period,
            package_id,
			package_id as inclusion_package_id
from        campaign_spot
group by    complex_id,
            screening_date,
            billing_date,
            spot_type,
            spot_status,
            campaign_no,
            billing_period,
            package_id
union all
select      'digilite',complex_id,
            screening_date,
            billing_date,
            sum(rate),
            sum(charge_rate),
            sum(cinema_rate) as cinema_rate_sum,
            count(spot_id) as no_spots,
            spot_type,
            spot_status,
            campaign_no,
            billing_period,
            package_id,
			package_id as inclusion_package_id
from        cinelight_spot,
            cinelight
where       cinelight_spot.cinelight_id = cinelight.cinelight_id
group by    complex_id,
            screening_date,
            billing_date,
            spot_type,
            spot_status,
            campaign_no,
            billing_period,
            package_id
union all
select      'cinemarketing',complex_id,
            screening_date,
            billing_date,
            sum(rate),
            sum(charge_rate),
            sum(cinema_rate) as cinema_rate_sum,
            count(spot_id) as no_spots,
            spot_type,
            spot_status,
            inclusion_spot.campaign_no,
            inclusion_spot.billing_period,
            NULL package_id,
			null as inclusion_package_id 
from        inclusion_spot
inner join inclusion on inclusion_spot.inclusion_id = inclusion.inclusion_id
where       billing_date is not null
and inclusion_type not in (24,29,30,31,32)
group by    complex_id,
            screening_date,
            billing_date,
            spot_type,
            spot_status,
            inclusion_spot.campaign_no,
            inclusion_spot.billing_period
union all
select      'onscreen',
			complex_id,
            screening_date,
            billing_date,
            sum(rate),
            sum(charge_rate),
            sum(cinema_rate) as cinema_rate_sum,
            count(spot_id) as no_spots,
            spot_type,
            spot_status,
			inclusion_spot.campaign_no,
            inclusion_spot.billing_period,
            NULL as package_id,
			inclusion_cinetam_package.package_id as inlusion_package_id
from        inclusion_spot
inner join	inclusion on inclusion_spot.inclusion_id = inclusion.inclusion_id
inner join	inclusion_cinetam_package on inclusion.inclusion_id = inclusion_cinetam_package.inclusion_id
where       billing_date is not null
and			inclusion_type in (24,29,30,31,32)
group by    complex_id,
            screening_date,
            billing_date,
            spot_type,
            spot_status,
            inclusion_spot.campaign_no,
            inclusion_spot.billing_period,
			inclusion_cinetam_package.package_id
union all
select      'takeouts',1,
            dateadd(dd, -6, revenue_period),
            dateadd(dd, -6, revenue_period),
            (sum(takeout_rate) * - 1),
            (sum(takeout_rate) * - 1),
            (0) as cinema_rate_sum,
            count(spot_id) as no_spots,
            spot_type,
            spot_status,
            campaign_no,
            revenue_period,
            NULL as package_id,
            NULL as inlusion_package_id
from        inclusion_spot
where       takeout_rate <> 0
and         inclusion_id not in (select inclusion_id from inclusion where inclusion_category in ('A','R','W'))
group by    complex_id,
            revenue_period,
            spot_type,
            spot_status,
            campaign_no



GO
