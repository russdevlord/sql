/****** Object:  View [dbo].[v_cplx_aus_proj_agree]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_cplx_aus_proj_agree]
GO
/****** Object:  View [dbo].[v_cplx_aus_proj_agree]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
create view [dbo].[v_cplx_aus_proj_agree]
as
select      distinct cap.cinema_agreement_id, 
			rev.revenue_source,
            rev.complex_id,
            fsdx.benchmark_end,
            com.complex_name,
            com.branch_code,
            revenue_desc,
            (sum(isnull(rev.cinema_rate, 0)) + sum(isnull(rev.makegood_rate, 0)) - sum(isnull(rev.takeout_rate, 0))) * (1 - fc.commission) as revenue,
            cag.agreement_desc,
            weighting,
            region_class_desc, (select count(*) from cinema where complex_id = rev.complex_id and active_flag = 'Y') as no_cinemas
from        complex_projected_revenue rev, 
            complex com, 
            cinema_agreement_policy cap, 
            cinema_agreement cag, 
            film_screening_date_xref fsdx,
            cinema_revenue_source,
            film_campaign fc,
            complex_region_class crc,
            complex_rent_groups crg
where       fsdx.screening_date = rev.billing_date
and         fsdx.benchmark_end not in (select accounting_period from film_revenue)
and         cap.cinema_agreement_id = cag.cinema_agreement_id 
and         rev.complex_id = com.complex_id
and         cap.complex_id = com.complex_id
and         cap.revenue_source = rev.revenue_source
and         cap.policy_status_code = 'A' 
and         com.branch_code <> 'Z'
and         fc.campaign_no = rev.campaign_no
and         isnull(cap.rent_inclusion_start, '1-jan-1900') <= fsdx.benchmark_end
and         isnull(cap.rent_inclusion_end, '1-jan-2050') >= fsdx.benchmark_end   
and         cinema_revenue_source.revenue_source = rev.revenue_source  
and         com.complex_region_class = crc.complex_region_class
and         com.complex_rent_group = crg.rent_group_no
group by    cap.cinema_agreement_id,
			rev.complex_id, 
            fsdx.benchmark_end, 
            com.branch_code,
            com.complex_name, 
            revenue_desc,
            rev.revenue_source,
            fc.commission, 
            cag.agreement_desc,
            weighting,
            region_class_desc
union all

select      distinct cap.cinema_agreement_id, 
			rev.revenue_source,
            rev.complex_id,
            rev.accounting_period,
            com.complex_name,
            com.branch_code,
            revenue_desc,
            sum(isnull(rev.cinema_amount, 0)),
            cag.agreement_desc,
            weighting,
            region_class_desc, (select count(*) from cinema where complex_id = rev.complex_id and active_flag = 'Y') as no_cinemas
from        film_revenue rev, 
            complex com, 
            cinema_agreement_policy cap, 
            cinema_agreement cag, 
            cinema_revenue_source,
            film_campaign fc,
            complex_region_class crc,
            complex_rent_groups crg
where       cap.cinema_agreement_id = cag.cinema_agreement_id 
and         rev.complex_id = com.complex_id
and         cap.complex_id = com.complex_id
and         cap.revenue_source = rev.revenue_source
and         cap.policy_status_code = 'A' 
and         com.branch_code <> 'Z'
and         fc.campaign_no = rev.campaign_no
and         liability_type_id <> 3
and         liability_type_id <> 158
and         liability_type_id <> 98
and         liability_type_id <> 99
and         isnull(cap.rent_inclusion_start, '1-jan-1900') <= rev.accounting_period
and         isnull(cap.rent_inclusion_end, '1-jan-2050') >= rev.accounting_period
and         cinema_revenue_source.revenue_source = rev.revenue_source 
and         com.complex_region_class = crc.complex_region_class
and         com.complex_rent_group = crg.rent_group_no
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
            region_class_desc
GO
