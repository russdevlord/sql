USE [production]
GO
/****** Object:  View [dbo].[v_accounting_period_wth_qtr]    Script Date: 11/03/2021 2:30:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

Create View [dbo].[v_accounting_period_wth_qtr] AS

select
   [end_date]
	,[start_date]
	,[status]
	,[film_billing_proc]
	,[film_statement_proc]
	,[film_alloc_proc]
	,[film_closure_proc]
	,[slide_alloc_proc]
	,[slide_rent_proc]
	,[slide_closure_proc]
	,[finyear_end]
	,[calendar_end]
	,[benchmark_start]
	,[benchmark_end]
	,[period_no]
	,[timestamp]
  ,case when period_no in (1, 2, 3) then 'Q1'
        when period_no in (4, 5, 6) then 'Q2'
        when period_no in (7, 8, 9) then 'Q3'
        when period_no in (10, 11, 12) then 'Q4'
        end as 'quarter'
from accounting_period
GO
