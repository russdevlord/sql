/****** Object:  StoredProcedure [dbo].[p_projected_billing_data_gen_hoyts]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_projected_billing_data_gen_hoyts]
GO
/****** Object:  StoredProcedure [dbo].[p_projected_billing_data_gen_hoyts]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
/*
 * p_projected_billing_data_gen_hoyts
 * --------------------------
 * This procedure updates the selected month colunm in projected_billings
 *
 * Created/Modified
 * GC, 2/4/2003, Created.
 * GC, 6/5/2003, modified to data-warehouse type function
 */

CREATE PROC [dbo].[p_projected_billing_data_gen_hoyts]    @report_date	        datetime,
                                            @business_unit_id       int,
                                            @media_product_id       int,
                                            @agency_deal            char(1),
                                            @branch_code            char(2),
                                            @finyear_end            datetime
--with recompile
as

/*
 * Declare Variables
 */

declare     @error_num                  int,
            @row_count                  int,
            @error                         int,
            @total_amt                  money,
            @temp_month                 tinyint,
            @month_num                  tinyint,
            @m1_amt                     money,
            @m2_amt                     money,
            @m3_amt                     money,
            @m4_amt                     money,
            @m5_amt                     money,
            @m6_amt                     money,
            @m7_amt                     money,
            @m8_amt                     money,
            @m9_amt                     money,
            @m10_amt                    money,
            @m11_amt                    money,
            @m12_amt                    money,
            @future_amt                 money,
            @prev_report_date           datetime,
            @country_code               char(1),
            @billing_period             datetime,
            @period_no                  int



    
select @country_code = country_code from branch where branch_code = @branch_code
/* get projected billing amount for period and branch */


select  @m1_amt   = 0,
        @m2_amt   = 0,
        @m3_amt   = 0,
        @m4_amt   = 0,
        @m5_amt   = 0,
        @m6_amt   = 0,
        @m7_amt   = 0,
        @m8_amt   = 0,
        @m9_amt   = 0,
        @m10_amt  = 0,
        @m11_amt  = 0,
        @m12_amt  = 0,
        @future_amt = 0

begin transaction

declare     acct_period_cur cursor static for
select      benchmark_end, period_no
from        accounting_period_hoyts
where       finyear_end = @finyear_end
order by    benchmark_end
for         read only

open acct_period_cur
fetch acct_period_cur into @billing_period, @period_no
while(@@fetch_status=0)
begin
    exec @error = p_projected_bill_calc_period @billing_period,@branch_code,@business_unit_id,@media_product_id,@agency_deal,@total_amt OUTPUT

    if @error = -1
    begin
        return -1
        deallocate acct_period_cur
    end 

    if @period_no = 7   select @m1_amt = @total_amt
    if @period_no = 8   select @m2_amt = @total_amt
    if @period_no = 9   select @m3_amt = @total_amt
    if @period_no = 10  select @m4_amt = @total_amt
    if @period_no = 11  select @m5_amt = @total_amt
    if @period_no = 12  select @m6_amt = @total_amt
    if @period_no = 1   select @m7_amt = @total_amt
    if @period_no = 2   select @m8_amt = @total_amt
    if @period_no = 3   select @m9_amt = @total_amt
    if @period_no = 4   select @m10_amt = @total_amt
    if @period_no = 5   select @m11_amt = @total_amt
    if @period_no = 6   select @m12_amt = @total_amt

    fetch acct_period_cur into @billing_period, @period_no
end     

deallocate acct_period_cur

    /* attempt to update existing row, if no row exists copy prev day and update */
    if exists (select 1 from projected_billings_hoyts
                where   report_date = @report_date
                and     business_unit_id = @business_unit_id
                and     media_product_id = @media_product_id
                and     agency_deal = @agency_deal
                and     branch_code = @branch_code
                and     finyear_end = @finyear_end)
    begin
        /* update appropriate month */

        update  projected_billings_hoyts
        set     billings_month_01 = @m1_amt,
                billings_month_02 = @m2_amt,
                billings_month_03 = @m3_amt,
                billings_month_04 = @m4_amt,
                billings_month_05 = @m5_amt,
                billings_month_06 = @m6_amt,
                billings_month_07 = @m7_amt,
                billings_month_08 = @m8_amt,
                billings_month_09 = @m9_amt,
                billings_month_10 = @m10_amt,
                billings_month_11 = @m11_amt,
                billings_month_12 = @m12_amt
        where   report_date = @report_date
        and     business_unit_id = @business_unit_id
        and     media_product_id = @media_product_id
        and     agency_deal = @agency_deal
        and     branch_code = @branch_code
        and     finyear_end = @finyear_end
        if @@error <> 0
        begin
            rollback transaction
            return -1
        end
    end /*update*/
    else
    begin
        /* copy new record from prev day, and update selected billing month */
        select  @prev_report_date = max(report_date)
        from    projected_billings_hoyts
        where   report_date < @report_date
        and     business_unit_id = @business_unit_id
        and     media_product_id = @media_product_id
        and     branch_code = @branch_code
        and     finyear_end = @finyear_end
        and     agency_deal = @agency_deal
        
    
        insert  projected_billings_hoyts(
                     report_date       ,
                     business_unit_id,
                     media_product_id,
                     agency_deal,
                     branch_code       ,
                     finyear_end       ,
                     billings_month_01  ,
                     billings_month_02  ,
                     billings_month_03  ,
                     billings_month_04  ,
                     billings_month_05  ,
                     billings_month_06  ,
                     billings_month_07  ,
                     billings_month_08  ,
                     billings_month_09  ,
                     billings_month_10 ,
                     billings_month_11 ,
                     billings_month_12 ,
                     billings_future)
             values    (@report_date,
                        @business_unit_id,
                        @media_product_id,
                        @agency_deal,
                        @branch_code,
                        @finyear_end,
                        @m1_amt   ,
                        @m2_amt   ,
                        @m3_amt   ,
                        @m4_amt   ,
                        @m5_amt   ,
                        @m6_amt   ,
                        @m7_amt   ,
                        @m8_amt   ,
                        @m9_amt   ,
                        @m10_amt  ,
                        @m11_amt  ,
                        @m12_amt  ,
                        0)
        if @@error <> 0
        begin
            rollback transaction
            return -1
        end
    end /* insert */

commit transaction

return
GO
