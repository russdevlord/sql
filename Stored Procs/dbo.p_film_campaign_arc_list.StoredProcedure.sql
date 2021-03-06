/****** Object:  StoredProcedure [dbo].[p_film_campaign_arc_list]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_film_campaign_arc_list]
GO
/****** Object:  StoredProcedure [dbo].[p_film_campaign_arc_list]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_film_campaign_arc_list]

as

/*
 * Declare variables
 */

declare 	@error			integer,
		@accounting_period	datetime

/*
 * Get finyear start for previous year 
 */

select @accounting_period = max(finyear_end)
  from financial_year
 where finyear_end < dateadd(yy, -2, getdate())

/*
 * Select film campaign info where makeup deadline is less than the date obtained above
 */

select 		fc.campaign_no,   
	       	fc.product_desc,   
	       	fc.revision_no,   
	       	fc.branch_code,   
	       	fc.rep_id,   
	       	fc.campaign_status,   
	       	fc.campaign_type,   
	       	fc.campaign_category,   
	       	fc.campaign_expiry_idc,   
	       	fc.closed_date,   
	       	fc.makeup_deadline,
	  	   	fy.finyear_end		 
  from 		film_campaign fc,
   	 		financial_year fy
 where 		campaign_status = 'X'
and 		makeup_deadline <= @accounting_period
and 		campaign_no not in (select distinct campaign_no from delete_charge_spots)
and			fc.closed_date < dateadd(mm, -3, getdate())
and			fc.makeup_deadline between fy.finyear_start and fy.finyear_end
group by 	fc.campaign_no,
	       	fc.product_desc,   
	       	fc.revision_no,   
	       	fc.branch_code,   
	       	fc.rep_id,   
	       	fc.campaign_status,   
	       	fc.campaign_type,   
	       	fc.campaign_category,   
	       	fc.campaign_expiry_idc,   
	       	fc.closed_date,   
	       	fc.makeup_deadline,
	  	   	fy.finyear_end	
having 		((select max(billing_date) from campaign_spot where campaign_no = fc.campaign_no) <= @accounting_period) 

return 0
GO
