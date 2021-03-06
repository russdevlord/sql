/****** Object:  View [dbo].[v_projbill_bu_mp_ad_abg_cinelights]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP VIEW [dbo].[v_projbill_bu_mp_ad_abg_cinelights]
GO
/****** Object:  View [dbo].[v_projbill_bu_mp_ad_abg_cinelights]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE VIEW [dbo].[v_projbill_bu_mp_ad_abg_cinelights]
AS

    select      x.finyear_end 'finyear', 
                x.benchmark_end 'accounting_period',
                fc.branch_code  'branch_code',
                fc.business_unit_id 'business_unit_id',
                3 'media_product_id',
                fc.agency_deal 'agency_deal',
                sum(isnull(cb.charge_rate,0) * (convert(numeric(6,4),x.no_days)/7.0)) 'billings',
                abg.buying_group_id 'buying_group_id'
    from        cinelight_billings cb,
                cinelight_campaigns cc,
                film_screening_date_xref x,
                agency a,
                agency_groups ag,
                agency_buying_groups abg,
                film_campaign fc
    where       cc.cinelight_campaign_no = cb.cinelight_campaign_no
    and         cb.screening_week = x.screening_date
    and         a.agency_id = fc.agency_id
    and         a.agency_group_id = ag.agency_group_id
    and         ag.buying_group_id = abg.buying_group_id
    and         cb.billing_status != 'P'
    and         cc.campaign_no = fc.campaign_no
    group by    x.finyear_end,
                x.benchmark_end,
                fc.branch_code,
                fc.business_unit_id,
                fc.agency_deal,
                abg.buying_group_id
GO
