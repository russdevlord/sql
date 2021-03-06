/****** Object:  View [dbo].[v_exhibitor_spot_and_duration]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP VIEW [dbo].[v_exhibitor_spot_and_duration]
GO
/****** Object:  View [dbo].[v_exhibitor_spot_and_duration]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


create view [dbo].[v_exhibitor_spot_and_duration]
as
select			exhibitor_name, 
					film_market.film_market_no, 
					film_market_desc, 
					region_class_desc, 
					complex_name,
					complex.state_code,
					business_unit_desc,
					'Follow Film Audience' as product_type,
					screening_date, 
					sum(duration) as sum_duration,
					count(distinct spot_id) as no_spots,
					sum(cinema_rate) as cinema_rate_sum
from				exhibitor,
					film_market,
					complex,
					complex_region_class,
					film_campaign,
					business_unit,
					campaign_spot,
					campaign_package
where			exhibitor.exhibitor_id = complex.exhibitor_id
and				complex.film_market_no = film_market.film_market_no
and				complex.complex_region_class = complex_region_class.complex_region_class
and				film_campaign.business_unit_id = business_unit.business_unit_id
and				film_campaign.campaign_no = campaign_spot.campaign_no
and				campaign_spot.complex_id = complex.complex_id
and				campaign_spot.package_id = campaign_package.package_id
and				spot_status = 'X'
and				spot_type = 'F'
and				screening_date >= '26-dec-2013'
group by		exhibitor_name, 
					film_market.film_market_no, 
					film_market_desc, 
					region_class_desc, 
					complex_name,
					complex.state_code,
					business_unit_desc,
					screening_date
union all
select			exhibitor_name, 
					film_market.film_market_no, 
					film_market_desc, 
					region_class_desc, 
					complex_name,
					complex.state_code,
					business_unit_desc,
					'Roadblock' as product_type,
					screening_date, 
					sum(duration) as sum_duration,
					count(distinct spot_id) as no_spots,
					sum(cinema_rate) as cinema_rate_sum
from				exhibitor,
					film_market,
					complex,
					complex_region_class,
					film_campaign,
					business_unit,
					campaign_spot,
					campaign_package
where			exhibitor.exhibitor_id = complex.exhibitor_id
and				complex.film_market_no = film_market.film_market_no
and				complex.complex_region_class = complex_region_class.complex_region_class
and				film_campaign.business_unit_id = business_unit.business_unit_id
and				film_campaign.campaign_no = campaign_spot.campaign_no
and				campaign_spot.complex_id = complex.complex_id
and				campaign_spot.package_id = campaign_package.package_id
and				spot_status = 'X'
and				spot_type = 'K'
and				screening_date >= '26-dec-2013'
group by		exhibitor_name, 
					film_market.film_market_no, 
					film_market_desc, 
					region_class_desc, 
					complex_name,
					complex.state_code,
					business_unit_desc,
					screening_date
union all
select			exhibitor_name, 
					film_market.film_market_no, 
					film_market_desc, 
					region_class_desc, 
					complex_name,
					complex.state_code,
					business_unit_desc,
					'TAP' as product_type,
					screening_date, 
					sum(duration) as sum_duration,
					count(distinct spot_id) as no_spots,
					sum(cinema_rate) as cinema_rate_sum
from				exhibitor,
					film_market,
					complex,
					complex_region_class,
					film_campaign,
					business_unit,
					campaign_spot,
					campaign_package
where			exhibitor.exhibitor_id = complex.exhibitor_id
and				complex.film_market_no = film_market.film_market_no
and				complex.complex_region_class = complex_region_class.complex_region_class
and				film_campaign.business_unit_id = business_unit.business_unit_id
and				film_campaign.campaign_no = campaign_spot.campaign_no
and				campaign_spot.complex_id = complex.complex_id
and				campaign_spot.package_id = campaign_package.package_id
and				spot_status = 'X'
and				spot_type = 'T'
and				screening_date >= '26-dec-2013'
group by		exhibitor_name, 
					film_market.film_market_no, 
					film_market_desc, 
					region_class_desc, 
					complex_name,
					complex.state_code,
					business_unit_desc,
					screening_date
union all
select			exhibitor_name, 
					film_market.film_market_no, 
					film_market_desc, 
					region_class_desc, 
					complex_name,
					complex.state_code,
					business_unit_desc,
					'CINEads' as product_type,
					screening_date, 
					sum(duration) as sum_duration,
					count(distinct spot_id) as no_spots,
					sum(cinema_rate) as cinema_rate_sum
from				exhibitor,
					film_market,
					complex,
					complex_region_class,
					film_campaign,
					business_unit,
					campaign_spot,
					campaign_package
where			exhibitor.exhibitor_id = complex.exhibitor_id
and				complex.film_market_no = film_market.film_market_no
and				complex.complex_region_class = complex_region_class.complex_region_class
and				film_campaign.business_unit_id = business_unit.business_unit_id
and				film_campaign.campaign_no = campaign_spot.campaign_no
and				campaign_spot.complex_id = complex.complex_id
and				campaign_spot.package_id = campaign_package.package_id
and				spot_status = 'X'
and				film_plan_id is not null
and				screening_date >= '26-dec-2013'
group by		exhibitor_name, 
					film_market.film_market_no, 
					film_market_desc, 
					region_class_desc, 
					complex_name,
					complex.state_code,
					business_unit_desc,
					screening_date
union all					
select			exhibitor_name, 
					film_market.film_market_no, 
					film_market_desc, 
					region_class_desc, 
					complex_name,
					complex.state_code,
					business_unit_desc,
					'Follow Film Scheduled' as product_type,
					screening_date, 
					sum(duration) as sum_duration,
					count(distinct spot_id) as no_spots,
					sum(cinema_rate) as cinema_rate_sum
from				exhibitor,
					film_market,
					complex,
					complex_region_class,
					film_campaign,
					business_unit,
					campaign_spot,
					campaign_package
where			exhibitor.exhibitor_id = complex.exhibitor_id
and				complex.film_market_no = film_market.film_market_no
and				complex.complex_region_class = complex_region_class.complex_region_class
and				film_campaign.business_unit_id = business_unit.business_unit_id
and				film_campaign.campaign_no = campaign_spot.campaign_no
and				campaign_spot.complex_id = complex.complex_id
and				campaign_spot.package_id = campaign_package.package_id
and				spot_status = 'X'
and				spot_type not in ('T', 'F', 'K')
and				film_plan_id is null
and				campaign_package.follow_film = 'Y'
and				screening_date >= '26-dec-2013'
group by		exhibitor_name, 
					film_market.film_market_no, 
					film_market_desc, 
					region_class_desc, 
					complex_name,
					complex.state_code,
					business_unit_desc,
					screening_date
union all					
select			exhibitor_name, 
					film_market.film_market_no, 
					film_market_desc, 
					region_class_desc, 
					complex_name,
					complex.state_code,
					business_unit_desc,
					'Movie Mix' as product_type,
					screening_date, 
					sum(duration) as sum_duration,
					count(distinct spot_id) as no_spots,
					sum(cinema_rate) as cinema_rate_sum
from				exhibitor,
					film_market,
					complex,
					complex_region_class,
					film_campaign,
					business_unit,
					campaign_spot,
					campaign_package
where			exhibitor.exhibitor_id = complex.exhibitor_id
and				complex.film_market_no = film_market.film_market_no
and				complex.complex_region_class = complex_region_class.complex_region_class
and				film_campaign.business_unit_id = business_unit.business_unit_id
and				film_campaign.campaign_no = campaign_spot.campaign_no
and				campaign_spot.complex_id = complex.complex_id
and				campaign_spot.package_id = campaign_package.package_id
and				spot_status = 'X'
and				spot_type not in ('T', 'F', 'K')
and				film_plan_id is null
and				campaign_package.follow_film = 'N'
and				screening_date >= '26-dec-2013'
group by		exhibitor_name, 
					film_market.film_market_no, 
					film_market_desc, 
					region_class_desc, 
					complex_name,
					complex.state_code,
					business_unit_desc,
					screening_date
GO
