/****** Object:  View [dbo].[v_michael_screening_date]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_michael_screening_date]
GO
/****** Object:  View [dbo].[v_michael_screening_date]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE VIEW [dbo].[v_michael_screening_date]
AS

    select      ap.finyear_end 'finyear', 
                ap.benchmark_end 'accounting_period',
                fc.branch_code  'branch_code',
                fc.business_unit_id 'business_unit_id',
                cp.media_product_id 'media_product_id',
                fc.agency_deal 'agency_deal',
                sum(isnull(cs.charge_rate,0)) 'billings'
    from        v_spots_non_proposed cs,
                accounting_period ap,
                campaign_package cp,
                film_campaign fc
    where       cs.screening_date between ap.benchmark_start and ap.benchmark_end
    and         cs.package_id = cp.package_id
    and         cp.campaign_no = fc.campaign_no
    group by    ap.finyear_end,
                ap.benchmark_end,
                fc.branch_code,
                fc.business_unit_id,
                cp.media_product_id,
                fc.agency_deal
GO
