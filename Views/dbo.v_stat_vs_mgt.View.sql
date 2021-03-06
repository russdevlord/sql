/****** Object:  View [dbo].[v_stat_vs_mgt]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_stat_vs_mgt]
GO
/****** Object:  View [dbo].[v_stat_vs_mgt]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

create view [dbo].[v_stat_vs_mgt]
as
SELECT 'Statutory' as revenue_type, datepart(dd, delta_date) as delta_day, datepart(mm, delta_date) as delta_month, datepart(yy, delta_date) as delta_year, campaign_no, revenue_period, sum (cost) as revenue, branch_name, master_revenue_group_desc, business_unit_desc  
FROM v_statrev
WHERE campaign_no in (  SELECT distinct campaign_no
                        FROM v_statrev
                        WHERE revenue_period >= '2011-01-01'
                        UNION all
                        SELECT distinct campaign_no
                        FROM v_mgtrev
                        WHERE revenue_period >= '2011-01-01')
GROUP by campaign_no, revenue_period, branch_name, master_revenue_group_desc, business_unit_desc, datepart(dd, delta_date), datepart(mm, delta_date), datepart(yy, delta_date)  
UNION
SELECT 'Management', datepart(dd, delta_date) as delta_day, datepart(mm, delta_date) as delta_month, datepart(yy, delta_date) as delta_year, campaign_no, revenue_period, sum (revenue), branch.branch_name, revision_group_desc, business_unit_desc
FROM v_mgtrev, branch
WHERE campaign_no in (  SELECT distinct campaign_no
                        FROM v_statrev
                        WHERE revenue_period >= '2011-01-01'
                        UNION all
                        SELECT distinct campaign_no
                        FROM v_mgtrev
                        WHERE revenue_period >= '2011-01-01')
and v_mgtrev.branch_code = branch.branch_code
GROUP by campaign_no, revenue_period, branch.branch_name, business_unit_desc, revision_group_desc, datepart(dd, delta_date), datepart(mm, delta_date), datepart(yy, delta_date)
GO
