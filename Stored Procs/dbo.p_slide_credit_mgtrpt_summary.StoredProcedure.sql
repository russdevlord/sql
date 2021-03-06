/****** Object:  StoredProcedure [dbo].[p_slide_credit_mgtrpt_summary]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_slide_credit_mgtrpt_summary]
GO
/****** Object:  StoredProcedure [dbo].[p_slide_credit_mgtrpt_summary]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_slide_credit_mgtrpt_summary] @branch_code	char(2)
as
set nocount on 
/*
 * Declare Variables
 */

declare @branch_name					varchar(50),
        @curr_date					datetime,
        @fin_year						datetime,
        @fin_year_start				datetime,
        @fin_year_desc				varchar(30),
        @acc_start					datetime,
        @acc_end						datetime,
        @mtd_bad_debts				money,
        @ytd_bad_debts				money,
        @mtd_billing_credits		money,
        @ytd_billing_credits		money,
        @mtd_suspension_credits	money,
        @ytd_suspension_credits	money,
        @suspensions					money,
        @atb_total					money,
        @gst_rate						numeric(6,4),
        @days_in_year				integer,
        @days_to_date				integer

/*
 * Set Current Date
 */

select @curr_date = getdate()

/*
 * Get GST Rate
 */

select @gst_rate = c.gst_rate,
       @branch_name = b.branch_name
  from branch b,
       country c
 where b.country_code = c.country_code and
       b.branch_code = @branch_code

/*
 * Get Current Accounting Period and Financial Year
 */

select @acc_end = min(end_date)
  from accounting_period
 where status = 'O'

select @acc_start = ac.start_date,
       @fin_year = fin.finyear_end,
       @fin_year_start = fin.finyear_start,
       @fin_year_desc = fin.finyear_desc
  from accounting_period ac,
       financial_year fin
 where ac.finyear_end = fin.finyear_end and
       ac.end_date = @acc_end

if(@curr_date > @acc_end)
	select @curr_date = @acc_end

/*
 * Calculate Days
 */

select @days_in_year = datediff(dd, @fin_year_start, @fin_year)
select @days_to_date = datediff(dd, @fin_year_start, @curr_date)

/*
 * Select Outstanding Balance
 */

select @atb_total = isnull(sum(sc.balance_outstanding),0)
  from slide_campaign sc
 where branch_code = @branch_code and
       is_closed = 'N' and
       sc.balance_outstanding <> 0

/*
 * Select Month to Date Bad Debts
 */

select @mtd_bad_debts = isnull(sum(st.gross_amount),0)
  from slide_campaign sc,
       slide_transaction st
 where sc.branch_code = @branch_code and
       sc.campaign_no = st.campaign_no and
       st.tran_type = 54 and --Bad Debt
       st.accounting_period is null

/*
 * Select Year to Date Bad Debts
 */

select @ytd_bad_debts = isnull(sum(st.gross_amount),0)
  from slide_campaign sc,
       slide_transaction st,
       accounting_period ap
 where sc.branch_code = @branch_code and
       sc.campaign_no = st.campaign_no and
       st.tran_type = 54 and --Bad Debt
       st.accounting_period = ap.end_date and
       ap.finyear_end = @fin_year

/*
 * Select Month to Date Billing Credits
 */

select @mtd_billing_credits = isnull(sum(st.gross_amount),0)
  from slide_campaign sc,
       slide_transaction st
 where sc.branch_code = @branch_code and
       sc.campaign_no = st.campaign_no and
       st.tran_type = 69 and --Billing Credit
       st.accounting_period is null

/*
 * Select Year to Date Billing Credits
 */

select @ytd_billing_credits = isnull(sum(st.gross_amount),0)
  from slide_campaign sc,
       slide_transaction st,
       accounting_period ap
 where sc.branch_code = @branch_code and
       sc.campaign_no = st.campaign_no and
       st.tran_type = 69 and --Billing Credit
       st.accounting_period = ap.end_date and
       ap.finyear_end = @fin_year

/*
 * Select Month to Date Suspension Credits
 */

select @mtd_suspension_credits = isnull(sum(st.gross_amount),0)
  from slide_campaign sc,
       slide_transaction st
 where sc.branch_code = @branch_code and
       sc.campaign_no = st.campaign_no and
       st.tran_type = 71 and --Suspension Credit
       st.accounting_period is null

/*
 * Select Year to Date Suspension Credits
 */

select @ytd_suspension_credits = isnull(sum(st.gross_amount),0)
  from slide_campaign sc,
       slide_transaction st,
       accounting_period ap
 where sc.branch_code = @branch_code and
       sc.campaign_no = st.campaign_no and
       st.tran_type = 71 and --Suspension Credit
       st.accounting_period = ap.end_date and
       ap.finyear_end = @fin_year

/*
 * Select Suspensions for the Month
 */

select @suspensions = isnull(sum(spot.nett_rate),0)
  from slide_campaign sc,
       slide_campaign_spot spot
 where sc.branch_code = @branch_code and
       sc.campaign_no = spot.campaign_no and
       spot.spot_status = 'S' and --Suspended
     ( spot.billing_status = 'S' or --Suspended 
       spot.billing_status = 'X' ) and --Cancelled
       spot.screening_date >= @acc_start and
       spot.screening_date <= @acc_end

/*
 * Return Dataset
 */

select @branch_name as branch_name,
       @curr_date as curr_date,
       @fin_year_desc as finyear_desc,
       @acc_end as accounting_period,
       @mtd_bad_debts * -1 as mtd_bad_debts,
       @ytd_bad_debts * -1 as ytd_bad_debts,
       @mtd_billing_credits * -1 as mtd_billing_credits,
       @ytd_billing_credits * -1 as ytd_billing_credits,
       @mtd_suspension_credits * -1 as mtd_suspension_credits,
       @ytd_suspension_credits * -1 as ytd_suspension_credits,
       @suspensions as suspensions,
       @atb_total as atb_total,
       @gst_rate as gst_rate,
       @days_in_year as days_in_year,
       @days_to_date as days_to_date

/*
 * Return
 */

return 0
GO
