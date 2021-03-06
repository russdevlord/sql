/****** Object:  View [dbo].[v_cplx_nz_proj_no_agree]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_cplx_nz_proj_no_agree]
GO
/****** Object:  View [dbo].[v_cplx_nz_proj_no_agree]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
create view [dbo].[v_cplx_nz_proj_no_agree]
as 
select      distinct rev.revenue_source,
            rev.complex_id,
            fsdx.benchmark_end,
            com.complex_name,
            com.branch_code,
            revenue_desc,
            (sum(isnull(rev.cinema_rate, 0)) + sum(isnull(rev.makegood_rate, 0)) - sum(isnull(rev.takeout_rate, 0))) * (1 - fc.commission) as revenue,
            rent_group_no,
            region_class_desc, (select count(*) from cinema where complex_id = rev.complex_id and active_flag = 'Y') as no_cinemas
from        complex_projected_revenue rev, 
            complex com, 
            film_screening_date_xref fsdx,
            cinema_revenue_source,
            film_campaign fc,
            complex_region_class crc,
            complex_rent_groups crg
where       fsdx.screening_date = rev.billing_date
and         fsdx.benchmark_end not in (select accounting_period from film_revenue)
and         rev.complex_id = com.complex_id
and         com.branch_code = 'Z'
and         fc.campaign_no = rev.campaign_no
and         cinema_revenue_source.revenue_source = rev.revenue_source
and         com.complex_region_class = crc.complex_region_class
and         com.complex_rent_group = crg.rent_group_no
group by    rev.complex_id, 
            fsdx.benchmark_end, 
            com.branch_code,
            com.complex_name, 
            revenue_desc,
            rev.revenue_source,
            fc.commission,
            rent_group_no,
            region_class_desc
union all

select      distinct rev.revenue_source,
            rev.complex_id,
            rev.accounting_period,
            com.complex_name,
            com.branch_code,
            revenue_desc,
            sum(isnull(rev.cinema_amount, 0)),
            rent_group_no,
            region_class_desc, (select count(*) from cinema where complex_id = rev.complex_id and active_flag = 'Y') as no_cinemas
from        film_revenue rev, 
            complex com, 
            cinema_revenue_source,
            film_campaign fc,
            complex_region_class crc,
            complex_rent_groups crg
where       rev.complex_id = com.complex_id
and         com.branch_code = 'Z'
and         fc.campaign_no = rev.campaign_no
and         liability_type_id <> 3
and         liability_type_id <> 158
and         liability_type_id <> 98
and         liability_type_id <> 99
and         cinema_revenue_source.revenue_source = rev.revenue_source  
and         com.complex_region_class = crc.complex_region_class
and         com.complex_rent_group = crg.rent_group_no
group by    rev.complex_id, 
            rev.accounting_period, 
            com.branch_code,
            com.complex_name, 
            revenue_desc,
            rev.revenue_source,
            fc.commission,
            rent_group_no,
            region_class_desc
GO
