/****** Object:  View [dbo].[v_projbill_bu_mp_ad_abg]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_projbill_bu_mp_ad_abg]
GO
/****** Object:  View [dbo].[v_projbill_bu_mp_ad_abg]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE VIEW [dbo].[v_projbill_bu_mp_ad_abg]
AS

    select      x.finyear_end 'finyear', 
                x.benchmark_end 'accounting_period',
                fc.branch_code  'branch_code',
                fc.business_unit_id 'business_unit_id',
                cp.media_product_id 'media_product_id',
                fc.agency_deal 'agency_deal',
                sum(isnull(cs.charge_rate,0) * (convert(numeric(6,4),x.no_days)/7.0)) 'billings',
                abg.buying_group_id 'buying_group_id'
    from        v_spots_non_proposed cs,
                film_screening_date_xref x,
                campaign_package cp,
                film_campaign fc,
                agency a,
                agency_groups ag,
                agency_buying_groups abg
    where       cs.billing_date = x.screening_date
    and         cs.package_id = cp.package_id
    and         cp.campaign_no = fc.campaign_no
    and         a.agency_id = fc.reporting_agency
    and         a.agency_group_id = ag.agency_group_id
    and         ag.buying_group_id = abg.buying_group_id
    group by    x.finyear_end,
                x.benchmark_end,
                fc.branch_code,
                fc.business_unit_id,
                cp.media_product_id,
                fc.agency_deal,
                abg.buying_group_id
union
    select      x.finyear_end 'finyear', 
                x.benchmark_end 'accounting_period',
                fc.branch_code  'branch_code',
                fc.business_unit_id 'business_unit_id',
                cp.media_product_id 'media_product_id',
                fc.agency_deal 'agency_deal',
                sum(isnull(cs.charge_rate,0) * (convert(numeric(6,4),x.no_days)/7.0)) 'billings',
                abg.buying_group_id 'buying_group_id'
    from        v_cinelight_spots_non_proposed cs,
                film_screening_date_xref x,
                cinelight_package cp,
                film_campaign fc,
                agency a,
                agency_groups ag,
                agency_buying_groups abg
    where       cs.billing_date = x.screening_date
    and         cs.package_id = cp.package_id
    and         cp.campaign_no = fc.campaign_no
    and         a.agency_id = fc.reporting_agency
    and         a.agency_group_id = ag.agency_group_id
    and         ag.buying_group_id = abg.buying_group_id
    group by    x.finyear_end,
                x.benchmark_end,
                fc.branch_code,
                fc.business_unit_id,
                cp.media_product_id,
                fc.agency_deal,
                abg.buying_group_id
GO
