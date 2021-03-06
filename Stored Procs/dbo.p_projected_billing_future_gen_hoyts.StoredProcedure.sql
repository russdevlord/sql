/****** Object:  StoredProcedure [dbo].[p_projected_billing_future_gen_hoyts]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_projected_billing_future_gen_hoyts]
GO
/****** Object:  StoredProcedure [dbo].[p_projected_billing_future_gen_hoyts]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
/*
 * p_projected_billing_future_gen_hoyts
 * --------------------------
 * This procedure generates data for the Projected Billing report for accounting,
 * for all future billings after cutoff date.
 *
 * Args:    1. Billing period (Acct cut off date)
 *		    3. Branch code
 *			4. Product Type (ie: Film, Slide)
 *
 * Created/Modified
 * GC, 13/4/2002, Created.
 * GC, 6/5/2003, modified to data-warehouse type function
 */

CREATE PROC [dbo].[p_projected_billing_future_gen_hoyts]  @report_date	        datetime,
                                            @business_unit_id       int,
                                            @media_product_id       int,
                                            @agency_deal            char(1),
                                            @branch_code            char(2),
                                            @finyear_end            datetime,
                                            @billing_period         datetime
--with recompile                                            
as

/*
 * Declare Variables
 */

declare     @error                 int,
            @total_amt          money,
            @country_code       char(1)

select @country_code = country_code from branch where branch_code = @branch_code

exec @error = p_projected_bill_calc_future   @report_date,@business_unit_id,@media_product_id,@agency_deal,@branch_code,@finyear_end,@billing_period,@total_amt OUTPUT
if @error = -1
    return -1

begin tran

        update  projected_billings_hoyts
        set     billings_future = @total_amt
        where   report_date = @report_date
        and     branch_code = @branch_code
        and     finyear_end = @finyear_end
        and     business_unit_id = @business_unit_id
        and     media_product_id = @media_product_id
        and     agency_deal = @agency_deal
        
        if @@error <> 0
        begin
            rollback transaction
            return -1
        end

commit tran

return 0
GO
