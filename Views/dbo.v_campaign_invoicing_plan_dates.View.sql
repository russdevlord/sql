/****** Object:  View [dbo].[v_campaign_invoicing_plan_dates]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_campaign_invoicing_plan_dates]
GO
/****** Object:  View [dbo].[v_campaign_invoicing_plan_dates]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




create view [dbo].[v_campaign_invoicing_plan_dates]

as
select			temp_table.campaign_no,
				temp_table.business_unit_id,
				temp_table.start_date,
				temp_table.end_date,
				temp_table.campaign_screening_start,
				temp_table.campaign_screening_end,
				temp_table.tran_start_date,
				temp_table.tran_end_date,
				temp_table.start_period,
				temp_table.end_period,
				temp_table.screen_start_period,
				temp_table.screen_end_period,
				temp_table.tran_start_period,
				temp_table.tran_end_period,
				isnull(temp_table.inv_plan_start_date, dateadd(dd, 1, temp_table.start_date)) as inv_plan_start_date,
				isnull(temp_table.inv_plan_start_period, dateadd(dd, 1, temp_table.start_period)) as inv_plan_start_period,
				isnull(temp_table.inv_plan_end_date, dateadd(dd, -1, temp_table.end_date)) as inv_plan_end_date,
				isnull(temp_table.inv_plan_end_period, dateadd(dd, -1, temp_table.end_period)) as inv_plan_end_period,
				isnull(temp_table.first_inv_plan_spot, dateadd(dd, -1, temp_table.start_date)) as first_inv_plan_spot,
				isnull(temp_table.last_inv_plan_spot, dateadd(dd, -1, temp_table.end_date)) as last_inv_plan_spot
from			(select		fc.campaign_no,
							fc.business_unit_id,
							(select min(tran_date) from campaign_transaction where campaign_no = fc.campaign_no) as tran_start_date,
							fc.start_date as start_date,
							(select min(screening_date) from v_all_cinema_spots where campaign_no = fc.campaign_no) as campaign_screening_start,

							(select min(end_date) from accounting_period where end_date >= (select min(tran_date) from campaign_transaction where campaign_no = fc.campaign_no)) as tran_start_period,
							(select min(end_date) from accounting_period where end_date >= (select start_date from film_campaign where campaign_no = fc.campaign_no)) as start_period,
							(select min(billing_period) from v_all_cinema_spots where campaign_no = fc.campaign_no) as screen_start_period,


							(select max(tran_date) from campaign_transaction where campaign_no = fc.campaign_no) as tran_end_date, 
							fc.end_date as end_date,
							(select max(screening_date) from v_all_cinema_spots where campaign_no = fc.campaign_no) as campaign_screening_end,

							(select min(end_date) from accounting_period where end_date >= (select max(tran_date) from campaign_transaction where campaign_no = fc.campaign_no)) as tran_end_period,
							(select min(end_date) from accounting_period where end_date >= (select end_date from film_campaign where campaign_no = fc.campaign_no)) as end_period,
							(select max(billing_period) from v_all_cinema_spots where campaign_no = fc.campaign_no) as screen_end_period,

							inc_temp.start_date as inv_plan_start_date,
							(select min(end_date) from accounting_period where end_date >= inc_temp.start_date) as inv_plan_start_period,
							inc_temp.used_by_date as inv_plan_end_date,
							(select min(end_date) from accounting_period where end_date >= inc_temp.used_by_date) as inv_plan_end_period,
							inc_temp.first_inv_plan_spot,
							inc_temp.last_inv_plan_spot
				from		film_campaign fc
				left join	(select				inc.campaign_no,
												inc.inclusion_id,
												start_date,
												used_by_date,
												(select min(billing_period) from inclusion_spot where inclusion_id = inc.inclusion_id) as first_inv_plan_spot,
												(select max(billing_period) from inclusion_spot where inclusion_id = inc.inclusion_id) as last_inv_plan_spot
							from				inclusion inc
							inner join			film_campaign_standalone_invoice fcsi on inc.inclusion_id = fcsi.inclusion_id
							where				inc.inclusion_type = 28) inc_temp on  fc.campaign_no = inc_temp.campaign_no) as temp_table
GO
