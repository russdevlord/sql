/****** Object:  View [dbo].[v_campaign_invoicing_periods]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_campaign_invoicing_periods]
GO
/****** Object:  View [dbo].[v_campaign_invoicing_periods]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


create view [dbo].[v_campaign_invoicing_periods]

as
select			temp_table.campaign_no,
				temp_table.start_date,
				temp_table.start_period,
				temp_table.end_date,
				temp_table.end_period,
				isnull(temp_table.inv_plan_start_date, dateadd(dd, 1, temp_table.end_date)) as inv_plan_start_date,
				isnull(temp_table.inv_plan_start_period, dateadd(dd, 1, temp_table.end_period)) as inv_plan_start_period,
				isnull(temp_table.inv_plan_end_date, dateadd(dd, -1, temp_table.start_date)) as inv_plan_end_date,
				isnull(temp_table.inv_plan_end_period, dateadd(dd, -1, temp_table.start_period)) as inv_plan_end_period
from			(select		fc.campaign_no,
							(select min(tran_date) from campaign_transaction where campaign_no = fc.campaign_no) as start_date,
							--fc.start_date,
							(select min(end_date) from accounting_period where end_date >= (select min(tran_date) from campaign_transaction where campaign_no = fc.campaign_no)) as start_period,
							(select max(tran_date) from campaign_transaction where campaign_no = fc.campaign_no) as end_date, 
							--fc.end_date,
							(select min(end_date) from accounting_period where end_date >= (select max(tran_date) from campaign_transaction where campaign_no = fc.campaign_no)) as end_period,
							inc_temp.start_date as inv_plan_start_date,
							(select min(end_date) from accounting_period where end_date >= inc_temp.start_date) as inv_plan_start_period,
							inc_temp.used_by_date as inv_plan_end_date,
							(select min(end_date) from accounting_period where end_date >= inc_temp.used_by_date) as inv_plan_end_period
				from		film_campaign fc
				left join	(select				inc.campaign_no,
												inc.inclusion_id,
												start_date,
												used_by_date
							from				inclusion inc
							inner join			film_campaign_standalone_invoice fcsi on inc.inclusion_id = fcsi.inclusion_id
							where				inc.inclusion_type = 28) inc_temp on  fc.campaign_no = inc_temp.campaign_no) as temp_table
GO
