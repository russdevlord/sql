/****** Object:  View [dbo].[v_bill_scr_diff_ret]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_bill_scr_diff_ret]
GO
/****** Object:  View [dbo].[v_bill_scr_diff_ret]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
create view [dbo].[v_bill_scr_diff_ret]
as
select 'Retail Panels' as revenue_type, film_campaign.campaign_no, product_desc, outpost_spot.screening_date, billing_date, spot_type_desc, sum(charge_rate) as revenue, count(spot_id) as no_spots, xrefa.benchmark_end as billing_month, xrefb.benchmark_end as screening_month,
(select sum(charge_rate) from outpost_spot where campaign_no = film_campaign.campaign_no) / (select count(spot_id) from outpost_spot where campaign_no = film_campaign.campaign_no and spot_type in ('S','B','C','N')) as avg_rate_all_spots
from outpost_spot, film_campaign, outpost_screening_date_xref xrefa, outpost_screening_date_xref xrefb, spot_type
where film_campaign.campaign_no = outpost_spot.campaign_no
and outpost_spot.screening_date = xrefb.screening_date
and outpost_spot.billing_date = xrefa.screening_date
and spot_status <> 'P'
and spot_type in ('S','N','C','B')
and outpost_spot.spot_type = spot_type.spot_type_code
--and xrefa.benchmark_end >= '1-jun-2007'
and branch_code <> 'Z'
group by film_campaign.campaign_no, product_desc, outpost_spot.screening_date, billing_date, spot_type_desc, xrefa.benchmark_end, xrefb.benchmark_end

union

select 'Retail Moving Wall', film_campaign.campaign_no, product_desc, inclusion_spot.op_screening_date, op_billing_date, spot_type_desc, sum(charge_rate) as revenue, count(spot_id) as no_spots, xrefa.benchmark_end, xrefb.benchmark_end,
(select sum(charge_rate) from inclusion_spot where campaign_no = film_campaign.campaign_no and inclusion_id in (select inclusion_id from inclusion where campaign_no = film_campaign.campaign_no and inclusion_type = 18)  ) / (select count(spot_id) from inclusion_spot where campaign_no = film_campaign.campaign_no and inclusion_id in (select inclusion_id from inclusion where campaign_no = film_campaign.campaign_no and inclusion_type = 18)  and spot_type in ('S','B','C','N')) as avg_rate_all_spots
from inclusion_spot, film_campaign, outpost_screening_date_xref xrefa, outpost_screening_date_xref xrefb, spot_type
where film_campaign.campaign_no = inclusion_spot.campaign_no
and inclusion_spot.op_screening_date = xrefb.screening_date
and inclusion_spot.op_billing_date = xrefa.screening_date
and spot_status <> 'P'
and spot_type in ('S','N','C','B')
and inclusion_id in (select inclusion_id from inclusion where inclusion_type = 18)
and inclusion_spot.spot_type = spot_type.spot_type_code
--and xrefa.benchmark_end >= '1-jun-2007'
and branch_code <> 'Z'
group by film_campaign.campaign_no, product_desc, inclusion_spot.op_screening_date, op_billing_date, spot_type_desc, xrefa.benchmark_end, xrefb.benchmark_end
GO
