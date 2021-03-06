/****** Object:  StoredProcedure [dbo].[p_dw_proj_bill_gen_all]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_dw_proj_bill_gen_all]
GO
/****** Object:  StoredProcedure [dbo].[p_dw_proj_bill_gen_all]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
/*
 * p_dw_proj_bill_gen_all
 * --------------------------
 * This procedure calls p_projected_billing_data_gen for all branches and forecast dates
 *
 * Args:    1. Billing period (Acct cut off date)
 *		    3. Country code
 *			4. Product Type (ie: Film, Slide)
 *
 * Created/Modified
 * GC, 14/4/2002, Created.
 */

CREATE PROC [dbo].[p_dw_proj_bill_gen_all] @billing_period	datetime,
                                   @country_code char(1),
                                   @product_type tinyint,
                                   @report_date  datetime
as

/* Declare Variables */
declare     @error_num              int,
            @error                     int,
            @cur_billing_period     datetime,
            @cur_branch_code        char(1),
            @finyear_end            datetime

declare acct_period_cur cursor static for
select  end_date
from    accounting_period
where   end_date >= @billing_period
and     finyear_end = @finyear_end
order by end_date
for read only


select  @finyear_end = finyear_end from accounting_period where end_date = @billing_period

open acct_period_cur
fetch acct_period_cur into @cur_billing_period
while @@fetch_status = 0
begin
	declare branch_cur cursor static for
	select  branch_code
	from    branch
	where   country_code = @country_code
	for read only

    open branch_cur
    fetch branch_cur into @cur_branch_code
    while @@fetch_status = 0
    begin
        exec @error = p_dw_proj_bill_gen @report_date, @product_type, @cur_branch_code, @finyear_end, @cur_billing_period
        fetch branch_cur into @cur_branch_code
    end /* branch_cur */
    close branch_cur
	deallocate branch_csr
    fetch acct_period_cur into @cur_billing_period
end /* acct_period_cur */
close acct_period_cur
deallocate acct_period_cur

declare branch_cur cursor static for
select  branch_code
from    branch
where   country_code = @country_code
for read only

/* generate future billings amounts, presume that we can use last value of @cur_billing_period */
open branch_cur
fetch branch_cur into @cur_branch_code
while @@fetch_status = 0
begin
     exec @error = p_dw_proj_bill_future_gen @report_date, @product_type, @cur_branch_code, @finyear_end, @cur_billing_period
     fetch branch_cur into @cur_branch_code
end /* branch_cur */
close branch_cur
deallocate branch_cur
GO
