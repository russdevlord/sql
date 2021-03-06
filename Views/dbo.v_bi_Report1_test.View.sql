/****** Object:  View [dbo].[v_bi_Report1_test]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_bi_Report1_test]
GO
/****** Object:  View [dbo].[v_bi_Report1_test]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create View [dbo].[v_bi_Report1_test] 
AS
WITH v_statrev_Agency (fin_year)
AS ( 
	SELECT DISTINCT fin_year from v_bi_statrev_unit_report UNION ALL
	SELECT DATEADD(Y, -1, fin_year) from v_bi_statrev_unit_report UNION ALL
	SELECT fin_qtr from v_bi_statrev_unit_report UNION ALL
	Select fin_half from v_bi_statrev_unit_report UNION ALL
	Select fin_Month from v_bi_statrev_unit_report
	)
	, Test(fin_year,fin_qtr,fin_half,fin_month, campaign_no, 
product_desc,  
client_group_desc, 
client_name, 
agency_name, 
agency_group_name, 
buying_group_desc, 
branch_name,
business_unit_desc, 
master_revenue_group_desc, 
revenue_group_desc, 
statrev_transaction_type_desc, 
revenue_period,
delta_date,
rev)

AS
	(Select fin_year,fin_qtr,fin_half,fin_month, campaign_no, 
	product_desc,  
client_group_desc, 
client_name, 
agency_name, 
agency_group_name, 
buying_group_desc, 
branch_name,
business_unit_desc, 
master_revenue_group_desc, 
revenue_group_desc, 
statrev_transaction_type_desc, 
revenue_period,
delta_date,
		Sum(Rev) Rev 
	from v_bi_statrev_unit_report
	Group by fin_year, fin_qtr, fin_half, fin_month,campaign_no,  product_desc,  
client_group_desc, 
client_name, 
agency_name, 
agency_group_name, 
buying_group_desc, 
branch_name,
business_unit_desc, 
master_revenue_group_desc, 
revenue_group_desc, 
statrev_transaction_type_desc, 
revenue_period,
delta_date
	)
	
SELECT DISTINCT Sales.fin_year
	 , sales.fin_qtr
	 , sales.fin_Half	 
	 , sales.fin_month	 
     , Sales.rev,
		Sales.campaign_no,  
		Sales.product_desc,  
		Sales.client_group_desc, 
		Sales.client_name, 
		Sales.agency_name, 
		Sales.agency_group_name, 
		Sales.buying_group_desc, 
		Sales.branch_name,
		Sales.business_unit_desc, 
		Sales.master_revenue_group_desc, 
		Sales.revenue_group_desc, 
		Sales.statrev_transaction_type_desc, 
		Sales.revenue_period,
	  Sales.delta_date
     ,prev.fin_year AS Prev_Fin_Year
     ,prev.fin_qtr AS Prev_Fin_Qtr
     ,prev.fin_Half AS Prev_Fin_Half
     ,prev.fin_month AS Prev_Fin_Month
     ,Prev.rev AS prev_Rev
FROM TEST Sales
      LEFT OUTER JOIN
       Test PREV
       ON PREV.fin_year = DATEADD(Y,-1,sales.fin_year)
       AND prev.fin_qtr = sales.fin_qtr
       AND prev.fin_half = sales.fin_half
       AND prev.fin_month = sales.fin_month
       AND PREV.campaign_no = Sales.campaign_no
       AND PREV.product_desc = Sales.product_desc
AND PREV.client_group_desc = Sales.client_group_desc
AND PREV.client_name = Sales.client_name
AND PREV.agency_name = Sales.agency_name 
AND PREV.agency_group_name = Sales.agency_group_name
AND PREV.buying_group_desc = Sales.buying_group_desc 
AND PREV.branch_name = Sales.branch_name
AND PREV.business_unit_desc = Sales.business_unit_desc
AND PREV.master_revenue_group_desc = Sales.master_revenue_group_desc
AND PREV.revenue_group_desc = Sales.revenue_group_desc
AND PREV.statrev_transaction_type_desc = Sales.statrev_transaction_type_desc
AND PREV.revenue_period = DATEADD(Y,-1,Sales.revenue_period)
AND PREV.delta_date = DATEADD(Y,-1,Sales.delta_date)
Where Sales.fin_year >= 2011
AND sales.fin_year <= 2014

         /*ON CAST(  CAST(Sales.fin_year AS CHAR(4)) 
                -- + '-'
                 --+ CAST(Sales.QQ AS CHAR(2)) 
                 --+ '-01' 
                 AS DATETIME)
             =
             DATEADD(Y,-1,CAST(  CAST(PREV.fin_year AS CHAR(4)) 
                              --+ '-'
                              --+ CAST(PREV.QQ AS CHAR(2)) 
                              --+ '-01' 
                              AS DATETIME))
         --AND sales.cinetam_demographics_id = prev.cinetam_demographics_id
--ORDER BY YY,QQ,cinetam_demographics_desc*/
GO
