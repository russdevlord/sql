USE [production]
GO
/****** Object:  View [dbo].[v_sales_rep_revenue_budgets]    Script Date: 11/03/2021 2:30:32 PM ******/
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
