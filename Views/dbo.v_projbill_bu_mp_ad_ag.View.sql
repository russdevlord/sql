/****** Object:  View [dbo].[v_projbill_bu_mp_ad_ag]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_projbill_bu_mp_ad_ag]
GO
/****** Object:  View [dbo].[v_projbill_bu_mp_ad_ag]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE VIEW [dbo].[v_projbill_bu_mp_ad_ag]
AS

    select      x.finyear_end 'finyear', 
                x.benchmark_end 'accounting_period',
                fc.branch_code  'branch_code',
                fc.business_unit_id 'business_unit_id',
                cp.media_product_id 'media_product_id',
                fc.agency_deal 'agency_deal',
                sum(isnull(cs.charge_rate,0) * (convert(numeric(6,4),x.no_days)/7.0)) 'billings',
                a.agency_id 'agency_id'
    from        v_spots_non_proposed cs,
                film_screening_date_xref x,
                campaign_package cp,
                film_campaign fc,
                agency a
    where       cs.billing_date = x.screening_date
    and         cs.package_id = cp.package_id
    and         cp.campaign_no = fc.campaign_no
    and         a.agency_id = fc.reporting_agency
    group by    x.finyear_end,
                x.benchmark_end,
                fc.branch_code,
                fc.business_unit_id,
                cp.media_product_id,
                fc.agency_deal,
                a.agency_id
GO
