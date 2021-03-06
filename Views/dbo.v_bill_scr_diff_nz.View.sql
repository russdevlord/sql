/****** Object:  View [dbo].[v_bill_scr_diff_nz]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_bill_scr_diff_nz]
GO
/****** Object:  View [dbo].[v_bill_scr_diff_nz]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
create view [dbo].[v_bill_scr_diff_nz]
as
select 'Onscreen' as revenue_type, film_campaign.campaign_no, product_desc, campaign_spot.screening_date, billing_date, spot_type_desc, sum(charge_rate) as revenue, count(spot_id) as no_spots, xrefa.benchmark_end as billing_month, xrefb.benchmark_end as screening_month,
(select sum(charge_rate) from campaign_spot where campaign_no = film_campaign.campaign_no) / (select count(spot_id) from campaign_spot where campaign_no = film_campaign.campaign_no and spot_type in ('S','B','C','N')) as avg_rate_all_spots
from campaign_spot, film_campaign, film_screening_date_xref xrefa, film_screening_date_xref xrefb, spot_type
where film_campaign.campaign_no = campaign_spot.campaign_no
and campaign_spot.screening_date = xrefb.screening_date
and campaign_spot.billing_date = xrefa.screening_date
and spot_status <> 'P'
and spot_type in ('S','N','C','B')
and campaign_spot.spot_type = spot_type.spot_type_code
--and xrefa.benchmark_end >= '1-jun-2004'
and branch_code = 'Z'
group by film_campaign.campaign_no, product_desc, campaign_spot.screening_date, billing_date, spot_type_desc, xrefa.benchmark_end, xrefb.benchmark_end

union

select 'Digilite', film_campaign.campaign_no, product_desc, cinelight_spot.screening_date, billing_date, spot_type_desc, sum(charge_rate) as revenue, count(spot_id) as no_spots, xrefa.benchmark_end, xrefb.benchmark_end,
(select sum(charge_rate) from cinelight_spot where campaign_no = film_campaign.campaign_no) / (select count(spot_id) from cinelight_spot where campaign_no = film_campaign.campaign_no and spot_type in ('S','B','C','N')) as avg_rate_all_spots
from cinelight_spot, film_campaign, film_screening_date_xref xrefa, film_screening_date_xref xrefb, spot_type
where film_campaign.campaign_no = cinelight_spot.campaign_no
and cinelight_spot.screening_date = xrefb.screening_date
and cinelight_spot.billing_date = xrefa.screening_date
and spot_status <> 'P'
and spot_type in ('S','N','C','B')
and cinelight_spot.spot_type = spot_type.spot_type_code
--and xrefa.benchmark_end >= '1-jun-2004'
and branch_code = 'Z'
group by film_campaign.campaign_no, product_desc, cinelight_spot.screening_date, billing_date, spot_type_desc, xrefa.benchmark_end, xrefb.benchmark_end

union

select 'Cinemarketing', film_campaign.campaign_no, product_desc, inclusion_spot.screening_date, billing_date, spot_type_desc, sum(charge_rate) as revenue, count(spot_id) as no_spots, xrefa.benchmark_end, xrefb.benchmark_end,
(select sum(charge_rate) from inclusion_spot where campaign_no = film_campaign.campaign_no and inclusion_id in (select inclusion_id from inclusion where campaign_no = film_campaign.campaign_no and inclusion_type = 5)  ) / (select count(spot_id) from inclusion_spot where campaign_no = film_campaign.campaign_no and inclusion_id in (select inclusion_id from inclusion where campaign_no = film_campaign.campaign_no and inclusion_type = 5)  and spot_type in ('S','B','C','N')) as avg_rate_all_spots
from inclusion_spot, film_campaign, film_screening_date_xref xrefa, film_screening_date_xref xrefb, spot_type
where film_campaign.campaign_no = inclusion_spot.campaign_no
and inclusion_spot.screening_date = xrefb.screening_date
and inclusion_spot.billing_date = xrefa.screening_date
and spot_status <> 'P'
and spot_type in ('S','N','C','B')
and inclusion_id in (select inclusion_id from inclusion where inclusion_type = 5)
and inclusion_spot.spot_type = spot_type.spot_type_code
--and xrefa.benchmark_end >= '1-jun-2004'
and branch_code = 'Z'
group by film_campaign.campaign_no, product_desc, inclusion_spot.screening_date, billing_date, spot_type_desc, xrefa.benchmark_end, xrefb.benchmark_end

union

select inclusion_category_desc, film_campaign.campaign_no, product_desc, dateadd(dd, -6, inclusion_spot.revenue_period), dateadd(dd, -6, inclusion_spot.revenue_period), 'Takeout', -1 * sum(takeout_rate) as revenue, 
count(spot_id) as no_spots, inclusion_spot.revenue_period, inclusion_spot.revenue_period, 0
from inclusion_spot, film_campaign, inclusion, inclusion_category
where film_campaign.campaign_no = inclusion_spot.campaign_no
and inclusion_spot.inclusion_id = inclusion.inclusion_id
and film_campaign.campaign_no = inclusion.campaign_no
and inclusion.inclusion_category = inclusion_category.inclusion_category
and inclusion.inclusion_category <> 'S'
and inclusion.inclusion_type <> 21
and spot_status <> 'P'
--and inclusion_spot.revenue_period >= '1-jun-2004'
and branch_code = 'Z'
group by inclusion_category_desc, film_campaign.campaign_no, product_desc, inclusion_spot.revenue_period
GO
