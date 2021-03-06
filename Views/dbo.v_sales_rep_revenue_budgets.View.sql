/****** Object:  View [dbo].[v_sales_rep_revenue_budgets]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP VIEW [dbo].[v_sales_rep_revenue_budgets]
GO
/****** Object:  View [dbo].[v_sales_rep_revenue_budgets]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create view [dbo].[v_sales_rep_revenue_budgets]
as
select	first_name, last_name, business_unit_desc, revenue_group_desc, revenue_period, budget
from	sales_rep,
		business_unit,
		statrev_revenue_group,
		statrev_budgets_rep
where	statrev_revenue_group.revenue_group = statrev_budgets_rep.revenue_group
and		statrev_budgets_rep.rep_id = sales_rep.rep_id
and		statrev_budgets_rep.business_unit_id = business_unit.business_unit_id
GO
