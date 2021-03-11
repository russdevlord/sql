USE [production]
GO
/****** Object:  View [dbo].[v_michael_bonus]    Script Date: 11/03/2021 2:30:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE VIEW [dbo].[v_michael_bonus]
AS

    select      ap.finyear_end 'finyear', 
                ap.benchmark_end 'accounting_period',
                fc.branch_code  'branch_code',
                fc.business_unit_id 'business_unit_id',
                cp.media_product_id 'media_product_id',
                fc.agency_deal 'agency_deal',
                sum(isnull(cp.charge_rate,0)) 'billings'
    from        campaign_spot cs,
                accounting_period ap,
                campaign_package cp,
                film_campaign fc
    where       cs.billing_date between ap.benchmark_start and ap.benchmark_end
    and         cs.package_id = cp.package_id
    and         cp.campaign_no = fc.campaign_no
    and         spot_status != 'P'
    and         spot_type = 'B'
    group by    ap.finyear_end,
                ap.benchmark_end,
                fc.branch_code,
                fc.business_unit_id,
                cp.media_product_id,
                fc.agency_deal
GO
