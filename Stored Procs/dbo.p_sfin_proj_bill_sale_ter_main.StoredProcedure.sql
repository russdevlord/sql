/****** Object:  StoredProcedure [dbo].[p_sfin_proj_bill_sale_ter_main]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_sfin_proj_bill_sale_ter_main]
GO
/****** Object:  StoredProcedure [dbo].[p_sfin_proj_bill_sale_ter_main]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC  [dbo].[p_sfin_proj_bill_sale_ter_main]  @period_start	datetime, @country char(1)  as
set nocount on 
/*
 * Declare Valiables
 */ 

declare @error						integer,
	    @sqlstatus					integer,
        @errorode						integer,
        @country_code				char(1),
        @sales_territory_id			integer,
        @current_account_period	datetime,
        @account_period				datetime,
        @account_start				datetime,
        @nett_billings				money,
        @campaign_count				integer,
        @suspended					money,
        @cancelled					money,
        @credits					money,
        @period_csr_open			tinyint,
        @territory_csr_open			tinyint,
        @target                     money

/*
 * Create Temporary Table
 */

create table #results
(
	country_code			char(1)		    	null,
	sales_territory_id		integer		    	null,
	period_1				datetime			null,
	bill_1					money				null,
	count_1					integer		    	null,
   suspended_1				money				null,
   cancelled_1				money				null,
   credits_1				money				null,
   target_1                 money               null,
	period_2				datetime			null,
	bill_2					money				null,
	count_2					integer		    	null,
   suspended_2				money				null,
   cancelled_2				money				null,
   credits_2				money				null,
   target_2                 money               null,
	period_3				datetime			null,
	bill_3					money				null,
	count_3					integer		    	null,
   suspended_3				money				null,
   cancelled_3				money				null,
   credits_3				money				null,
   target_3                 money               null,
	period_4				datetime			null,
	bill_4					money				null,
	count_4					integer		    	null,
   suspended_4				money				null,
   cancelled_4				money				null,
   credits_4				money				null,
   target_4                 money               null,
	period_5				datetime			null,
	bill_5					money				null,
	count_5					integer		    	null,
   suspended_5				money				null,
   cancelled_5				money				null,
   credits_5				money				null,
   target_5                 money               null,
	period_6				datetime			null,
	bill_6					money				null,
	count_6					integer	    		null,
   suspended_6				money				null,
   cancelled_6				money				null,
   credits_6				money				null,
   target_6                 money               null,
	period_7				datetime			null,
	bill_7					money				null,
	count_7					integer		    	null,
   suspended_7				money				null,
   cancelled_7				money				null,
   credits_7				money				null,
   target_7                 money               null,
	period_8				datetime			null,
	bill_8					money				null,
	count_8					integer		    	null,
   suspended_8				money				null,
   cancelled_8				money				null,
   credits_8				money				null,
   target_8                 money               null,
	period_9				datetime			null,
	bill_9					money				null,
	count_9					integer		    	null,
   suspended_9				money				null,
   cancelled_9				money				null,
   credits_9				money				null,
   target_9                 money               null,
	period_10				datetime			null,
	bill_10					money				null,
	count_10				integer		    	null,
   suspended_10		    	money				null,
   cancelled_10	    		money				null,
   credits_10				money				null,
   target_10                money               null,
	period_11				datetime			null,
	bill_11					money				null,
	count_11				integer	    		null,
   suspended_11			    money				null,
   cancelled_11			    money				null,
   credits_11				money				null,
   target_11                money               null,
	period_12				datetime			null,
	bill_12					money				null,
	count_12				integer		      	null,
   suspended_12		    	money				null,
   cancelled_12			    money				null,
   credits_12				money				null,
   target_12                money               null
)

/*
 * Declare Cursors
 */ 

--declare period_csr cursor static for
-- select end_date,
--        start_date
--   from accounting_period
--  where	end_date >= @period_start
--order by end_date ASC
--     for read only

/*
 * Calculate Current Accounting Period
 */

select @current_account_period = min(benchmark_end)
  from accounting_period
 where status = 'O'

select @error = @@error
if (@error !=0)
	goto error

/*
 * Initialise Variables
 */

select @territory_csr_open = 0,
       @period_csr_open = 0

/*
 * Loop Branches
 */
 declare territory_csr cursor static for
  select sales_territory_id,
         country_code
    from sales_territory
 where   country_code = @country
     for read only
 
open territory_csr
select @territory_csr_open = 1
fetch territory_csr into @sales_territory_id, @country_code
while (@@fetch_status = 0)
begin

	/*
    * Insert Branch
    */

	insert into #results (country_code, sales_territory_id ) values (@country_code, @sales_territory_id)

	select @error = @@error
	if (@error !=0)
		goto error

	/*
  	 * Open Period Cursor
	 */

	declare period_csr cursor static for
	select  benchmark_end,
	        benchmark_start
	from    accounting_period
	where	end_date >=  @period_start
	order by benchmark_end ASC
	for read only

	open period_csr
	select @period_csr_open = 1

	/*
    * Calculate Results 1
    */

	fetch period_csr into @account_period, @account_start
	if(@@fetch_status = 0)
	begin

		execute @errorode = p_sfin_proj_bill_sales_terr @sales_territory_id,
                                                     @account_period,
                                                     @account_start,
                                                     @current_account_period,
                                                     @nett_billings OUTPUT,
                                                     @campaign_count OUTPUT,
                                                     @suspended OUTPUT,
                                                     @cancelled OUTPUT,
                                                     @credits OUTPUT
                                          
		if (@errorode !=0)
			return -1

        select @target =  0
        
        select @target = isnull(billing_target, 0)
        from    sales_territory_targets
        where   sales_territory_id = @sales_territory_id
        and     accounting_period = @account_period
	
		update #results
         set period_1 = @account_period,
             bill_1 = @nett_billings,
             count_1 = @campaign_count,
             suspended_1 = @suspended,
             cancelled_1 = @cancelled,
             credits_1 = @credits,
             target_1 = @target
       where sales_territory_id = @sales_territory_id

		select @error = @@error
		if (@error !=0)
			goto error

	end

	/*
    * Calculate Results 2
    */

	fetch period_csr into @account_period, @account_start
	if(@@fetch_status = 0)
	begin

		execute @errorode = p_sfin_proj_bill_sales_terr @sales_territory_id,
                                                     @account_period,
                                                     @account_start,
                                                     @current_account_period,
                                                     @nett_billings OUTPUT,
                                                     @campaign_count OUTPUT,
                                                     @suspended OUTPUT,
                                                     @cancelled OUTPUT,
                                                     @credits OUTPUT
                                          
		if (@errorode !=0)
			return -1
	
        select @target =  0
        
        select @target = isnull(billing_target, 0)
        from    sales_territory_targets
        where   sales_territory_id = @sales_territory_id
        and     accounting_period = @account_period
        
		update #results
         set period_2 = @account_period,
             bill_2 = @nett_billings,
             count_2 = @campaign_count,
             suspended_2 = @suspended,
             cancelled_2 = @cancelled,
             credits_2 = @credits,
             target_2 = @target
       where sales_territory_id = @sales_territory_id

		select @error = @@error
		if (@error !=0)
			goto error

	end

	/*
    * Calculate Results 3
    */

	fetch period_csr into @account_period, @account_start
	if(@@fetch_status = 0)
	begin

		execute @errorode = p_sfin_proj_bill_sales_terr @sales_territory_id,
                                                     @account_period,
                                                     @account_start,
                                                     @current_account_period,
                                                     @nett_billings OUTPUT,
                                                     @campaign_count OUTPUT,
                                                     @suspended OUTPUT,
                                                     @cancelled OUTPUT,
                                                     @credits OUTPUT
                                          
		if (@errorode !=0)
			return -1
	
        select @target =  0
        
        select @target = isnull(billing_target, 0)
        from    sales_territory_targets
        where   sales_territory_id = @sales_territory_id
        and     accounting_period = @account_period

		update #results
         set period_3 = @account_period,
             bill_3 = @nett_billings,
             count_3 = @campaign_count,
             suspended_3 = @suspended,
             cancelled_3 = @cancelled,
             credits_3 = @credits,
             target_3 = @target
       where sales_territory_id = @sales_territory_id

		select @error = @@error
		if (@error !=0)
			goto error

	end

	/*
    * Calculate Results 4
    */

	fetch period_csr into @account_period, @account_start
	if(@@fetch_status = 0)
	begin

		execute @errorode = p_sfin_proj_bill_sales_terr @sales_territory_id,
                                                     @account_period,
                                                     @account_start,
                                                     @current_account_period,
                                                     @nett_billings OUTPUT,
                                                     @campaign_count OUTPUT,
                                                     @suspended OUTPUT,
                                                     @cancelled OUTPUT,
                                                     @credits OUTPUT
                                          
		if (@errorode !=0)
			return -1
	
        select @target =  0
        
        select @target = isnull(billing_target, 0)
        from    sales_territory_targets
        where   sales_territory_id = @sales_territory_id
        and     accounting_period = @account_period
    
		update #results
         set period_4 = @account_period,
             bill_4 = @nett_billings,
             count_4 = @campaign_count,
             suspended_4 = @suspended,
             cancelled_4 = @cancelled,
             credits_4 = @credits,
             target_4 = @target
       where sales_territory_id = @sales_territory_id

		select @error = @@error
		if (@error !=0)
			goto error

	end

	/*
    * Calculate Results 5
    */

	fetch period_csr into @account_period, @account_start
	if(@@fetch_status = 0)
	begin

		execute @errorode = p_sfin_proj_bill_sales_terr @sales_territory_id,
                                                     @account_period,
                                                     @account_start,
                                                     @current_account_period,
                                                     @nett_billings OUTPUT,
                                                     @campaign_count OUTPUT,
                                                     @suspended OUTPUT,
                                                     @cancelled OUTPUT,
                                                     @credits OUTPUT
                                          
		if (@errorode !=0)
			return -1

        select @target =  0
        
        select @target = isnull(billing_target, 0)
        from    sales_territory_targets
        where   sales_territory_id = @sales_territory_id
        and     accounting_period = @account_period
	
		update #results
         set period_5 = @account_period,
             bill_5 = @nett_billings,
             count_5 = @campaign_count,
             suspended_5 = @suspended,
             cancelled_5 = @cancelled,
             credits_5 = @credits,
             target_5 = @target
       where sales_territory_id = @sales_territory_id

		select @error = @@error
		if (@error !=0)
			goto error

	end

	/*
    * Calculate Results 6
    */

	fetch period_csr into @account_period, @account_start
	if(@@fetch_status = 0)
	begin

		execute @errorode = p_sfin_proj_bill_sales_terr @sales_territory_id,
                                                     @account_period,
                                                     @account_start,
                                                     @current_account_period,
                                                     @nett_billings OUTPUT,
                                                     @campaign_count OUTPUT,
                                                     @suspended OUTPUT,
                                                     @cancelled OUTPUT,
                                                     @credits OUTPUT
                                          
		if (@errorode !=0)
			return -1

        select @target =  0
        
        select @target = isnull(billing_target, 0)
        from    sales_territory_targets
        where   sales_territory_id = @sales_territory_id
        and     accounting_period = @account_period
	
		update #results
         set period_6 = @account_period,
             bill_6 = @nett_billings,
             count_6 = @campaign_count,
             suspended_6 = @suspended,
             cancelled_6 = @cancelled,
             credits_6 = @credits,
             target_6 = @target
       where sales_territory_id = @sales_territory_id

		select @error = @@error
		if (@error !=0)
			goto error

	end

	/*
    * Calculate Results 7
    */

	fetch period_csr into @account_period, @account_start
	if(@@fetch_status = 0)
	begin

		execute @errorode = p_sfin_proj_bill_sales_terr @sales_territory_id,
                                                     @account_period,
                                                     @account_start,
                                                     @current_account_period,
                                                     @nett_billings OUTPUT,
                                                     @campaign_count OUTPUT,
                                                     @suspended OUTPUT,
                                                     @cancelled OUTPUT,
                                                     @credits OUTPUT
                                          
		if (@errorode !=0)
			return -1

        select @target =  0
        
        select @target = isnull(billing_target, 0)
        from    sales_territory_targets
        where   sales_territory_id = @sales_territory_id
        and     accounting_period = @account_period
	
		update #results
         set period_7 = @account_period,
             bill_7 = @nett_billings,
             count_7 = @campaign_count,
             suspended_7 = @suspended,
             cancelled_7 = @cancelled,
             credits_7 = @credits,
             target_7 = @target
       where sales_territory_id = @sales_territory_id

		select @error = @@error
		if (@error !=0)
			goto error

	end

	/*
    * Calculate Results 8
    */

	fetch period_csr into @account_period, @account_start
	if(@@fetch_status = 0)
	begin

		execute @errorode = p_sfin_proj_bill_sales_terr @sales_territory_id,
                                                     @account_period,
                                                     @account_start,
                                                     @current_account_period,
                                                     @nett_billings OUTPUT,
                                                     @campaign_count OUTPUT,
                                                     @suspended OUTPUT,
                                                     @cancelled OUTPUT,
                                                     @credits OUTPUT
                                          
		if (@errorode !=0)
			return -1

        select @target =  0
        
        select @target = isnull(billing_target, 0)
        from    sales_territory_targets
        where   sales_territory_id = @sales_territory_id
        and     accounting_period = @account_period
	
		update #results
         set period_8 = @account_period,
             bill_8 = @nett_billings,
             count_8 = @campaign_count,
             suspended_8 = @suspended,
             cancelled_8 = @cancelled,
             credits_8 = @credits,
             target_8 = @target
       where sales_territory_id = @sales_territory_id

		select @error = @@error
		if (@error !=0)
			goto error

	end

	/*
    * Calculate Results 9
    */

	fetch period_csr into @account_period, @account_start
	if(@@fetch_status = 0)
	begin

		execute @errorode = p_sfin_proj_bill_sales_terr @sales_territory_id,
                                                     @account_period,
                                                     @account_start,
                                                     @current_account_period,
                                                     @nett_billings OUTPUT,
                                                     @campaign_count OUTPUT,
                                                     @suspended OUTPUT,
                                                     @cancelled OUTPUT,
                                                     @credits OUTPUT
                                          
		if (@errorode !=0)
			return -1
            
        select @target =  0
        
        select @target = isnull(billing_target, 0)
        from    sales_territory_targets
        where   sales_territory_id = @sales_territory_id
        and     accounting_period = @account_period
	
		update #results
         set period_9 = @account_period,
             bill_9 = @nett_billings,
             count_9 = @campaign_count,
             suspended_9 = @suspended,
             cancelled_9 = @cancelled,
             credits_9 = @credits,
             target_9 = @target
       where sales_territory_id = @sales_territory_id

		select @error = @@error
		if (@error !=0)
			goto error

	end

	/*
    * Calculate Results 10
    */

	fetch period_csr into @account_period, @account_start
	if(@@fetch_status = 0)
	begin

		execute @errorode = p_sfin_proj_bill_sales_terr @sales_territory_id,
                                                     @account_period,
                                                     @account_start,
                                                     @current_account_period,
                                                     @nett_billings OUTPUT,
                                                     @campaign_count OUTPUT,
                                                     @suspended OUTPUT,
                                                     @cancelled OUTPUT,
                                                     @credits OUTPUT
                                          
		if (@errorode !=0)
			return -1
            
        select @target =  0
        
        select @target = isnull(billing_target, 0)
        from    sales_territory_targets
        where   sales_territory_id = @sales_territory_id
        and     accounting_period = @account_period
	
		update #results
         set period_10 = @account_period,
             bill_10 = @nett_billings,
             count_10 = @campaign_count,
             suspended_10 = @suspended,
             cancelled_10 = @cancelled,
             credits_10 = @credits,
             target_10 = @target
       where sales_territory_id = @sales_territory_id

		select @error = @@error
		if (@error !=0)
			goto error

	end

	/*
    * Calculate Results 11
    */

	fetch period_csr into @account_period, @account_start
	if(@@fetch_status = 0)
	begin

		execute @errorode = p_sfin_proj_bill_sales_terr @sales_territory_id,
                                                     @account_period,
                                                     @account_start,
                                                     @current_account_period,
                                                     @nett_billings OUTPUT,
                                                     @campaign_count OUTPUT,
                                                     @suspended OUTPUT,
                                                     @cancelled OUTPUT,
                                                     @credits OUTPUT
                                          
		if (@errorode !=0)
			return -1

        select @target =  0
        
        select @target = isnull(billing_target, 0)
        from    sales_territory_targets
        where   sales_territory_id = @sales_territory_id
        and     accounting_period = @account_period
	
		update #results
         set period_11 = @account_period,
             bill_11 = @nett_billings,
             count_11 = @campaign_count,
             suspended_11 = @suspended,
             cancelled_11 = @cancelled,
             credits_11 = @credits,
             target_11 = @target
       where sales_territory_id = @sales_territory_id

		select @error = @@error
		if (@error !=0)
			goto error

	end

	/*
    * Calculate Results 12
    */

	fetch period_csr into @account_period, @account_start
	if(@@fetch_status = 0)
	begin

		execute @errorode = p_sfin_proj_bill_sales_terr @sales_territory_id,
                                                     @account_period,
                                                     @account_start,
                                                     @current_account_period,
                                                     @nett_billings OUTPUT,
                                                     @campaign_count OUTPUT,
                                                     @suspended OUTPUT,
                                                     @cancelled OUTPUT,
                                                     @credits OUTPUT
                                          
		if (@errorode !=0)
			return -1

        select @target =  0
        
        select @target = isnull(billing_target, 0)
        from    sales_territory_targets
        where   sales_territory_id = @sales_territory_id
        and     accounting_period = @account_period
	
		update #results
         set period_12 = @account_period,
             bill_12 = @nett_billings,
             count_12 = @campaign_count,
             suspended_12 = @suspended,
             cancelled_12 = @cancelled,
             credits_12 = @credits,
             target_12 = @target
       where sales_territory_id = @sales_territory_id

		select @error = @@error
		if (@error !=0)
			goto error

	end

	/*
    * Close Period Cursor
    */

	close period_csr
	deallocate period_csr
	select @period_csr_open = 0

	/*
    * Fetch Next
    */

	fetch territory_csr into @sales_territory_id, @country_code

end

if(@territory_csr_open = 1)
begin
	close territory_csr
	deallocate territory_csr
end

if(@period_csr_open = 1)
begin
	close period_csr
	deallocate period_csr
end

/*
 * Return Result Set
 */

select * from #results

/*
 * Return
 */

return 0

/*
 * Error Handler
 */

error:
	
	if(@territory_csr_open = 1)
	begin
		close territory_csr
		deallocate territory_csr
	end

	if(@period_csr_open = 1)
	begin
		close period_csr
		deallocate period_csr
	end

	return -1
GO
