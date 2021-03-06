/****** Object:  View [dbo].[v_statrev_excel]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_statrev_excel]
GO
/****** Object:  View [dbo].[v_statrev_excel]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


create view [dbo].[v_statrev_excel]
as
select cal_year, cal_half, cal_qtr, fin_year, fin_half, fin_qtr,client_group_desc, client_name, agency_name, agency_group_name, buying_group_desc, branch_name, business_unit_desc, master_revenue_group_desc, country_name, campaign_no, product_desc, sum(rev) as revenue
from v_statrev_agency
group by cal_year, cal_half, cal_qtr, fin_year, fin_half, fin_qtr,client_group_desc, client_name, agency_name, agency_group_name, buying_group_desc, branch_name, business_unit_desc, master_revenue_group_desc, country_name, campaign_no, product_desc
GO
