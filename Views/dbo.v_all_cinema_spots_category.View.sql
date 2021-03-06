/****** Object:  View [dbo].[v_all_cinema_spots_category]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_all_cinema_spots_category]
GO
/****** Object:  View [dbo].[v_all_cinema_spots_category]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO



create view [dbo].[v_all_cinema_spots_category]

as

select      'onscreen' as type,
			campaign_spot.complex_id,
            campaign_spot.screening_date,
            campaign_spot.billing_date,
            sum(campaign_spot.rate) as rate_sum,
            sum(campaign_spot.charge_rate) as charge_rate_sum,
            sum(campaign_spot.cinema_rate) as cinema_rate_sum,
            count(campaign_spot.spot_id) as no_spots,
            campaign_spot.spot_type,
            campaign_spot.spot_status,
            campaign_spot.campaign_no,
            campaign_spot.billing_period,
            campaign_spot.package_id,
            product_category
from        campaign_spot, campaign_package
where	    campaign_spot.package_id = campaign_package.package_id
group by    campaign_spot.complex_id,
            campaign_spot.screening_date,
            campaign_spot.billing_date,
            campaign_spot.spot_type,
            campaign_spot.spot_status,
            campaign_spot.campaign_no,
            campaign_spot.billing_period,
            campaign_spot.package_id,
            product_category
union all
select      'digilite',
			complex_id,
            cinelight_spot.screening_date,
            cinelight_spot.billing_date,
            sum(cinelight_spot.rate),
            sum(cinelight_spot.charge_rate),
            sum(cinelight_spot.cinema_rate) as cinema_rate_sum,
            count(cinelight_spot.spot_id) as no_spots,
            cinelight_spot.spot_type,
            cinelight_spot.spot_status,
            cinelight_spot.campaign_no,
            cinelight_spot.billing_period,
            cinelight_spot.package_id,
            product_category
from        cinelight_spot,
            cinelight,
            cinelight_package
where       cinelight_spot.cinelight_id = cinelight.cinelight_id
and			cinelight_spot.package_id = cinelight_package.package_id
group by    complex_id,
            cinelight_spot.screening_date,
            cinelight_spot.billing_date,
            cinelight_spot.spot_type,
            cinelight_spot.spot_status,
            cinelight_spot.campaign_no,
            cinelight_spot.billing_period,
            cinelight_spot.package_id,
            product_category
union all
select      'cinemarketing',
			inclusion_spot.complex_id,
            inclusion_spot.screening_date,
            inclusion_spot.billing_date,
            sum(inclusion_spot.rate),
            sum(inclusion_spot.charge_rate),
            sum(inclusion_spot.cinema_rate) as cinema_rate_sum,
            count(inclusion_spot.spot_id) as no_spots,
            inclusion_spot.spot_type,
            inclusion_spot.spot_status,
            inclusion_spot.campaign_no,
            inclusion_spot.billing_period,
            NULL package_id,
            product_category_id
from        inclusion_spot,
			inclusion
where       billing_date is not null
group by    inclusion_spot.complex_id,
            inclusion_spot.screening_date,
            inclusion_spot.billing_date,
            inclusion_spot.spot_type,
            inclusion_spot.spot_status,
            inclusion_spot.campaign_no,
            inclusion_spot.billing_period,
            product_category_id



GO
