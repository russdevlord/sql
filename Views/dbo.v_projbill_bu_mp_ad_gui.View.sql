/****** Object:  View [dbo].[v_projbill_bu_mp_ad_gui]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_projbill_bu_mp_ad_gui]
GO
/****** Object:  View [dbo].[v_projbill_bu_mp_ad_gui]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE VIEW [dbo].[v_projbill_bu_mp_ad_gui]
AS

    select      v.finyear 'finyear',
                v.accounting_period 'accounting_period',
                ct.country_name 'country',
                br.branch_name 'branch',
                bu.business_unit_desc 'business_unit',
                mp.media_product_desc 'media_product',
                case when v.agency_deal = 'Y' then 'YES' else 'NO' end 'agency_deal',
                v.billings 'billings'
    from        v_projbill_bu_mp_ad v,
                branch br,
                business_unit bu,
                media_product mp,
                country ct
    where       v.branch_code = br.branch_code
    and         v.business_unit_id = bu.business_unit_id
    and         v.media_product_id = mp.media_product_id
    and         br.country_code = ct.country_code
GO
