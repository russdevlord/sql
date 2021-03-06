/****** Object:  View [dbo].[v_projbill_bu_mp_ad_hoyts]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_projbill_bu_mp_ad_hoyts]
GO
/****** Object:  View [dbo].[v_projbill_bu_mp_ad_hoyts]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE VIEW [dbo].[v_projbill_bu_mp_ad_hoyts]
AS

    select      aph.finyear_end 'finyear', 
                aph.benchmark_end 'accounting_period',
                fc.branch_code  'branch_code',
                fc.business_unit_id 'business_unit_id',
                cp.media_product_id 'media_product_id',
                fc.agency_deal 'agency_deal',
                sum(isnull(cs.charge_rate,0)) 'billings'
    from        v_spots_non_proposed cs,
                accounting_period_hoyts aph,
                campaign_package cp,
                film_campaign fc
    where       cs.billing_date between aph.benchmark_start and aph.benchmark_end
    and         cs.package_id = cp.package_id
    and         cp.campaign_no = fc.campaign_no
    group by    aph.finyear_end,
                aph.benchmark_end,
                fc.branch_code,
                fc.business_unit_id,
                cp.media_product_id,
                fc.agency_deal
GO
