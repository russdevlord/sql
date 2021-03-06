/****** Object:  StoredProcedure [dbo].[p_projected_bill_calc_period]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_projected_bill_calc_period]
GO
/****** Object:  StoredProcedure [dbo].[p_projected_bill_calc_period]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
/*
 * p_projected_bill_calc_period
 * --------------------------
 * This procedure generated data for the Projected Billing report for accounting
 *
 * Args:    1. Billing period (Acct cut off date)
 *		    2. Branch code
 *			3. Product Type - 1=campaign_format=Standard, 2=campaign_format=Designer
 *
 * Created/Modified
 * GC, 13/4/2002, Created.
 */

CREATE PROC [dbo].[p_projected_bill_calc_period]    @billing_period	            datetime,
                                            @branch_code                char(1),
                                            @business_unit_id           int,
                                            @media_product_id           int,
                                            @agency_deal                char(1),
                                            @billing_amount             money OUTPUT
                                            
--with recompile      
                                      
as

/*
 * Declare Variables
 */

declare     @error_num               int,
            @row_count               int,
            @cut_off_date            datetime,
            @leading_bill_date       datetime,
            @leading_bill_amt        money,
            @leading_bill_portion    int,
            @trailing_bill_date      datetime,
            @trailing_bill_amt       money,
            @trailing_bill_portion   int,
            @prev_bill_date          datetime,
            @prev_bill_amt           money,
            @intra_bill_amt          money,
            @total_amt               money


select      @intra_bill_amt = 0

select  @intra_bill_amt   = isnull(sum(amount),0)
from    #intra
where   branch_code = @branch_code
and     business_unit_id = @business_unit_id
and     agency_deal = @agency_deal
and     media_product_id = @media_product_id
and     benchmark_end = @billing_period

select      @billing_amount = isnull(@intra_bill_amt,0)

return 0
GO
