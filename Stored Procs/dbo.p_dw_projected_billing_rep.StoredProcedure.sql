/****** Object:  StoredProcedure [dbo].[p_dw_projected_billing_rep]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_dw_projected_billing_rep]
GO
/****** Object:  StoredProcedure [dbo].[p_dw_projected_billing_rep]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create PROC [dbo].[p_dw_projected_billing_rep]   @report_date	datetime,
                                         @prev_report_date datetime,
                                         @finyear   datetime,
                                         @country_code	char(1),
                                         @product_type  tinyint
with recompile as

/*
 * Declare Valiables
 */

declare @error							integer,
        @sqlstatus					integer,
        @errorode							integer,
        @branch_code					char(2),
        @account_period				datetime,
        @prev_bill                  money,
        @future_dummy_period        datetime,
        @manual_bill                money,
        @budget_bill                money,
        @nett_billings				money,
        @period_csr_open			tinyint,
        @branch_csr_open			tinyint,
        @update_date_ftr            datetime

/*
 * Create Temporary Table
 */

create table #results
(
	country_code			char(1)			null,
	branch_code				char(2)			null,
	period_1				datetime		null,
	bill_1					money			null,
    prev_bill_1             money           null,
    prev_date_1             datetime        null,
    manual_bill_1           money           null,
    budget_bill_1           money           null,
	period_2				datetime		null,
	bill_2					money			null,
    prev_bill_2             money           null,
    prev_date_2             datetime        null,
    manual_bill_2           money           null,
    budget_bill_2           money           null,
	period_3				datetime		null,
	bill_3					money			null,
    prev_bill_3             money           null,
    prev_date_3             datetime        null,
    manual_bill_3           money           null,
    budget_bill_3           money           null,
	period_4				datetime		null,
	bill_4					money			null,
    prev_bill_4             money           null,
    prev_date_4             datetime        null,
    manual_bill_4           money           null,
    budget_bill_4           money           null,
	period_5				datetime		null,
	bill_5					money			null,
    prev_bill_5             money           null,
    prev_date_5             datetime        null,
    manual_bill_5           money           null,
    budget_bill_5           money           null,
	period_6				datetime		null,
	bill_6					money			null,
    prev_bill_6             money           null,
    prev_date_6             datetime        null,
    manual_bill_6           money           null,
    budget_bill_6           money           null,
	period_7				datetime		null,
	bill_7					money			null,
    prev_bill_7             money           null,
    prev_date_7             datetime        null,
    manual_bill_7           money           null,
    budget_bill_7           money           null,
	period_8				datetime		null,
	bill_8					money			null,
    prev_bill_8             money           null,
    prev_date_8             datetime        null,
    manual_bill_8           money           null,
    budget_bill_8           money           null,
	period_9				datetime		null,
	bill_9					money			null,
    prev_bill_9             money           null,
    prev_date_9             datetime        null,
    manual_bill_9           money           null,
    budget_bill_9           money           null,
	period_10				datetime		null,
	bill_10					money			null,
    prev_bill_10             money           null,
    prev_date_10             datetime        null,
    manual_bill_10           money           null,
    budget_bill_10           money           null,
	period_11				datetime		null,
	bill_11					money			null,
    prev_bill_11             money           null,
    prev_date_11             datetime        null,
    manual_bill_11         money           null,
    budget_bill_11         money           null,
	period_12				datetime		null,
	bill_12					money			null,
    prev_bill_12           money           null,
    prev_date_12           datetime        null,
    manual_bill_12         money           null,
    budget_bill_12         money           null,
   	period_ftr				datetime		null,
	bill_ftr				money			null,
    prev_bill_ftr           money           null,
    prev_date_ftr           datetime        null,
    manual_bill_ftr         money           null,
    budget_bill_ftr         money           null,
    update_date_ftr         datetime        null,
    financial_year          datetime        null
)

/*
 * Declare Cursors
 */



/*
 * Initialise Variables
 */

/* use a fake furture billing period to make creating report easy, matches generation routine code */
select @future_dummy_period = '1 jan 2050'

select @branch_csr_open = 0,
       @period_csr_open = 0

/* PB client does not check for valid prev report date - change to valid date if it is not */
if not exists (select 1 from dw_projected_billings where report_date = @prev_report_date)
	select @prev_report_date = max(report_date) from dw_projected_billings

/*
 * Loop Branches
 */

 declare branch_csr cursor static for
  select country_code,
         branch_code
    from branch
   where country_code = @country_code
order by country_code ASC,
         branch_code ASC
     for read only

open branch_csr
select @branch_csr_open = 1
fetch branch_csr into @country_code, @branch_code
while (@@fetch_status = 0)
begin

	/*
    * Insert Branch
    */

	insert into #results (country_code, branch_code ) values (@country_code, @branch_code)
	select @error = @@error
	if (@error !=0)
		goto error

	/*
  	 * Open Period Cursor
	 */

	 declare period_csr cursor static for
	  select end_date
	    from accounting_period
	   where finyear_end = @finyear
	order by end_date ASC
	     for read only

	open period_csr
	select @period_csr_open = 1

	/*
    * Calculate Results 1
    */

	fetch period_csr into @account_period
	if(@@fetch_status = 0)
	begin
        select  @nett_billings = 0, @prev_bill = 0
    	select  @nett_billings   = isnull(billings_month_01,0)
        from    dw_projected_billings
        where   report_date = @report_date
        and     branch_code = @branch_code
        and     product_type = @product_type
        and     finyear_end = @finyear

    	select  @prev_bill   = isnull(billings_month_01,0)
        from    dw_projected_billings
        where   report_date = @prev_report_date
        and     branch_code = @branch_code
        and     product_type = @product_type
        and     finyear_end = @finyear

        select  @manual_bill = 0, @budget_bill = 0
        select  @manual_bill = film_manual_billings_total,
                @budget_bill = film_billings_budget
        from    monthly_billings
        where   billing_period = @account_period
        and     country_code = @country_code

		update  #results
        set     period_1 = @account_period,
                bill_1 = @nett_billings,
                prev_bill_1 = @prev_bill,
                prev_date_1 = @prev_report_date,
                manual_bill_1 = @manual_bill,
                budget_bill_1 = @budget_bill
        where   branch_code = @branch_code
		if (@@error !=0)
			goto error
    end /*fetch*/

	/*
    * Calculate Results 2
    */
	fetch period_csr into @account_period
	if(@@fetch_status = 0)
	begin
        select  @nett_billings = 0, @prev_bill = 0
    	select  @nett_billings   = isnull(billings_month_02,0)
        from    dw_projected_billings
        where   report_date = @report_date
        and     branch_code = @branch_code
        and     product_type = @product_type
        and     finyear_end = @finyear

    	select  @prev_bill   = isnull(billings_month_02,0)
        from    dw_projected_billings
        where   report_date = @prev_report_date
        and     branch_code = @branch_code
        and     product_type = @product_type
        and     finyear_end = @finyear

        select  @manual_bill = 0, @budget_bill = 0
        select  @manual_bill = film_manual_billings_total,
                @budget_bill = film_billings_budget
        from    monthly_billings
        where   billing_period = @account_period
        and     country_code = @country_code

		update  #results
        set     period_2 = @account_period,
                bill_2 = @nett_billings,
                prev_bill_2 = @prev_bill,
                prev_date_2 = @prev_report_date,
                manual_bill_2 = @manual_bill,
                budget_bill_2 = @budget_bill
        where   branch_code = @branch_code
		if (@@error !=0)
			goto error
    end /*fetch*/

	/*
    * Calculate Results 3
    */
	fetch period_csr into @account_period
	if(@@fetch_status = 0)
	begin
        select  @nett_billings = 0, @prev_bill = 0
    	select  @nett_billings   = isnull(billings_month_03,0)
        from    dw_projected_billings
        where   report_date = @report_date
        and     branch_code = @branch_code
        and     product_type = @product_type
        and     finyear_end = @finyear

    	select  @prev_bill   = isnull(billings_month_03,0)
        from    dw_projected_billings
        where   report_date = @prev_report_date
        and     branch_code = @branch_code
        and     product_type = @product_type
        and     finyear_end = @finyear

        select  @manual_bill = 0, @budget_bill = 0
        select  @manual_bill = film_manual_billings_total,
                @budget_bill = film_billings_budget
        from    monthly_billings
        where   billing_period = @account_period
        and     country_code = @country_code

		update  #results
        set     period_3 = @account_period,
                bill_3 = @nett_billings,
                prev_bill_3 = @prev_bill,
                prev_date_3 = @prev_report_date,
                manual_bill_3 = @manual_bill,
                budget_bill_3 = @budget_bill
        where   branch_code = @branch_code
		if (@@error !=0)
			goto error
    end /*fetch*/

	/*
    * Calculate Results 4
    */
	fetch period_csr into @account_period
	if(@@fetch_status = 0)
	begin
        select  @nett_billings = 0, @prev_bill = 0
    	select  @nett_billings   = isnull(billings_month_04,0)
        from    dw_projected_billings
        where   report_date = @report_date
        and     branch_code = @branch_code
        and     product_type = @product_type
        and     finyear_end = @finyear

    	select  @prev_bill   = isnull(billings_month_04,0)
        from    dw_projected_billings
        where   report_date = @prev_report_date
        and     branch_code = @branch_code
        and     product_type = @product_type
        and     finyear_end = @finyear

        select  @manual_bill = 0, @budget_bill = 0
        select  @manual_bill = film_manual_billings_total,
                @budget_bill = film_billings_budget
        from    monthly_billings
        where   billing_period = @account_period
        and     country_code = @country_code

		update  #results
        set     period_4 = @account_period,
                bill_4 = @nett_billings,
                prev_bill_4 = @prev_bill,
                prev_date_4 = @prev_report_date,
                manual_bill_4 = @manual_bill,
                budget_bill_4 = @budget_bill
        where   branch_code = @branch_code
		if (@@error !=0)
			goto error
    end /*fetch*/


	/*
    * Calculate Results 5
    */
	fetch period_csr into @account_period
	if(@@fetch_status = 0)
	begin
        select  @nett_billings = 0, @prev_bill = 0
    	select  @nett_billings   = isnull(billings_month_05,0)
        from    dw_projected_billings
        where   report_date = @report_date
        and     branch_code = @branch_code
        and     product_type = @product_type
        and     finyear_end = @finyear

    	select  @prev_bill   = isnull(billings_month_05,0)
        from    dw_projected_billings
        where   report_date = @prev_report_date
        and     branch_code = @branch_code
        and     product_type = @product_type
        and     finyear_end = @finyear

        select  @manual_bill = 0, @budget_bill = 0
        select  @manual_bill = film_manual_billings_total,
                @budget_bill = film_billings_budget
        from    monthly_billings
        where   billing_period = @account_period
        and     country_code = @country_code

		update  #results
        set     period_5 = @account_period,
                bill_5 = @nett_billings,
                prev_bill_5 = @prev_bill,
                prev_date_5 = @prev_report_date,
                manual_bill_5 = @manual_bill,
                budget_bill_5 = @budget_bill
        where   branch_code = @branch_code
		if (@@error !=0)
			goto error
    end /*fetch*/

	/*
    * Calculate Results 6
    */
	fetch period_csr into @account_period
	if(@@fetch_status = 0)
	begin
        select  @nett_billings = 0, @prev_bill = 0
    	select  @nett_billings   = isnull(billings_month_06,0)
        from    dw_projected_billings
        where   report_date = @report_date
        and     branch_code = @branch_code
        and     product_type = @product_type
        and     finyear_end = @finyear

    	select  @prev_bill   = isnull(billings_month_06,0)
        from    dw_projected_billings
        where   report_date = @prev_report_date
        and     branch_code = @branch_code
        and     product_type = @product_type
        and     finyear_end = @finyear

        select  @manual_bill = 0, @budget_bill = 0
        select  @manual_bill = film_manual_billings_total,
                @budget_bill = film_billings_budget
        from    monthly_billings
        where   billing_period = @account_period
        and     country_code = @country_code

		update  #results
        set     period_6 = @account_period,
                bill_6 = @nett_billings,
                prev_bill_6 = @prev_bill,
                prev_date_6 = @prev_report_date,
                manual_bill_6 = @manual_bill,
                budget_bill_6 = @budget_bill
        where   branch_code = @branch_code
		if (@@error !=0)
			goto error
    end /*fetch*/

	/*
    * Calculate Results 7
    */
	fetch period_csr into @account_period
	if(@@fetch_status = 0)
	begin
        select  @nett_billings = 0, @prev_bill = 0
    	select  @nett_billings   = isnull(billings_month_07,0)
        from    dw_projected_billings
        where   report_date = @report_date
        and     branch_code = @branch_code
        and     product_type = @product_type
        and     finyear_end = @finyear

    	select  @prev_bill   = isnull(billings_month_07,0)
        from    dw_projected_billings
        where   report_date = @prev_report_date
        and     branch_code = @branch_code
        and     product_type = @product_type
        and     finyear_end = @finyear

        select  @manual_bill = 0, @budget_bill = 0
        select  @manual_bill = film_manual_billings_total,
                @budget_bill = film_billings_budget
        from    monthly_billings
        where   billing_period = @account_period
        and     country_code = @country_code

		update  #results
        set     period_7 = @account_period,
                bill_7 = @nett_billings,
                prev_bill_7 = @prev_bill,
                prev_date_7 = @prev_report_date,
                manual_bill_7 = @manual_bill,
                budget_bill_7 = @budget_bill
        where   branch_code = @branch_code
		if (@@error !=0)
			goto error
    end /*fetch*/

	/*
    * Calculate Results 8
    */
	fetch period_csr into @account_period
	if(@@fetch_status = 0)
	begin
        select  @nett_billings = 0, @prev_bill = 0
    	select  @nett_billings   = isnull(billings_month_08,0)
        from    dw_projected_billings
        where   report_date = @report_date
        and     branch_code = @branch_code
        and     product_type = @product_type
        and     finyear_end = @finyear

    	select  @prev_bill   = isnull(billings_month_08,0)
        from    dw_projected_billings
        where   report_date = @prev_report_date
        and     branch_code = @branch_code
        and     product_type = @product_type
        and     finyear_end = @finyear

        select  @manual_bill = 0, @budget_bill = 0
        select  @manual_bill = film_manual_billings_total,
                @budget_bill = film_billings_budget
        from    monthly_billings
        where   billing_period = @account_period
        and     country_code = @country_code

		update  #results
        set     period_8 = @account_period,
                bill_8 = @nett_billings,
                prev_bill_8 = @prev_bill,
                prev_date_8 = @prev_report_date,
                manual_bill_8 = @manual_bill,
                budget_bill_8 = @budget_bill
        where   branch_code = @branch_code
		if (@@error !=0)
			goto error
    end /*fetch*/

	/*
    * Calculate Results 9
    */
	fetch period_csr into @account_period
	if(@@fetch_status = 0)
	begin
        select  @nett_billings = 0, @prev_bill = 0
    	select  @nett_billings   = isnull(billings_month_09,0)
        from    dw_projected_billings
        where   report_date = @report_date
        and     branch_code = @branch_code
        and     product_type = @product_type
        and     finyear_end = @finyear

    	select  @prev_bill   = isnull(billings_month_09,0)
        from    dw_projected_billings
        where   report_date = @prev_report_date
        and     branch_code = @branch_code
        and     product_type = @product_type
        and     finyear_end = @finyear

        select  @manual_bill = 0, @budget_bill = 0
        select  @manual_bill = film_manual_billings_total,
                @budget_bill = film_billings_budget
        from    monthly_billings
        where   billing_period = @account_period
        and     country_code = @country_code

		update  #results
        set     period_9 = @account_period,
                bill_9 = @nett_billings,
                prev_bill_9 = @prev_bill,
                prev_date_9 = @prev_report_date,
                manual_bill_9 = @manual_bill,
                budget_bill_9 = @budget_bill
        where   branch_code = @branch_code
		if (@@error !=0)
			goto error
    end /*fetch*/

	/*
    * Calculate Results 10
    */
	fetch period_csr into @account_period
	if(@@fetch_status = 0)
	begin
        select  @nett_billings = 0, @prev_bill = 0
    	select  @nett_billings   = isnull(billings_month_10,0)
        from    dw_projected_billings
        where   report_date = @report_date
        and     branch_code = @branch_code
        and     product_type = @product_type
        and     finyear_end = @finyear

    	select  @prev_bill   = isnull(billings_month_10,0)
        from    dw_projected_billings
        where   report_date = @prev_report_date
        and     branch_code = @branch_code
        and     product_type = @product_type
        and     finyear_end = @finyear

        select  @manual_bill = 0, @budget_bill = 0
        select  @manual_bill = film_manual_billings_total,
                @budget_bill = film_billings_budget
        from    monthly_billings
        where   billing_period = @account_period
        and     country_code = @country_code

		update  #results
        set     period_10 = @account_period,
                bill_10 = @nett_billings,
                prev_bill_10 = @prev_bill,
                prev_date_10 = @prev_report_date,
                manual_bill_10 = @manual_bill,
                budget_bill_10 = @budget_bill
        where   branch_code = @branch_code
		if (@@error !=0)
			goto error
    end /*fetch*/

	/*
    * Calculate Results 11
    */
	fetch period_csr into @account_period
	if(@@fetch_status = 0)
	begin
        select  @nett_billings = 0, @prev_bill = 0
    	select  @nett_billings   = isnull(billings_month_11,0)
        from    dw_projected_billings
        where   report_date = @report_date
        and     branch_code = @branch_code
        and     product_type = @product_type
        and     finyear_end = @finyear

    	select  @prev_bill   = isnull(billings_month_11,0)
        from    dw_projected_billings
        where   report_date = @prev_report_date
        and     branch_code = @branch_code
        and     product_type = @product_type
        and     finyear_end = @finyear

        select  @manual_bill = 0, @budget_bill = 0
        select  @manual_bill = film_manual_billings_total,
                @budget_bill = film_billings_budget
        from    monthly_billings
        where   billing_period = @account_period
        and     country_code = @country_code

		update  #results
        set     period_11 = @account_period,
                bill_11 = @nett_billings,
                prev_bill_11 = @prev_bill,
                prev_date_11 = @prev_report_date,
                manual_bill_11 = @manual_bill,
                budget_bill_11 = @budget_bill
        where   branch_code = @branch_code
		if (@@error !=0)
			goto error
    end /*fetch*/

	/*
    * Calculate Results 12
    */
	fetch period_csr into @account_period
	if(@@fetch_status = 0)
	begin
        select  @nett_billings = 0, @prev_bill = 0
    	select  @nett_billings   = isnull(billings_month_12,0)
        from    dw_projected_billings
        where   report_date = @report_date
        and     branch_code = @branch_code
        and     product_type = @product_type
        and     finyear_end = @finyear

    	select  @prev_bill   = isnull(billings_month_12,0)
        from    dw_projected_billings
        where   report_date = @prev_report_date
        and     branch_code = @branch_code
        and     product_type = @product_type
        and     finyear_end = @finyear

        select  @manual_bill = 0, @budget_bill = 0
        select  @manual_bill = film_manual_billings_total,
                @budget_bill = film_billings_budget
        from    monthly_billings
        where   billing_period = @account_period
        and     country_code = @country_code

		update  #results
        set     period_12 = @account_period,
                bill_12 = @nett_billings,
                prev_bill_12 = @prev_bill,
                prev_date_12 = @prev_report_date,
                manual_bill_12 = @manual_bill,
                budget_bill_12 = @budget_bill
        where   branch_code = @branch_code
		if (@@error !=0)
			goto error
    end /*fetch*/

    /* insert future billing data */
    select  @nett_billings = 0, @prev_bill = 0
	select  @nett_billings   = isnull(billings_future,0)
    from    dw_projected_billings
    where   report_date = @report_date
    and     branch_code = @branch_code
    and     product_type = @product_type
    and     finyear_end = @finyear

	select  @prev_bill   = isnull(billings_future,0)
    from    dw_projected_billings
    where   report_date = @prev_report_date
    and     branch_code = @branch_code
    and     product_type = @product_type
    and     finyear_end = @finyear

    select  @manual_bill = 0, @budget_bill = 0

	update  #results
    set     period_ftr = @future_dummy_period,
            bill_ftr = @nett_billings,
            prev_bill_ftr = @prev_bill,
            prev_date_ftr = @prev_report_date,
            manual_bill_ftr = @manual_bill,
            budget_bill_ftr = @budget_bill,
            update_date_ftr = @report_date
    where   branch_code = @branch_code
	if (@@error !=0)
		goto error

	/*
    * Close Period Cursor
    */

	close period_csr
	deallocate period_csr
	select @period_csr_open = 0

	/*
    * Fetch Next
    */

	fetch branch_csr into @country_code, @branch_code

end
close branch_csr
deallocate branch_csr
select @branch_csr_open = 0

/*
 * Return Result Set
 */

select country_code,
       branch_code,
	period_1				,
	bill_1					,
    prev_bill_1             ,
    prev_date_1             ,
    manual_bill_1           ,
    budget_bill_1           ,
	period_2				,
	bill_2					,
    prev_bill_2             ,
    prev_date_2             ,
    manual_bill_2           ,
    budget_bill_2           ,
	period_3				,
	bill_3					,
    prev_bill_3             ,
    prev_date_3             ,
    manual_bill_3           ,
    budget_bill_3           ,
	period_4				,
	bill_4					,
    prev_bill_4             ,
    prev_date_4             ,
    manual_bill_4           ,
    budget_bill_4           ,
	period_5				,
	bill_5					,
    prev_bill_5             ,
    prev_date_5             ,
    manual_bill_5           ,
    budget_bill_5           ,
	period_6				,
	bill_6					,
    prev_bill_6             ,
    prev_date_6             ,
    manual_bill_6           ,
    budget_bill_6           ,
	period_7				,
	bill_7					,
    prev_bill_7             ,
    prev_date_7             ,
    manual_bill_7           ,
    budget_bill_7           ,
	period_8				,
	bill_8					,
    prev_bill_8             ,
    prev_date_8             ,
    manual_bill_8           ,
    budget_bill_8           ,
	period_9				,
	bill_9					,
    prev_bill_9             ,
    prev_date_9             ,
    manual_bill_9          ,
    budget_bill_9          ,
	period_10			,
	bill_10				,
    prev_bill_10         ,
    prev_date_10          ,
    manual_bill_10         ,
    budget_bill_10          ,
	period_11				,
	bill_11					,
    prev_bill_11            ,
    prev_date_11            ,
    manual_bill_11         ,
    budget_bill_11         ,
	period_12			,
	bill_12				,
    prev_bill_12        ,
    prev_date_12        ,
    manual_bill_12      ,
    budget_bill_12      ,
    period_ftr			,
	bill_ftr			,
    prev_bill_ftr       ,
    prev_date_ftr       ,
    manual_bill_ftr     ,
    budget_bill_ftr,
    update_date_ftr,
    @finyear as 'financial_year'
  from #results

/*
 * Return
 */

return 0

/*
 * Error Handler
 */

error:

	if(@branch_csr_open = 1)
	begin
		close branch_csr
		deallocate branch_csr
	end

	if(@period_csr_open = 1)
	begin
		close period_csr
		deallocate period_csr
	end

	return -1
GO
