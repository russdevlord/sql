/****** Object:  View [dbo].[v_projbill_bu_mp_ad_cinelights]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_projbill_bu_mp_ad_cinelights]
GO
/****** Object:  View [dbo].[v_projbill_bu_mp_ad_cinelights]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE VIEW [dbo].[v_projbill_bu_mp_ad_cinelights]
AS

    select      x.finyear_end 'finyear', 
                x.benchmark_end 'accounting_period',
                cbd.branch_code  'branch_code',
                cbd.business_unit_id 'business_unit_id',
                cbd.media_product_id 'media_product_id',
                cbd.agency_deal 'agency_deal',
                sum(isnull(cbd.charge_rate,0) * (convert(numeric(6,4),x.no_days)/7.0)) 'billings'
    from        v_cinemarketing_billing_data cbd,
                film_screening_date_xref x
    where       cbd.screening_week = x.screening_date
    and         cbd.billing_status != 'P'
    group by    x.finyear_end,
                x.benchmark_end,
                cbd.branch_code,
                cbd.business_unit_id,
                cbd.media_product_id,
                cbd.agency_deal
GO
