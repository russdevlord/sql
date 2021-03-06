/****** Object:  StoredProcedure [dbo].[p_slide_campaign_arc_list]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_slide_campaign_arc_list]
GO
/****** Object:  StoredProcedure [dbo].[p_slide_campaign_arc_list]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_slide_campaign_arc_list]

as
set nocount on 
/*
 * Declare variables
 */

declare 	@error					integer,
			@accounting_period	datetime

/*
 * Get finyear start for previous year 
 */

select @accounting_period = max(finyear_start)
  from financial_year
 where finyear_end < dateadd(yy, -1, getdate())

/*
 * Select slide campaign info where makeup deadline is less than the date obtained above
 */

select sc.campaign_no,   
       sc.name_on_slide,   
       sc.branch_code,   
       sc.contract_rep,   
       sc.campaign_status,   
       sc.campaign_type,   
       sc.campaign_category,   
       sc.start_date, 
		 sc.min_campaign_period,
		 sc.bonus_period	 
  from slide_campaign sc
 where sc.campaign_status in ('X', 'C', 'Z') and
       dateadd(wk, sc.min_campaign_period + sc.bonus_period, sc.start_date) < @accounting_period 

return 0
GO
