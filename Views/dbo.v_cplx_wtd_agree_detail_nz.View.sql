/****** Object:  View [dbo].[v_cplx_wtd_agree_detail_nz]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_cplx_wtd_agree_detail_nz]
GO
/****** Object:  View [dbo].[v_cplx_wtd_agree_detail_nz]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
create view [dbo].[v_cplx_wtd_agree_detail_nz]

as

select      distinct cap.cinema_agreement_id, 
			rev.revenue_source,
            rev.complex_id,
            rev.accounting_period,
            com.complex_name,
            com.branch_code,
            revenue_desc,
            sum(isnull(rev.cinema_amount, 0)) as revenue,
            cag.agreement_desc,
            weighting,
            region_class_desc, (select count(*) from cinema where complex_id = rev.complex_id and active_flag = 'Y') as no_cinemas,
            fc.campaign_no,
            fc.product_desc,
            ltyp.liability_type_desc as revenue_type,
            lcat.liability_category_desc as revenue_master_type
from        film_revenue_creation rev, 
            complex com, 
            cinema_agreement_policy cap, 
            cinema_agreement cag, 
            cinema_revenue_source,
            film_campaign fc,
            complex_region_class crc,
            complex_rent_groups crg,
            liability_type ltyp, 
            liability_category lcat
where       cap.cinema_agreement_id = cag.cinema_agreement_id 
and         rev.complex_id = com.complex_id
and         cap.complex_id = com.complex_id
and         cap.revenue_source = rev.revenue_source
and         cap.policy_status_code = 'A' 
and         com.branch_code = 'Z'
and         fc.campaign_no = rev.campaign_no
and         ltyp.liability_type_id <> 3
and         ltyp.liability_type_id <> 158
and         ltyp.liability_type_id <> 98
and         ltyp.liability_type_id <> 99
and         isnull(cap.rent_inclusion_start, '1-jan-1900') <= rev.accounting_period
and         isnull(cap.rent_inclusion_end, '1-jan-2050') >= rev.accounting_period
and         cinema_revenue_source.revenue_source = rev.revenue_source 
and         com.complex_region_class = crc.complex_region_class
and         com.complex_rent_group = crg.rent_group_no
and         rev.liability_type_id = ltyp.liability_type_id
and         ltyp.liability_category_id = lcat.liability_category_id
group by    cap.cinema_agreement_id,
			rev.complex_id, 
            rev.accounting_period, 
            com.branch_code,
            com.complex_name, 
            revenue_desc,
            rev.revenue_source,
            fc.commission, 
            cag.agreement_desc,
            weighting,
            region_class_desc,
            fc.campaign_no,
            fc.product_desc,
            ltyp.liability_type_desc,
            lcat.liability_category_desc
GO
