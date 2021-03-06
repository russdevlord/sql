/****** Object:  View [dbo].[v_wk_rpt_billings]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_wk_rpt_billings]
GO
/****** Object:  View [dbo].[v_wk_rpt_billings]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE VIEW [dbo].[v_wk_rpt_billings]
AS

    select      cs.billing_date 'billing_date',
				b.country_code  'country_code',
                fc.business_unit_id 'business_unit_id',
                cp.media_product_id 'media_product_id',
				cp.revenue_source 'revenue_source',
				cs.complex_id 'complex_id',
				'' as campaign_no,
                sum(isnull(cs.charge_rate,0)) 'billings',
				sum(isnull(cs.charge_rate,0) * (fc.commission)) 'agency_commission',
				sum(isnull(cs.cinema_rate,0) * (1 - fc.commission)) 'net_billings'
    from        v_spots_non_proposed cs,
                campaign_package cp,
                film_campaign fc,
				branch b
    where       cs.package_id = cp.package_id
    and         cp.campaign_no = fc.campaign_no
	and			fc.branch_code = b.branch_code
	and			cs.spot_type in ('S','B','C','N')
    group by    cs.billing_date,
				b.country_code,
                fc.business_unit_id,
                cp.media_product_id,
				cp.revenue_source,
				cs.complex_id
	union
    select      cs.billing_date 'billing_date',
				b.country_code  'country_code',
                fc.business_unit_id 'business_unit_id',
                cp.media_product_id 'media_product_id',
				cp.revenue_source 'revenue_source',
				c.complex_id 'complex_id',
				'' as campaign_no,
                sum(isnull(cs.charge_rate,0)) 'billings',
				sum(isnull(cs.charge_rate,0) * (fc.commission)) 'agency_commission',
				sum(isnull(cs.cinema_rate,0) * (1 - fc.commission)) 'net_billings'
    from        v_cinelight_spots_non_proposed cs,
                cinelight_package cp,
				cinelight c,
                film_campaign fc,
				branch b
    where       cs.package_id = cp.package_id
    and         cp.campaign_no = fc.campaign_no
	and			fc.branch_code = b.branch_code
	and			cs.cinelight_id = c.cinelight_id
	and			cs.spot_type in ('S','B','C','N')
    group by    cs.billing_date,
				b.country_code,
                fc.business_unit_id,
                cp.media_product_id,
				cp.revenue_source,
				c.complex_id
union
    select      cs.billing_date 'billing_date',
				b.country_code  'country_code',
                fc.business_unit_id 'business_unit_id',
                6 as 'media_product_id',
				'I' as 'revenue_source',
				cs.complex_id 'complex_id',
				'' as campaign_no,
                sum(isnull(cs.charge_rate,0)) 'billings',
				sum(isnull(cs.charge_rate,0) * (fc.commission)) 'agency_commission',
				sum(isnull(cs.cinema_rate,0) * (1 - fc.commission)) 'net_billings'
    from        v_cinemarketing_spots_non_proposed cs,
                inclusion cp,
                film_campaign fc,
				branch b
    where       cs.inclusion_id = cp.inclusion_id
    and         cp.campaign_no = fc.campaign_no
	and			fc.branch_code = b.branch_code
	and			cp.inclusion_type = 5
	and			cs.spot_type in ('S','B','C','N')
    group by    cs.billing_date,
				b.country_code,
                fc.business_unit_id,
				cs.complex_id
GO
