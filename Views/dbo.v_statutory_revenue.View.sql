/****** Object:  View [dbo].[v_statutory_revenue]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_statutory_revenue]
GO
/****** Object:  View [dbo].[v_statutory_revenue]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
create view [dbo].[v_statutory_revenue]
as
select      fc.campaign_no 'campaign_no',
            fc.product_desc 'campaign desc',
            x.benchmark_end 'accounting_period',
            fc.branch_code  'branch_code',
            fc.business_unit_id 'business_unit_id',
            cp.media_product_id 'media_product_id',
            count(spot_id) 'no_spots',
            spot_type_desc 'Spot Type',
            'Standard' as 'Revenue Type',
            x.screening_date 'Screening Date',
            ((select sum(charge_rate) from v_spots_non_proposed where campaign_no = fc.campaign_no) + (select sum(makegood_rate) from v_spots_non_proposed where campaign_no = fc.campaign_no)) / (select count(spot_id) from v_spots_non_proposed where campaign_no = fc.campaign_no and spot_type not in ('V','M')) as 'Average Rate'

from        v_spots_non_proposed cs,
            film_screening_date_xref x,
            campaign_package cp,
            film_campaign fc,
            spot_type
where       cs.screening_date = x.screening_date
and         cs.package_id = cp.package_id
and         cp.campaign_no = fc.campaign_no
and         cs.spot_type = spot_type.spot_type_code
and         cs.spot_type not in ('V','M')
and         cs.dandc  = 'N'
group by    fc.campaign_no,
            fc.product_desc,
            x.benchmark_end,
            fc.branch_code,
            fc.business_unit_id,
            cp.media_product_id,
            spot_type_desc,
            x.screening_date
union all
select      fc.campaign_no 'campaign_no',
            fc.product_desc,
            x.benchmark_end 'accounting_period',
            fc.branch_code  'branch_code',
            fc.business_unit_id 'business_unit_id',
            cp.media_product_id 'media_product_id',
            count(spot_id) 'no_spots',
            spot_type_desc 'Spot Type',
            'Standard' as 'Revenue Type',
            x.screening_date 'Screening Date',
            ((select sum(charge_rate) from v_cinelight_spots_non_proposed where campaign_no = fc.campaign_no) + (select sum(makegood_rate) from v_cinelight_spots_non_proposed where campaign_no = fc.campaign_no)) / (select count(spot_id) from v_cinelight_spots_non_proposed where campaign_no = fc.campaign_no and spot_type not in ('V','M')) as 'Average Rate'

from        v_cinelight_spots_non_proposed cs,
            film_screening_date_xref x,
            cinelight_package cp,
            film_campaign fc,
            spot_type
where       cs.screening_date = x.screening_date
and         cs.package_id = cp.package_id
and         cp.campaign_no = fc.campaign_no
and         cs.spot_type = spot_type.spot_type_code
and         cs.spot_type not in ('V','M')
and         cs.dandc  = 'N'
group by    fc.campaign_no,
            fc.product_desc,
            x.benchmark_end,
            fc.branch_code,
            fc.business_unit_id,
            cp.media_product_id,
            spot_type_desc,
            x.screening_date
union all
select      fc.campaign_no 'campaign_no',
            fc.product_desc,
            x.benchmark_end 'accounting_period',
            fc.branch_code  'branch_code',
            fc.business_unit_id 'business_unit_id',
            6 'media_product_id',
            count(spot_id) 'no_spots',
            spot_type_desc 'Spot Type',
            'Standard' as 'Revenue Type',
            x.screening_date 'Screening Date',
            ((select sum(charge_rate) from v_cinemarketing_spots_non_proposed where campaign_no = fc.campaign_no) + (select sum(makegood_rate) from v_cinemarketing_spots_non_proposed where campaign_no = fc.campaign_no)) / (select count(spot_id) from v_cinemarketing_spots_non_proposed where campaign_no = fc.campaign_no and spot_type not in ('V','M')) as 'Average Rate'
from        v_cinemarketing_spots_non_proposed cs,
            film_screening_date_xref x,
            inclusion inc,
            film_campaign fc,
            spot_type
where       cs.screening_date = x.screening_date
and         cs.inclusion_id = inc.inclusion_id
and         inc.campaign_no = fc.campaign_no
and         cs.spot_type = spot_type.spot_type_code
and         cs.spot_type not in ('V','M')
and         cs.dandc  = 'N'
group by    fc.campaign_no,
            fc.product_desc,
            x.benchmark_end,
            fc.branch_code,
            fc.business_unit_id,
            spot_type_desc,
            x.screening_date
union all        
select      fc.campaign_no 'campaign_no',
            fc.product_desc,
            cs.revenue_period 'accounting_period',
            fc.branch_code  'branch_code',
            fc.business_unit_id 'business_unit_id',
            (case inc.inclusion_category when 'C' then 3 when 'D' then 2 when 'F' then 1 when 'I' then 6 end)  as 'media_product_id',
            count(spot_id) 'no_spots',
            'Takeouts',
            'Takeouts',
            dateadd(dd, -6, cs.revenue_period) 'Screening Date',
            avg(isnull(cs.takeout_rate,0)) * -1 'Average Rate'
from        inclusion_spot cs,
            inclusion inc,
            film_campaign fc
where       cs.inclusion_id = inc.inclusion_id
and         inc.campaign_no = fc.campaign_no
and         inclusion_category <> 'S'
and         spot_status <> 'P'
group by    fc.campaign_no,
            fc.product_desc,
            cs.revenue_period,
            fc.branch_code,
            fc.business_unit_id,
            inc.inclusion_category
union all
SELECT 	    fc.campaign_no 'campaign_no',
            fc.product_desc,
            sl.creation_period  'accounting_period',
            fc.branch_code  'branch_code',
            fc.business_unit_id 'business_unit_id',
            1 as 'media_product_id',
            count(sl.spot_id),
            'Agency Billing Credits',
            'Agency Billing Credits',
            dateadd(dd, -6, sl.creation_period) 'Screening Date',
            avg(isnull(sl.spot_amount ,0)) 'Average Rate'
FROM 		campaign_spot cs,
            spot_liability sl,
            film_campaign fc
WHERE		cs.spot_status != 'P'
AND 		sl.liability_type = 7 
AND 		cs.spot_id  = sl.spot_id
and         cs.campaign_no = fc.campaign_no
GROUP BY	fc.campaign_no,
            fc.product_desc,
            sl.creation_period,
            fc.branch_code,
            fc.business_unit_id
union all
SELECT 	    fc.campaign_no 'campaign_no',
            fc.product_desc,
            sl.creation_period  'accounting_period',
            fc.branch_code  'branch_code',
            fc.business_unit_id 'business_unit_id',
            2 as 'media_product_id',
            count(sl.spot_id),
            'Agency Billing Credits',
            'Agency Billing Credits',
            dateadd(dd, -6, sl.creation_period) 'Screening Date',
            avg(isnull(sl.spot_amount ,0)) 'Average Rate'
FROM 		campaign_spot cs,
            spot_liability sl,
            film_campaign fc
WHERE		cs.spot_status != 'P'
AND 		sl.liability_type = 8
AND 		cs.spot_id  = sl.spot_id
and         cs.campaign_no = fc.campaign_no
GROUP BY	fc.campaign_no,
            fc.product_desc,
            sl.creation_period,
            fc.branch_code,
            fc.business_unit_id
union all
SELECT 	    fc.campaign_no 'campaign_no',
            fc.product_desc,
            sl.creation_period  'accounting_period',
            fc.branch_code  'branch_code',
            fc.business_unit_id 'business_unit_id',
            3 as 'media_product_id',
            count(sl.spot_id),
            'Agency Billing Credits',
            'Agency Billing Credits',
            dateadd(dd, -6, sl.creation_period) 'Screening Date',
            avg(isnull(sl.spot_amount ,0)) 'Average Rate'
FROM 		cinelight_spot cs,
            cinelight_spot_liability sl,
            film_campaign fc
WHERE		cs.spot_status != 'P'
AND 		sl.liability_type = 13 
AND 		cs.spot_id  = sl.spot_id
and         cs.campaign_no = fc.campaign_no
GROUP BY	fc.campaign_no,
            fc.product_desc,
            sl.creation_period,
            fc.branch_code,
            fc.business_unit_id
union all
SELECT 	    fc.campaign_no 'campaign_no',
            fc.product_desc,
            sl.creation_period  'accounting_period',
            fc.branch_code  'branch_code',
            fc.business_unit_id 'business_unit_id',
            6 as 'media_product_id',
            count(sl.spot_id),
            'Agency Billing Credits',
            'Agency Billing Credits',
            dateadd(dd, -6, sl.creation_period) 'Screening Date',
            avg(isnull(sl.spot_amount ,0)) 'Average Rate'
FROM 		inclusion_spot cs,
            inclusion_spot_liability sl,
            film_campaign fc
WHERE		cs.spot_status != 'P'
AND 		sl.liability_type = 16 
AND 		cs.spot_id  = sl.spot_id
and         cs.campaign_no = fc.campaign_no
GROUP BY	fc.campaign_no,
            fc.product_desc,
            sl.creation_period,
            fc.branch_code,
            fc.business_unit_id
GO
