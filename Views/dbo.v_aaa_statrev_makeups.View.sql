/****** Object:  View [dbo].[v_aaa_statrev_makeups]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_aaa_statrev_makeups]
GO
/****** Object:  View [dbo].[v_aaa_statrev_makeups]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
create view [dbo].[v_aaa_statrev_makeups]
as
select      fc.campaign_no 'campaign_no',
            fc.product_desc 'campaign desc',
            x.benchmark_end 'accounting_period',
            fc.branch_code  'branch_code',
            fc.business_unit_id 'business_unit_id',
            cp.media_product_id 'media_product_id',
            cs.spot_id 'spot_id',
            spot_type_desc 'Spot Type',
            'Standard' as 'Revenue Type',
            x.screening_date 'Screening Date',
            ((select sum(charge_rate) from v_spots_non_proposed where campaign_no = fc.campaign_no) + (select sum(makegood_rate) from v_spots_non_proposed where campaign_no = fc.campaign_no)) / (select count(spot_id) from v_spots_non_proposed where campaign_no = fc.campaign_no and spot_type not in ('V','M')) as 'Average Rate',
            (select benchmark_end from v_spots_non_proposed, film_screening_date_xref where v_spots_non_proposed.screening_date = film_screening_date_xref.screening_date and dbo.f_spot_redirect(cs.spot_id) = v_spots_non_proposed.spot_id) as makeup_period
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
            x.screening_date,
            cs.spot_id
union all
select      fc.campaign_no 'campaign_no',
            fc.product_desc,
            x.benchmark_end 'accounting_period',
            fc.branch_code  'branch_code',
            fc.business_unit_id 'business_unit_id',
            cp.media_product_id 'media_product_id',
            cs.spot_id 'spot_id',
            spot_type_desc 'Spot Type',
            'Standard' as 'Revenue Type',
            x.screening_date 'Screening Date',
            ((select sum(charge_rate) from v_cinelight_spots_non_proposed where campaign_no = fc.campaign_no) + (select sum(makegood_rate) from v_cinelight_spots_non_proposed where campaign_no = fc.campaign_no)) / (select count(spot_id) from v_cinelight_spots_non_proposed where campaign_no = fc.campaign_no and spot_type not in ('V','M')) as 'Average Rate',
            (select benchmark_end from v_cinelight_spots_non_proposed, film_screening_date_xref where v_cinelight_spots_non_proposed.screening_date = film_screening_date_xref.screening_date and dbo.f_cl_spot_redirect(cs.spot_id) = v_cinelight_spots_non_proposed.spot_id) as makeup_period

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
            x.screening_date,
            cs.spot_id
union all
select      fc.campaign_no 'campaign_no',
            fc.product_desc,
            x.benchmark_end 'accounting_period',
            fc.branch_code  'branch_code',
            fc.business_unit_id 'business_unit_id',
            6 'media_product_id',
            cs.spot_id 'spot_id',
            spot_type_desc 'Spot Type',
            'Standard' as 'Revenue Type',
            x.screening_date 'Screening Date',
            ((select sum(charge_rate) from v_cinemarketing_spots_non_proposed where campaign_no = fc.campaign_no) + (select sum(makegood_rate) from v_cinemarketing_spots_non_proposed where campaign_no = fc.campaign_no)) / (select count(spot_id) from v_cinemarketing_spots_non_proposed where campaign_no = fc.campaign_no and spot_type not in ('V','M')) as 'Average Rate',
            (select benchmark_end from v_cinemarketing_spots_non_proposed, film_screening_date_xref where v_cinemarketing_spots_non_proposed.screening_date = film_screening_date_xref.screening_date and dbo.f_cl_spot_redirect(cs.spot_id) = v_cinemarketing_spots_non_proposed.spot_id) as makeup_period
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
            x.screening_date,
            cs.spot_id
GO
