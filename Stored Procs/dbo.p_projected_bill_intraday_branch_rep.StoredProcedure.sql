/****** Object:  StoredProcedure [dbo].[p_projected_bill_intraday_branch_rep]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_projected_bill_intraday_branch_rep]
GO
/****** Object:  StoredProcedure [dbo].[p_projected_bill_intraday_branch_rep]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create PROC [dbo].[p_projected_bill_intraday_branch_rep]   	@report_date	        datetime,
		                                            @prev_report_date       datetime,
		                                            @finyear                datetime,
		                                            @business_unit_id       int,    
		                                            @media_product_id       int,
		                                            @mode                   char(1),
		                                            @intra_day              char(1),
													@adjustments			char(1),
													@branch_code			varchar(2)
with recompile as

/*
 * Declare Valiables
 */

declare @error							int,
        @sqlstatus					    int,
        @errorode							int,
        @account_period				    datetime,
        @selected_acct_period           datetime,
        @prev_actual_report_date        datetime,
        @prev_bill                      money,
        @future_dummy_period            datetime,
        @manual_bill                    money,
        @budget_bill                    money,
        @prev_year_bill                 money,
        @final_prev_year_bill           money,        
        @prev_year                      datetime,
        @nett_billings				    money,
        @period_csr_open			    tinyint,
        @branch_csr_open			    tinyint,
        @update_date_ftr                datetime,
        @sort_order                     smallint,
        @sort_add                       smallint,
        @end_of_month_date              datetime,
        @group_desc                     varchar(50),
        @sub_group_desc                 varchar(50),
        @report_header                  varchar(255),
        @agency_deal                    char(1),
        @budget_type                    int,
        @previous_year_run_date         datetime,
        @working_days                   int,
        @finyear_start                  datetime,
        @final_year                     datetime,
        @next_final_year                datetime,
		@other_income_desc				varchar(50),
		@other_billings					money,
		@adjustment_amount				money,
		@branch_name					varchar(50),
		@adj_branch_code				varchar(20),
		@group_adj						varchar(50),
		@final_year_end_date			datetime,
		@country_code					char(1)

/*
 * Create Temporary Tables
 */


create table #intra
(
    benchmark_end               datetime        null,
    branch_code                 varchar(2)      null,
    business_unit_id            int             null,
    media_product_id            int             null,
    agency_deal                 char(1)         null,
    amount                      money           null,
    finyear_end                 datetime        null
)

create table #intra_adj
(
    benchmark_end               datetime        null,
    branch_code                 varchar(2)      null,
    business_unit_id            int             null,
    media_product_id            int             null,
    agency_deal                 char(1)         null,
    amount                      money           null,
    finyear_end                 datetime        null
)

create table #results
(
	country_code			    char(1)			null,
	branch_code				    varchar(2)		null,
	branch_name					varchar(50)		null,
	period_1				    datetime		null,
	bill_1					    money			null,
    prev_bill_1                 money           null,
    prev_date_1                 datetime        null,
    manual_bill_1               money           null,
    budget_bill_1               money           null,
    previous_year_1             money           null,
    final_previous_year_1       money           null,
	period_2				    datetime		null,
	bill_2					    money			null,
    prev_bill_2                 money           null,
    prev_date_2                 datetime        null,
    manual_bill_2               money           null,
 	budget_bill_2               money           null,
    previous_year_2             money           null,
    final_previous_year_2       money           null,
    period_3				    datetime		null,
	bill_3					    money			null,
    prev_bill_3                 money           null,
    prev_date_3                 datetime        null,
    manual_bill_3               money           null,
    budget_bill_3               money           null,
    previous_year_3             money           null,
    final_previous_year_3       money           null,
	period_4				    datetime		null,
	bill_4					    money			null,
    prev_bill_4                 money           null,
    prev_date_4                 datetime        null,
    manual_bill_4               money           null,
    budget_bill_4               money           null,
    previous_year_4             money           null,
    final_previous_year_4       money           null,
	period_5				    datetime		null,
	bill_5					    money			null,
    prev_bill_5                 money           null,
    prev_date_5                 datetime        null,
    manual_bill_5               money           null,
    budget_bill_5               money           null,
    previous_year_5             money           null,
    final_previous_year_5       money           null,
	period_6				    datetime		null,
	bill_6					    money			null,
    prev_bill_6                 money           null,
    prev_date_6                 datetime        null,
    manual_bill_6               money           null,
    budget_bill_6               money           null,
    previous_year_6             money           null,
    final_previous_year_6       money           null,
	period_7				    datetime		null,
	bill_7					    money			null,
    prev_bill_7                 money           null,
    prev_date_7                 datetime        null,
    manual_bill_7               money           null,
    budget_bill_7               money           null,
    previous_year_7             money           null,
    final_previous_year_7       money           null,
	period_8				    datetime		null,
	bill_8					    money			null,
    prev_bill_8                 money           null,
    prev_date_8                 datetime        null,
    manual_bill_8               money           null,
    budget_bill_8               money           null,
    previous_year_8             money           null,
    final_previous_year_8       money           null,
	period_9				    datetime		null,
	bill_9					    money			null,
    prev_bill_9                 money           null,
    prev_date_9                 datetime        null,
    manual_bill_9               money           null,
    budget_bill_9               money           null,
    previous_year_9             money           null,
    final_previous_year_9       money           null,
	period_10				    datetime		null,
	bill_10					    money			null,
    prev_bill_10                money           null,
    prev_date_10                datetime        null,
    manual_bill_10              money           null,
    budget_bill_10              money           null,
    previous_year_10            money           null,
    final_previous_year_10      money           null,
	period_11				    datetime		null,
	bill_11					    money			null,
    prev_bill_11                money           null,
    prev_date_11                datetime        null,
    manual_bill_11              money           null,
    budget_bill_11              money           null,
    previous_year_11            money           null,
    final_previous_year_11      money           null,
	period_12				    datetime		null,
	bill_12					    money			null,
    prev_bill_12                money           null,
    prev_date_12                datetime        null,
    manual_bill_12              money           null,
    budget_bill_12              money     null,
    previous_year_12            money           null,
    final_previous_year_12      money           null,
   	period_ftr				    datetime		null,
	bill_ftr				    money			null,
    prev_bill_ftr               money           null,
    prev_date_ftr               datetime        null,
    manual_bill_ftr             money           null,
    budget_bill_ftr             money           null,
    update_date_ftr             datetime        null,
    previous_year_ftr           money           null,
    final_previous_year_ftr     money           null,
    financial_year              datetime        null,
    sort_order                  smallint        null,
    group_desc                  varchar(50)     null,
    sub_group_desc              varchar(50)     null,
	other_income_1				money			null,
	other_income_2				money			null,
	other_income_3				money			null,
	other_income_4				money			null,
	other_income_5				money			null,
	other_income_6				money			null,
	other_income_7				money			null,
	other_income_8				money			null,
	other_income_9				money			null,
	other_income_10				money			null,
	other_income_11				money			null,
	other_income_12				money			null,
	other_income_ftr			money			null,
	other_income_desc			varchar(50)		null)

/*
 * Initialise Variables
 */

/* use a fake furture billing period to make creating report easy, matches generation routine code */
select @future_dummy_period = '1 jan 2050'

select @branch_csr_open = 0,
       @period_csr_open = 0

/* get last closed accounting period prior to chosen report date */
select  @selected_acct_period = max(benchmark_end)
from    accounting_period
where   benchmark_end <= @report_date

if @selected_acct_period is null
    return -1

select  @prev_actual_report_date = max(report_date)
from    projected_billings
where   report_date <= @report_date

if @prev_actual_report_date is null
    return -1

select  @prev_report_date = max(report_date)
from    projected_billings
where   report_date <= @prev_report_date

if @prev_report_date is null
    return -1

/* number of working days should be the same for 'as at date' for current and prior period */
select @finyear_start = finyear_start from financial_year where finyear_end >= @finyear and finyear_start <= @finyear
/*exec @errorode = p_workingdays @finyear_start, @report_date, @working_days OUTPUT
if @errorode != 0
begin
    raiserror ('Error Calcuating Prior As At Date', 16, 1)
    return -1
end 

exec @errorode = p_get_workingday @finyear_start, @final_year OUTPUT, 1
if @errorode != 0
begin
    raiserror ('Error Calcuating Prior As At Date', 16, 1)
    return -1
end 
*/
select @finyear_start = max(finyear_start) from financial_year where finyear_end <  @finyear
select @prev_year = max(finyear_end) from financial_year where finyear_end <  @finyear
/*exec @errorode = p_get_workingday @finyear_start, @previous_year_run_date OUTPUT, @working_days
if @errorode != 0
begin
    raiserror ('Error Calcuating Prior As At Date', 16, 1)
    return -1
end 
*/
select @previous_year_run_date = dateadd(yy, -1, @report_date)
select @previous_year_run_date = min(report_date) from projected_billings where report_date >= @previous_year_run_date

select @final_year = max(report_date) from projected_billings where finyear_end = @prev_year

select @final_year_end_date = dateadd(dd, 1, @prev_year)

select @final_year_end_date = max(report_date) from projected_billings where finyear_end = @prev_year and report_date <= @final_year_end_date 

select @country_code = country_code from branch where @branch_code = branch_code

if @intra_day = 'I'
begin
    select @next_final_year = dateadd(yy,1,@finyear)
    
    insert into #intra
    (
    benchmark_end,
    branch_code,
    business_unit_id,
    media_product_id,
    agency_deal,
    amount,
    finyear_end
    ) 
    select      accounting_period, 
                branch_code,
                business_unit_id,
                media_product_id,
                agency_deal,
                billings,
                finyear
    from        v_projbill_bu_mp_ad
    where       finyear >= @finyear
	and 		branch_code = @branch_code

end 

if @adjustments = 'Y'
begin
    insert into #intra_adj
    (
    benchmark_end,
    branch_code,
    business_unit_id,
    media_product_id,
    agency_deal,
    amount,
    finyear_end
    ) 
    select      accounting_period, 
                branch_code,
                business_unit_id,
                media_product_id,
                agency_deal,
                adjustment,
                finyear
    from        v_film_adj_bp_mp_ad
    where       finyear >= @finyear
	and 		branch_code = @branch_code
end


/*
 * Declare Cursors
 */

select 		@other_income_desc = 'None'

if @mode = '1' -- Business Unit Header Report     
begin
    select      @report_header = 'Business Unit : ' + business_unit_desc
    from        business_unit
    where       business_unit_id = @business_unit_id

	select 		@other_income_desc = 'Cinelights'


    declare     report_csr cursor static for
    select      bu.business_unit_id,
                null,
                convert(char(1),null),
                'Media',
                '',
                0,
                b.country_code,
                b.branch_code,
                b.sort_order
    from        business_unit bu,
                branch b
    where       bu.system_use_only = 'N'
    and         bu.business_unit_id = @business_unit_id
    and         b.branch_code = @branch_code
    order by    bu.business_unit_id
    for         read only

    
end
else if @mode = '2' -- Media Product Header Report
begin


    select      @report_header = 'Media Product : ' + media_product_desc
    from        media_product
    where       media_product_id = @media_product_id

    declare     report_csr cursor static for
    select      null,
                mp.media_product_id,
                ad.agency_deal,
                ad.agency_deal_desc,
                ad.agency_deal_desc,
                case when  ad.agency_deal = 'Y' then 0 else 100 end,
                b.country_code,
                b.branch_code,
                b.sort_order 
    from        agency_deal ad,
                media_product mp,
                branch b
    where       mp.system_use_only = 'N'  
    and         mp.media_product_id = @media_product_id
    and         b.branch_code = @branch_code
    order by    mp.media_product_id,
                ad.agency_deal
    for         read only
end
else
begin
    raiserror ('Error: Unsupported Mode', 16, 1)
    return -1
end


/*
 * Loop Branches & Business Unit/Media Product
 */

select @group_adj = ''
open report_csr
fetch report_csr into @business_unit_id, @media_product_id, @agency_deal, @group_desc, @sub_group_desc, @sort_add, @country_code, @branch_code, @sort_order
while(@@fetch_status=0)
begin
    /*
     * Add Sorts Together
     */
     
        if @mode = '1' or @mode = '2'
            select @sort_order = @sort_order + @sort_add
        else if @mode = '3' or @mode = '4'
            select @sort_order = @sort_add        
	/*
     * Insert Branch
     */

	select @branch_name = branch_name from branch where branch_code = @branch_code
	
	insert into #results (country_code, branch_code, branch_name, sort_order, group_desc, sub_group_desc, other_income_desc ) values (@country_code, @branch_code, @branch_name, @sort_order, @group_desc, @sub_group_desc, @other_income_desc)
	select @error = @@error
	if (@error !=0)
		goto error

	if @adjustments = 'Y' and @group_adj != @group_desc
	begin
		select	@branch_name = 'Adjustments'
		select 	@adj_branch_code =  'A'

		insert into #results (country_code, branch_code, branch_name, sort_order, group_desc, sub_group_desc, other_income_desc ) values (@country_code, @adj_branch_code, @branch_name, 15000, @group_desc, @sub_group_desc, @other_income_desc)
		select @error = @@error
		if (@error !=0)
			goto error
	end

	select @group_adj = @group_desc

	/*
  	 * Open Period Cursor
	 */

	 declare period_csr cursor static for
	  select benchmark_end
	    from accounting_period
	   where finyear_end = @finyear
	order by benchmark_end ASC
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
        if @intra_day = 'I' /* intra day report */
        begin
            /* get projected billing amount for period and branch */
            select  @nett_billings   = isnull(sum(amount),0)
            from    #intra
            where   branch_code = @branch_code
            and     (business_unit_id = @business_unit_id
             or     @business_unit_id is null)
            and     (agency_deal = @agency_deal
             or     @agency_deal is null)
            and     (media_product_id = @media_product_id or (@media_product_id is null and media_product_id in (select media_product_id from media_product where media = 'Y')))
            and     benchmark_end = @account_period
            and     finyear_end = @finyear
        end
        else
        begin
        	select  @nett_billings   = isnull(sum(billings_month_01),0)
            from    projected_billings
            where   report_date = @report_date
            and     branch_code = @branch_code
            and     (business_unit_id = @business_unit_id
             or     @business_unit_id is null)
            and     (agency_deal = @agency_deal
             or     @agency_deal is null)
            and     (media_product_id = @media_product_id or (@media_product_id is null and media_product_id in (select media_product_id from media_product where media = 'Y')))
            and     finyear_end = @finyear
        end

		if @mode = '1'
		begin
	        if @intra_day = 'I' /* intra day report */
	        begin
	            select  @other_billings   = isnull(sum(amount),0)
	            from    #intra
	            where   branch_code = @branch_code
	            and     (business_unit_id = @business_unit_id
	             or     @business_unit_id is null)
	            and     (agency_deal = @agency_deal
	             or     @agency_deal is null)
	            and     (media_product_id = @media_product_id or (@media_product_id is null and media_product_id in (select media_product_id from media_product where media = 'N')))
	            and     benchmark_end = @account_period
	            and     finyear_end = @finyear
			end
			else
			begin
				select 	@other_billings = isnull(sum(billings_month_01),0)
				from 	projected_billings 
				where	report_date = @report_date
	            and     (business_unit_id = @business_unit_id
	             or     @business_unit_id is null)
	            and     (media_product_id = @media_product_id or (@media_product_id is null and media_product_id in (select media_product_id from media_product where media = 'N')))
	            and     finyear_end = @finyear
				and		branch_code in (select branch_code from branch where country_code = @country_code)
			end	
		end 

    	select  @prev_bill   = isnull(sum(billings_month_01),0)
        from    projected_billings
        where   report_date = @prev_report_date
        and     branch_code = @branch_code
        and     (business_unit_id = @business_unit_id
         or     @business_unit_id is null)
        and     (agency_deal = @agency_deal
         or     @agency_deal is null)
        and     (media_product_id = @media_product_id or (@media_product_id is null and media_product_id in (select media_product_id from media_product where media = 'Y')))
        and     finyear_end = @finyear

    	select  @prev_year_bill   = isnull(sum(billings_month_01),0)
        from    projected_billings
        where   report_date = @previous_year_run_date
        and     branch_code = @branch_code
        and     (business_unit_id = @business_unit_id
         or     @business_unit_id is null)
        and     (agency_deal = @agency_deal
         or     @agency_deal is null)
        and     (media_product_id = @media_product_id or (@media_product_id is null and media_product_id in (select media_product_id from media_product where media = 'Y')))
        and     finyear_end = @prev_year

    	select  @final_prev_year_bill   = isnull(sum(billings_month_01),0)
        from    projected_billings
        where   report_date = @final_year
        and     branch_code = @branch_code
        and     (business_unit_id = @business_unit_id
         or     @business_unit_id is null)
        and     (agency_deal = @agency_deal
         or     @agency_deal is null)
        and     (media_product_id = @media_product_id or (@media_product_id is null and media_product_id in (select media_product_id from media_product where media = 'Y')))
        and     finyear_end = @prev_year


        select  @manual_bill = 0, @budget_bill = 0
        select  @manual_bill = isnull(sum(film_manual_billings_total),0),
                @budget_bill = isnull(sum(film_billings_budget),0)
        from    monthly_billings
        where   billing_period = @account_period
        and     country_code = @country_code
        and     (budget_type = @business_unit_id
         or     @business_unit_id is null)
        and     (budget_type_id = @media_product_id or @media_product_id is null)

		update  #results
        set     period_1 = @account_period,
                bill_1 = @nett_billings,
                prev_bill_1 = @prev_bill,
                prev_date_1 = @prev_report_date,
                manual_bill_1 = @manual_bill,
                budget_bill_1 = @budget_bill,
                previous_year_1 = @prev_year_bill,
                final_previous_year_1 = @final_prev_year_bill,
				other_income_1 = @other_billings
        where   branch_code = @branch_code
        and     group_desc = @group_desc
        and     sub_group_desc = @sub_group_desc
        
		if (@@error !=0)
			goto error

		if @adjustments = 'Y'
		begin

            select  @adjustment_amount = isnull(sum(amount),0)
            from    #intra_adj
            where   (business_unit_id = @business_unit_id
             or     @business_unit_id is null)
            and     branch_code in (select branch_code from branch where country_code = @country_code)
            and     (agency_deal = @agency_deal
             or     @agency_deal is null)
            and     (media_product_id = @media_product_id or (@media_product_id is null and media_product_id in (select media_product_id from media_product where media = 'Y')))
            and     benchmark_end = @account_period
            and     finyear_end = @finyear

			update  #results
	        set     period_1 = @account_period,
	                bill_1 = @adjustment_amount,
	                prev_bill_1 = 0,
	                prev_date_1 = @prev_report_date,
	                manual_bill_1 = 0,
	                budget_bill_1 = 0,
	                previous_year_1 = 0,
	                final_previous_year_1 = 0,
					other_income_1 = 0
	        where   branch_code = @adj_branch_code
	        and     group_desc = @group_desc
	        and     sub_group_desc = @sub_group_desc
		end
    end /*fetch*/

	/*
    * Calculate Results 2
    */
	fetch period_csr into @account_period
	if(@@fetch_status = 0)
	begin
        select  @nett_billings = 0, @prev_bill = 0
        if @intra_day = 'I' /* intra day report */
        begin
            /* get projected billing amount for period and branch */
            select  @nett_billings   = isnull(sum(amount),0)
            from    #intra
            where   branch_code = @branch_code
            and     (business_unit_id = @business_unit_id
             or     @business_unit_id is null)
            and     (agency_deal = @agency_deal
             or     @agency_deal is null)
            and     (media_product_id = @media_product_id or (@media_product_id is null and media_product_id in (select media_product_id from media_product where media = 'Y')))
            and     benchmark_end = @account_period
            and     finyear_end = @finyear
        end
        else
        begin
        	select  @nett_billings   = isnull(sum(billings_month_02),0)
            from    projected_billings
            where   report_date = @report_date
            and     branch_code = @branch_code
            and     (business_unit_id = @business_unit_id
             or     @business_unit_id is null)
            and     (agency_deal = @agency_deal
             or     @agency_deal is null)
            and     (media_product_id = @media_product_id or (@media_product_id is null and media_product_id in (select media_product_id from media_product where media = 'Y')))
            and     finyear_end = @finyear
        end

		if @mode = '1'
		begin
	        if @intra_day = 'I' /* intra day report */
	        begin
	            select  @other_billings   = isnull(sum(amount),0)
	            from    #intra
	            where   branch_code = @branch_code
	            and     (business_unit_id = @business_unit_id
	             or     @business_unit_id is null)
	            and     (agency_deal = @agency_deal
	             or     @agency_deal is null)
	            and     (media_product_id = @media_product_id or (@media_product_id is null and media_product_id in (select media_product_id from media_product where media = 'N')))
	            and     benchmark_end = @account_period
	            and     finyear_end = @finyear
			end
			else
			begin
				select 	@other_billings = isnull(sum(billings_month_02),0)
				from 	projected_billings 
				where	report_date = @report_date
	            and     (business_unit_id = @business_unit_id
	             or     @business_unit_id is null)
	            and     (media_product_id = @media_product_id or (@media_product_id is null and media_product_id in (select media_product_id from media_product where media = 'N')))
	            and     finyear_end = @finyear
				and		branch_code in (select branch_code from branch where country_code = @country_code)
			end	
		end 


    	select  @prev_bill   = isnull(sum(billings_month_02),0)
        from    projected_billings
        where   report_date = @prev_report_date
        and     branch_code = @branch_code
        and     (business_unit_id = @business_unit_id
         or     @business_unit_id is null)
        and     (agency_deal = @agency_deal
         or     @agency_deal is null)
        and     (media_product_id = @media_product_id or (@media_product_id is null and media_product_id in (select media_product_id from media_product where media = 'Y')))
        and     finyear_end = @finyear

    	select  @prev_year_bill   = isnull(sum(billings_month_02),0)
        from    projected_billings
        where   report_date = @previous_year_run_date
        and     branch_code = @branch_code
        and     (business_unit_id = @business_unit_id
         or     @business_unit_id is null)
        and     (agency_deal = @agency_deal
         or     @agency_deal is null)
        and     (media_product_id = @media_product_id or (@media_product_id is null and media_product_id in (select media_product_id from media_product where media = 'Y')))
        and     finyear_end = @prev_year

    	select  @final_prev_year_bill   = isnull(sum(billings_month_02),0)
        from    projected_billings
        where   report_date = @final_year
        and     branch_code = @branch_code
        and     (business_unit_id = @business_unit_id
         or     @business_unit_id is null)
        and     (agency_deal = @agency_deal
         or     @agency_deal is null)
        and     (media_product_id = @media_product_id or (@media_product_id is null and media_product_id in (select media_product_id from media_product where media = 'Y')))
        and     finyear_end = @prev_year

        select  @manual_bill = 0, @budget_bill = 0
        select  @manual_bill = isnull(sum(film_manual_billings_total),0),
                @budget_bill = isnull(sum(film_billings_budget),0)
        from    monthly_billings
        where   billing_period = @account_period
        and     country_code = @country_code
        and     (budget_type = @business_unit_id
         or     @business_unit_id is null)
        and     (budget_type_id = @media_product_id or @media_product_id is null)

		update  #results
        set     period_2 = @account_period,
                bill_2 = @nett_billings,
                prev_bill_2 = @prev_bill,
                prev_date_2 = @prev_report_date,
                manual_bill_2 = @manual_bill,
                budget_bill_2 = @budget_bill,
                previous_year_2 = @prev_year_bill,
                final_previous_year_2 = @final_prev_year_bill,
				other_income_2 = @other_billings
        where   branch_code = @branch_code
        and     group_desc = @group_desc
        and     sub_group_desc = @sub_group_desc
        
        if (@@error !=0)
			goto error
		if @adjustments = 'Y'
		begin

            select  @adjustment_amount = isnull(sum(amount),0)
            from    #intra_adj
            where   (business_unit_id = @business_unit_id
             or     @business_unit_id is null)
            and     (agency_deal = @agency_deal
             or     @agency_deal is null)
            and     branch_code in (select branch_code from branch where country_code = @country_code)
            and     (media_product_id = @media_product_id or (@media_product_id is null and media_product_id in (select media_product_id from media_product where media = 'Y')))
            and     benchmark_end = @account_period
            and     finyear_end = @finyear

			update  #results
	        set     period_2 = @account_period,
	                bill_2 = @adjustment_amount,
	                prev_bill_2 = 0,
	                prev_date_2 = @prev_report_date,
	                manual_bill_2 = 0,
	                budget_bill_2 = 0,
	                previous_year_2 = 0,
	                final_previous_year_2 = 0,
					other_income_2 = 0
	        where   branch_code = @adj_branch_code
	        and     group_desc = @group_desc
	        and     sub_group_desc = @sub_group_desc
		end
    end /*fetch*/

	/*
    * Calculate Results 3
    */
	fetch period_csr into @account_period
	if(@@fetch_status = 0)
	begin
        select  @nett_billings = 0, @prev_bill = 0
        if @intra_day = 'I' /* intra day report */
        begin
            /* get projected billing amount for period and branch */
            select  @nett_billings   = isnull(sum(amount),0)
            from    #intra
            where   branch_code = @branch_code
            and     (business_unit_id = @business_unit_id
             or     @business_unit_id is null)
            and     (agency_deal = @agency_deal
             or     @agency_deal is null)
            and     (media_product_id = @media_product_id or (@media_product_id is null and media_product_id in (select media_product_id from media_product where media = 'Y')))
            and    benchmark_end = @account_period
            and     finyear_end = @finyear
        end
        else
        begin
        	select  @nett_billings   = isnull(sum(billings_month_03),0)
            from    projected_billings
            where   report_date = @report_date
            and     branch_code = @branch_code
            and     (business_unit_id = @business_unit_id
             or     @business_unit_id is null)
            and     (agency_deal = @agency_deal
             or     @agency_deal is null)
            and     (media_product_id = @media_product_id or (@media_product_id is null and media_product_id in (select media_product_id from media_product where media = 'Y')))
            and     finyear_end = @finyear
        end

		if @mode = '1'
		begin
	        if @intra_day = 'I' /* intra day report */
	        begin
	            select  @other_billings   = isnull(sum(amount),0)
	            from    #intra
	            where   branch_code = @branch_code
	            and     (business_unit_id = @business_unit_id
	             or     @business_unit_id is null)
	            and     (agency_deal = @agency_deal
	             or     @agency_deal is null)
	            and     (media_product_id = @media_product_id or (@media_product_id is null and media_product_id in (select media_product_id from media_product where media = 'N')))
	            and     benchmark_end = @account_period
	            and     finyear_end = @finyear
			end
			else
			begin
				select 	@other_billings = isnull(sum(billings_month_03),0)
				from 	projected_billings 
				where	report_date = @report_date
	            and     (business_unit_id = @business_unit_id
	             or     @business_unit_id is null)
	            and     (media_product_id = @media_product_id or (@media_product_id is null and media_product_id in (select media_product_id from media_product where media = 'N')))
	            and     finyear_end = @finyear
				and		branch_code in (select branch_code from branch where country_code = @country_code)
			end	
		end 

    	select  @prev_bill   = isnull(sum(billings_month_03),0)
        from    projected_billings
        where   report_date = @prev_report_date
        and     branch_code = @branch_code
        and     (business_unit_id = @business_unit_id
         or     @business_unit_id is null)
        and     (agency_deal = @agency_deal
         or     @agency_deal is null)
        and     (media_product_id = @media_product_id or (@media_product_id is null and media_product_id in (select media_product_id from media_product where media = 'Y')))
        and     finyear_end = @finyear

    	select  @prev_year_bill   = isnull(sum(billings_month_03),0)
        from    projected_billings
        where   report_date = @previous_year_run_date
        and     branch_code = @branch_code
        and     (business_unit_id = @business_unit_id
         or     @business_unit_id is null)
        and     (agency_deal = @agency_deal
         or     @agency_deal is null)
        and     (media_product_id = @media_product_id or (@media_product_id is null and media_product_id in (select media_product_id from media_product where media = 'Y')))
        and     finyear_end = @prev_year

    	select  @final_prev_year_bill   = isnull(sum(billings_month_03),0)
        from    projected_billings
        where   report_date = @final_year
        and     branch_code = @branch_code
        and     (business_unit_id = @business_unit_id
         or     @business_unit_id is null)
        and     (agency_deal = @agency_deal
         or     @agency_deal is null)
        and     (media_product_id = @media_product_id or (@media_product_id is null and media_product_id in (select media_product_id from media_product where media = 'Y')))
        and     finyear_end = @prev_year

        select  @manual_bill = 0, @budget_bill = 0
        select  @manual_bill = isnull(sum(film_manual_billings_total),0),
                @budget_bill = isnull(sum(film_billings_budget),0)
        from    monthly_billings
        where   billing_period = @account_period
        and     country_code = @country_code
        and     (budget_type = @business_unit_id
         or     @business_unit_id is null)
        and     (budget_type_id = @media_product_id or @media_product_id is null)


		update  #results
        set     period_3 = @account_period,
                bill_3 = @nett_billings,
                prev_bill_3 = @prev_bill,
                prev_date_3 = @prev_report_date,
                manual_bill_3 = @manual_bill,
                budget_bill_3 = @budget_bill,
                previous_year_3 = @prev_year_bill,
          final_previous_year_3 = @final_prev_year_bill,
				other_income_3 = @other_billings
        where   branch_code = @branch_code
        and     group_desc = @group_desc
        and     sub_group_desc = @sub_group_desc
        
		if (@@error !=0)
			goto error

		if @adjustments = 'Y'
		begin

            select  @adjustment_amount = isnull(sum(amount),0)
            from    #intra_adj
            where   (business_unit_id = @business_unit_id
             or     @business_unit_id is null)
            and     branch_code in (select branch_code from branch where country_code = @country_code)
            and     (agency_deal = @agency_deal
             or     @agency_deal is null)
            and     (media_product_id = @media_product_id or (@media_product_id is null and media_product_id in (select media_product_id from media_product where media = 'Y')))
            and     benchmark_end = @account_period
            and     finyear_end = @finyear

			update  #results
	        set     period_3 = @account_period,
	                bill_3 = @adjustment_amount,
	                prev_bill_3 = 0,
	                prev_date_3 = @prev_report_date,
	                manual_bill_3 = 0,
	                budget_bill_3 = 0,
	                previous_year_3 = 0,
	                final_previous_year_3 = 0,
					other_income_3 = 0
	        where   branch_code = @adj_branch_code
	        and     group_desc = @group_desc
	        and     sub_group_desc = @sub_group_desc
		end
    end /*fetch*/

	/*
    * Calculate Results 4
    */
	fetch period_csr into @account_period
	if(@@fetch_status = 0)
	begin
        select  @nett_billings = 0, @prev_bill = 0
        if @intra_day = 'I' /* intra day report */
        begin
            /* get projected billing amount for period and branch */
            select  @nett_billings   = isnull(sum(amount),0)
            from    #intra
            where   branch_code = @branch_code
            and     (business_unit_id = @business_unit_id
             or     @business_unit_id is null)
            and     (agency_deal = @agency_deal
             or     @agency_deal is null)
            and     (media_product_id = @media_product_id or (@media_product_id is null and media_product_id in (select media_product_id from media_product where media = 'Y')))
            and     benchmark_end = @account_period
            and     finyear_end = @finyear
        end
        else
        begin
        	select  @nett_billings   = isnull(sum(billings_month_04),0)
            from    projected_billings
            where   report_date = @report_date
            and     branch_code = @branch_code
            and     (business_unit_id = @business_unit_id
             or     @business_unit_id is null)
            and     (agency_deal = @agency_deal
             or     @agency_deal is null)
            and     (media_product_id = @media_product_id or (@media_product_id is null and media_product_id in (select media_product_id from media_product where media = 'Y')))
            and     finyear_end = @finyear
        end

		if @mode = '1'
		begin
	        if @intra_day = 'I' /* intra day report */
	        begin
	            select  @other_billings   = isnull(sum(amount),0)
	            from    #intra
	            where   branch_code = @branch_code
	            and     (business_unit_id = @business_unit_id
	             or     @business_unit_id is null)
	            and     (agency_deal = @agency_deal
	             or     @agency_deal is null)
	            and     (media_product_id = @media_product_id or (@media_product_id is null and media_product_id in (select media_product_id from media_product where media = 'N')))
	            and     benchmark_end = @account_period
	            and     finyear_end = @finyear
			end
			else
			begin
				select 	@other_billings = isnull(sum(billings_month_04),0)
				from 	projected_billings 
				where	report_date = @report_date
	            and     (business_unit_id = @business_unit_id
	             or     @business_unit_id is null)
	            and     (media_product_id = @media_product_id or (@media_product_id is null and media_product_id in (select media_product_id from media_product where media = 'N')))
	            and     finyear_end = @finyear
				and		branch_code in (select branch_code from branch where country_code = @country_code)
			end	
		end 

    	select  @prev_bill   = isnull(sum(billings_month_04),0)
        from    projected_billings
        where   report_date = @prev_report_date
        and     branch_code = @branch_code
        and     (business_unit_id = @business_unit_id
         or     @business_unit_id is null)
        and     (agency_deal = @agency_deal
         or     @agency_deal is null)
        and     (media_product_id = @media_product_id or (@media_product_id is null and media_product_id in (select media_product_id from media_product where media = 'Y')))
        and     finyear_end = @finyear

    	select  @prev_year_bill   = isnull(sum(billings_month_04),0)
        from    projected_billings
        where   report_date = @previous_year_run_date
        and     branch_code = @branch_code
        and     (business_unit_id = @business_unit_id
         or     @business_unit_id is null)
        and     (agency_deal = @agency_deal
         or     @agency_deal is null)
        and     (media_product_id = @media_product_id or (@media_product_id is null and media_product_id in (select media_product_id from media_product where media = 'Y')))
        and     finyear_end = @prev_year

    	select  @final_prev_year_bill   = isnull(sum(billings_month_04),0)
        from    projected_billings
        where   report_date = @final_year
        and     branch_code = @branch_code
        and     (business_unit_id = @business_unit_id
         or     @business_unit_id is null)
        and     (agency_deal = @agency_deal
         or     @agency_deal is null)
        and     (media_product_id = @media_product_id or (@media_product_id is null and media_product_id in (select media_product_id from media_product where media = 'Y')))
        and     finyear_end = @prev_year


        select  @manual_bill = 0, @budget_bill = 0
        select  @manual_bill = isnull(sum(film_manual_billings_total),0),
                @budget_bill = isnull(sum(film_billings_budget),0)
        from    monthly_billings
        where   billing_period = @account_period
        and     country_code = @country_code
        and     (budget_type = @business_unit_id
         or     @business_unit_id is null)
        and     (budget_type_id = @media_product_id or @media_product_id is null)

		update  #results
        set     period_4 = @account_period,
                bill_4 = @nett_billings,
                prev_bill_4 = @prev_bill,
                prev_date_4 = @prev_report_date,
                manual_bill_4 = @manual_bill,
                budget_bill_4 = @budget_bill,
                previous_year_4 = @prev_year_bill,
                final_previous_year_4 = @final_prev_year_bill,
				other_income_4 = @other_billings
        where   branch_code = @branch_code
        and     group_desc = @group_desc
        and     sub_group_desc = @sub_group_desc
        
		if (@@error !=0)
			goto error

		if @adjustments = 'Y'
		begin

            select  @adjustment_amount = isnull(sum(amount),0)
            from    #intra_adj
            where   (business_unit_id = @business_unit_id
             or     @business_unit_id is null)
            and     (agency_deal = @agency_deal
             or     @agency_deal is null)
            and     branch_code in (select branch_code from branch where country_code = @country_code)
            and     (media_product_id = @media_product_id or (@media_product_id is null and media_product_id in (select media_product_id from media_product where media = 'Y')))
            and     benchmark_end = @account_period
            and     finyear_end = @finyear

			update  #results
	        set     period_4 = @account_period,
	                bill_4 = @adjustment_amount,
	                prev_bill_4 = 0,
	                prev_date_4 = @prev_report_date,
	                manual_bill_4 = 0,
	                budget_bill_4 = 0,
	                previous_year_4 = 0,
	                final_previous_year_4 = 0,
					other_income_4 = 0
	        where   branch_code = @adj_branch_code
	        and     group_desc = @group_desc
	        and     sub_group_desc = @sub_group_desc
		end


    end /*fetch*/


	/*
    * Calculate Results 5
    */
	fetch period_csr into @account_period
	if(@@fetch_status = 0)
	begin
        select  @nett_billings = 0, @prev_bill = 0
        if @intra_day = 'I' /* intra day report */
        begin
            /* get projected billing amount for period and branch */
            select  @nett_billings   = isnull(sum(amount),0)
            from    #intra
            where   branch_code = @branch_code
            and     (business_unit_id = @business_unit_id
             or     @business_unit_id is null)
            and     (agency_deal = @agency_deal
             or     @agency_deal is null)
            and     (media_product_id = @media_product_id or (@media_product_id is null and media_product_id in (select media_product_id from media_product where media = 'Y')))
            and     benchmark_end = @account_period
            and     finyear_end = @finyear
        end
        else
        begin
        	select  @nett_billings   = isnull(sum(billings_month_05),0)
            from    projected_billings
            where   report_date = @report_date
            and     branch_code = @branch_code
            and     (business_unit_id = @business_unit_id
             or     @business_unit_id is null)
            and     (agency_deal = @agency_deal
             or     @agency_deal is null)
            and     (media_product_id = @media_product_id or (@media_product_id is null and media_product_id in (select media_product_id from media_product where media = 'Y')))
            and     finyear_end = @finyear
        end

		if @mode = '1'
		begin
	        if @intra_day = 'I' /* intra day report */
	        begin
	            select  @other_billings   = isnull(sum(amount),0)
	            from    #intra
	            where   branch_code = @branch_code
	            and     (business_unit_id = @business_unit_id
	             or     @business_unit_id is null)
	            and     (agency_deal = @agency_deal
	             or     @agency_deal is null)
	            and     (media_product_id = @media_product_id or (@media_product_id is null and media_product_id in (select media_product_id from media_product where media = 'N')))
	            and     benchmark_end = @account_period
	            and     finyear_end = @finyear
			end
			else
			begin
				select 	@other_billings = isnull(sum(billings_month_05),0)
				from 	projected_billings 
				where	report_date = @report_date
	            and     (business_unit_id = @business_unit_id
	             or     @business_unit_id is null)
	            and     (media_product_id = @media_product_id or (@media_product_id is null and media_product_id in (select media_product_id from media_product where media = 'N')))
	            and     finyear_end = @finyear
				and		branch_code in (select branch_code from branch where country_code = @country_code)
			end	
		end 

    	select  @prev_bill   = isnull(sum(billings_month_05),0)
        from    projected_billings
        where   report_date = @prev_report_date
        and     branch_code = @branch_code
        and     (business_unit_id = @business_unit_id
         or     @business_unit_id is null)
        and     (agency_deal = @agency_deal
         or     @agency_deal is null)
        and     (media_product_id = @media_product_id or (@media_product_id is null and media_product_id in (select media_product_id from media_product where media = 'Y')))
        and     finyear_end = @finyear

    	select  @prev_year_bill   = isnull(sum(billings_month_05),0)
        from    projected_billings
        where   report_date = @previous_year_run_date
        and     branch_code = @branch_code
        and     (business_unit_id = @business_unit_id
         or     @business_unit_id is null)
        and     (agency_deal = @agency_deal
         or     @agency_deal is null)
        and     (media_product_id = @media_product_id or (@media_product_id is null and media_product_id in (select media_product_id from media_product where media = 'Y')))
        and     finyear_end = @prev_year

    	select  @final_prev_year_bill   = isnull(sum(billings_month_05),0)
        from    projected_billings
        where   report_date = @final_year
        and     branch_code = @branch_code
        and     (business_unit_id = @business_unit_id
         or     @business_unit_id is null)
        and     (agency_deal = @agency_deal
         or     @agency_deal is null)
        and     (media_product_id = @media_product_id or (@media_product_id is null and media_product_id in (select media_product_id from media_product where media = 'Y')))
        and     finyear_end = @prev_year

        select  @manual_bill = 0, @budget_bill = 0
        select  @manual_bill = isnull(sum(film_manual_billings_total),0),
                @budget_bill = isnull(sum(film_billings_budget),0)
        from    monthly_billings
        where   billing_period = @account_period
        and     country_code = @country_code
        and     (budget_type = @business_unit_id
         or     @business_unit_id is null)
        and     (budget_type_id = @media_product_id or @media_product_id is null)

		update  #results
        set     period_5 = @account_period,
                bill_5 = @nett_billings,
                prev_bill_5 = @prev_bill,
                prev_date_5 = @prev_report_date,
                manual_bill_5 = @manual_bill,
                budget_bill_5 = @budget_bill,
                previous_year_5 = @prev_year_bill,
                final_previous_year_5 = @final_prev_year_bill,
				other_income_5 = @other_billings
        where   branch_code = @branch_code
        and     group_desc = @group_desc
        and     sub_group_desc = @sub_group_desc
        
		if (@@error !=0)
			goto error

		if @adjustments = 'Y'
		begin

            select  @adjustment_amount = isnull(sum(amount),0)
            from    #intra_adj
            where   (business_unit_id = @business_unit_id
             or     @business_unit_id is null)
            and     branch_code in (select branch_code from branch where country_code = @country_code)
            and     (agency_deal = @agency_deal
             or     @agency_deal is null)
            and     (media_product_id = @media_product_id or (@media_product_id is null and media_product_id in (select media_product_id from media_product where media = 'Y')))
            and     benchmark_end = @account_period
            and     finyear_end = @finyear

			update  #results
	        set     period_5 = @account_period,
	                bill_5 = @adjustment_amount,
	                prev_bill_5 = 0,
	                prev_date_5 = @prev_report_date,
	                manual_bill_5 = 0,
	                budget_bill_5 = 0,
	                previous_year_5 = 0,
	                final_previous_year_5 = 0,
					other_income_5 = 0
	        where   branch_code = @adj_branch_code
	        and     group_desc = @group_desc
	        and     sub_group_desc = @sub_group_desc
		end


    end /*fetch*/

	/*
    * Calculate Results 6
    */
	fetch period_csr into @account_period
	if(@@fetch_status = 0)
	begin
        select  @nett_billings = 0, @prev_bill = 0
        if @intra_day = 'I' /* intra day report */
        begin
            /* get projected billing amount for period and branch */
            select  @nett_billings   = isnull(sum(amount),0)
            from    #intra
            where   branch_code = @branch_code
            and     (business_unit_id = @business_unit_id
             or     @business_unit_id is null)
            and     branch_code = @branch_code
            and     (agency_deal = @agency_deal
             or     @agency_deal is null)
            and     (media_product_id = @media_product_id or (@media_product_id is null and media_product_id in (select media_product_id from media_product where media = 'Y')))
            and     benchmark_end = @account_period
            and     finyear_end = @finyear
        end
        else
        begin
        	select  @nett_billings   = isnull(sum(billings_month_06),0)
            from    projected_billings
            where   report_date = @report_date
            and     branch_code = @branch_code
            and     (business_unit_id = @business_unit_id
             or     @business_unit_id is null)
            and     (agency_deal = @agency_deal
             or     @agency_deal is null)
            and     (media_product_id = @media_product_id or (@media_product_id is null and media_product_id in (select media_product_id from media_product where media = 'Y')))
            and     finyear_end = @finyear
        end

		if @mode = '1'
		begin
	        if @intra_day = 'I' /* intra day report */
	        begin
	            select  @other_billings   = isnull(sum(amount),0)
	            from    #intra
	            where   branch_code = @branch_code
	            and     (business_unit_id = @business_unit_id
	             or     @business_unit_id is null)
	            and     (agency_deal = @agency_deal
	             or     @agency_deal is null)
	            and     (media_product_id = @media_product_id or (@media_product_id is null and media_product_id in (select media_product_id from media_product where media = 'N')))
	            and     benchmark_end = @account_period
	            and     finyear_end = @finyear
			end
			else
			begin
				select 	@other_billings = isnull(sum(billings_month_06),0)
				from 	projected_billings 
				where	report_date = @report_date
	            and     (business_unit_id = @business_unit_id
	             or     @business_unit_id is null)
	            and     (media_product_id = @media_product_id or (@media_product_id is null and media_product_id in (select media_product_id from media_product where media = 'N')))
	            and     finyear_end = @finyear
				and		branch_code in (select branch_code from branch where country_code = @country_code)
			end	
		end 

    	select  @prev_bill   = isnull(sum(billings_month_06),0)
        from    projected_billings
        where   report_date = @prev_report_date
        and     branch_code = @branch_code
        and     (business_unit_id = @business_unit_id
         or     @business_unit_id is null)
        and     (agency_deal = @agency_deal
         or     @agency_deal is null)
        and     (media_product_id = @media_product_id or (@media_product_id is null and media_product_id in (select media_product_id from media_product where media = 'Y')))
        and     finyear_end = @finyear

    	select  @prev_year_bill   = isnull(sum(billings_month_06),0)
        from    projected_billings
        where   report_date = @previous_year_run_date
        and     branch_code = @branch_code
        and     (business_unit_id = @business_unit_id
         or     @business_unit_id is null)
        and     (agency_deal = @agency_deal
         or     @agency_deal is null)
        and     (media_product_id = @media_product_id or (@media_product_id is null and media_product_id in (select media_product_id from media_product where media = 'Y')))
        and     finyear_end = @prev_year

    	select  @final_prev_year_bill   = isnull(sum(billings_month_06),0)
        from    projected_billings
        where   report_date = @final_year
        and     branch_code = @branch_code
        and     (business_unit_id = @business_unit_id
         or     @business_unit_id is null)
        and     (agency_deal = @agency_deal
         or     @agency_deal is null)
        and     (media_product_id = @media_product_id or (@media_product_id is null and media_product_id in (select media_product_id from media_product where media = 'Y')))
        and     finyear_end = @prev_year

        select  @manual_bill = 0, @budget_bill = 0
        select  @manual_bill = isnull(sum(film_manual_billings_total),0),
                @budget_bill = isnull(sum(film_billings_budget),0)
        from    monthly_billings
        where   billing_period = @account_period
        and     country_code = @country_code
        and     (budget_type = @business_unit_id
         or     @business_unit_id is null)
        and     (budget_type_id = @media_product_id or @media_product_id is null)

--        exec @errorode = p_calendar_month_end	@account_period,
--									  		@end_of_month_date OUTPUT
    

		update  #results
        set     period_6 = @account_period,
                bill_6 = @nett_billings,
                prev_bill_6 = @prev_bill,
                prev_date_6 = @prev_report_date,
                manual_bill_6 = @manual_bill,
                budget_bill_6 = @budget_bill,
                previous_year_6 = @prev_year_bill,
                final_previous_year_6 = @final_prev_year_bill,
				other_income_6 = @other_billings
        where   branch_code = @branch_code
        and     group_desc = @group_desc
        and     sub_group_desc = @sub_group_desc

		if (@@error !=0)
			goto error

		if @adjustments = 'Y'
		begin

            select  @adjustment_amount = isnull(sum(amount),0)
            from    #intra_adj
            where   (business_unit_id = @business_unit_id
             or     @business_unit_id is null)
            and     branch_code in (select branch_code from branch where country_code = @country_code)
            and     (agency_deal = @agency_deal
             or     @agency_deal is null)
            and     (media_product_id = @media_product_id or (@media_product_id is null and media_product_id in (select media_product_id from media_product where media = 'Y')))
            and     benchmark_end = @account_period
            and     finyear_end = @finyear

			update  #results
	        set     period_6 = @account_period,
	                bill_6 = @adjustment_amount,
	                prev_bill_6 = 0,
	                prev_date_6 = @prev_report_date,
	                manual_bill_6 = 0,
	                budget_bill_6 = 0,
	                previous_year_6 = 0,
	                final_previous_year_6 = 0,
					other_income_6 = 0
	        where   branch_code = @adj_branch_code
	        and     group_desc = @group_desc
	        and     sub_group_desc = @sub_group_desc
		end

    end /*fetch*/

	/*
    * Calculate Results 7
    */
	fetch period_csr into @account_period
	if(@@fetch_status = 0)
	begin
        select  @nett_billings = 0, @prev_bill = 0
        if @intra_day = 'I' /* intra day report */
        begin
            /* get projected billing amount for period and branch */
            select  @nett_billings   = isnull(sum(amount),0)
            from    #intra
            where   branch_code = @branch_code
            and     (business_unit_id = @business_unit_id
             or     @business_unit_id is null)
            and     (agency_deal = @agency_deal
             or     @agency_deal is null)
            and     (media_product_id = @media_product_id or (@media_product_id is null and media_product_id in (select media_product_id from media_product where media = 'Y')))
            and     benchmark_end = @account_period
            and     finyear_end = @finyear
        end
        else
        begin
        	select  @nett_billings   = isnull(sum(billings_month_07),0)
            from    projected_billings
            where   report_date = @report_date
            and     branch_code = @branch_code
            and     (business_unit_id = @business_unit_id
             or     @business_unit_id is null)
            and     (agency_deal = @agency_deal
             or     @agency_deal is null)
            and     (media_product_id = @media_product_id or (@media_product_id is null and media_product_id in (select media_product_id from media_product where media = 'Y')))
            and     finyear_end = @finyear
        end

		if @mode = '1'
		begin
	        if @intra_day = 'I' /* intra day report */
	        begin
	            select  @other_billings   = isnull(sum(amount),0)
	            from    #intra
	            where   branch_code = @branch_code
	            and     (business_unit_id = @business_unit_id
	             or     @business_unit_id is null)
	            and     (agency_deal = @agency_deal
	             or     @agency_deal is null)
	            and     (media_product_id = @media_product_id or (@media_product_id is null and media_product_id in (select media_product_id from media_product where media = 'N')))
	            and     benchmark_end = @account_period
	            and     finyear_end = @finyear
			end
			else
			begin
				select 	@other_billings = isnull(sum(billings_month_07),0)
				from 	projected_billings 
				where	report_date = @report_date
	            and     (business_unit_id = @business_unit_id
	             or     @business_unit_id is null)
	            and     (media_product_id = @media_product_id or (@media_product_id is null and media_product_id in (select media_product_id from media_product where media = 'N')))
	            and     finyear_end = @finyear
				and		branch_code in (select branch_code from branch where country_code = @country_code)
			end	
		end 

    	select  @prev_bill   = isnull(sum(billings_month_07),0)
        from    projected_billings
        where   report_date = @prev_report_date
        and     branch_code = @branch_code
        and     (business_unit_id = @business_unit_id
         or     @business_unit_id is null)
        and     (agency_deal = @agency_deal
         or     @agency_deal is null)
        and     (media_product_id = @media_product_id or (@media_product_id is null and media_product_id in (select media_product_id from media_product where media = 'Y')))
        and     finyear_end = @finyear

    	select  @prev_year_bill   = isnull(sum(billings_month_07),0)
        from    projected_billings
        where   report_date = @previous_year_run_date
        and     branch_code = @branch_code
        and     (business_unit_id = @business_unit_id
         or     @business_unit_id is null)
        and     (agency_deal = @agency_deal
         or     @agency_deal is null)
        and     (media_product_id = @media_product_id or (@media_product_id is null and media_product_id in (select media_product_id from media_product where media = 'Y')))
        and     finyear_end = @prev_year

    	select  @final_prev_year_bill   = isnull(sum(billings_month_07),0)
        from    projected_billings
        where   report_date = @final_year
        and     branch_code = @branch_code
        and     (business_unit_id = @business_unit_id
         or     @business_unit_id is null)
        and     (agency_deal = @agency_deal
         or     @agency_deal is null)
        and     (media_product_id = @media_product_id or (@media_product_id is null and media_product_id in (select media_product_id from media_product where media = 'Y')))
        and     finyear_end = @prev_year

        select  @manual_bill = 0, @budget_bill = 0
        select  @manual_bill = isnull(sum(film_manual_billings_total),0),
                @budget_bill = isnull(sum(film_billings_budget),0)
        from    monthly_billings
        where   billing_period = @account_period
        and     country_code = @country_code
        and     (budget_type = @business_unit_id
         or     @business_unit_id is null)
        and     (budget_type_id = @media_product_id or @media_product_id is null)

		update  #results
        set     period_7 = @account_period,
                bill_7 = @nett_billings,
                prev_bill_7 = @prev_bill,
                prev_date_7 = @prev_report_date,
                manual_bill_7 = @manual_bill,
                budget_bill_7 = @budget_bill,
                previous_year_7 = @prev_year_bill,
                final_previous_year_7 = @final_prev_year_bill,
				other_income_7 = @other_billings
        where   branch_code = @branch_code
        and     group_desc = @group_desc
        and     sub_group_desc = @sub_group_desc
       
		if (@@error !=0)
			goto error

		if @adjustments = 'Y'
		begin

            select  @adjustment_amount = isnull(sum(amount),0)
            from    #intra_adj
            where   (business_unit_id = @business_unit_id
             or     @business_unit_id is null)
            and     (agency_deal = @agency_deal
             or     @agency_deal is null)
            and     branch_code in (select branch_code from branch where country_code = @country_code)
            and     (media_product_id = @media_product_id or (@media_product_id is null and media_product_id in (select media_product_id from media_product where media = 'Y')))
            and     benchmark_end = @account_period
            and     finyear_end = @finyear

			update  #results
	        set     period_7 = @account_period,
	                bill_7 = @adjustment_amount,
	                prev_bill_7 = 0,
	                prev_date_7 = @prev_report_date,
	                manual_bill_7 = 0,
	                budget_bill_7 = 0,
	                previous_year_7 = 0,
	                final_previous_year_7 = 0,
					other_income_7 = 0
	        where   branch_code = @adj_branch_code
	        and     group_desc = @group_desc
	        and     sub_group_desc = @sub_group_desc
		end

    end /*fetch*/

	/*
    * Calculate Results 8
    */
	fetch period_csr into @account_period
	if(@@fetch_status = 0)
	begin
        select  @nett_billings = 0, @prev_bill = 0
        if @intra_day = 'I' /* intra day report */
        begin
            /* get projected billing amount for period and branch */
            select  @nett_billings   = isnull(sum(amount),0)
            from    #intra
            where   branch_code = @branch_code
            and     (business_unit_id = @business_unit_id
             or     @business_unit_id is null)
            and     (agency_deal = @agency_deal
             or     @agency_deal is null)
            and     (media_product_id = @media_product_id or (@media_product_id is null and media_product_id in (select media_product_id from media_product where media = 'Y')))
            and     benchmark_end = @account_period
            and     finyear_end = @finyear
        end
        else
        begin
        	select  @nett_billings   = isnull(sum(billings_month_08),0)
            from    projected_billings
            where   report_date = @report_date
            and     branch_code = @branch_code
            and     (business_unit_id = @business_unit_id
             or     @business_unit_id is null)
            and     (agency_deal = @agency_deal
             or     @agency_deal is null)
            and     (media_product_id = @media_product_id or (@media_product_id is null and media_product_id in (select media_product_id from media_product where media = 'Y')))
            and     finyear_end = @finyear
        end

		if @mode = '1'
		begin
	        if @intra_day = 'I' /* intra day report */
	        begin
	            select  @other_billings   = isnull(sum(amount),0)
	            from    #intra
	            where   branch_code = @branch_code
	            and     (business_unit_id = @business_unit_id
	             or     @business_unit_id is null)
	            and     (agency_deal = @agency_deal
	             or     @agency_deal is null)
	            and     (media_product_id = @media_product_id or (@media_product_id is null and media_product_id in (select media_product_id from media_product where media = 'N')))
	            and     benchmark_end = @account_period
	            and     finyear_end = @finyear
			end
			else
			begin
				select 	@other_billings = isnull(sum(billings_month_08),0)
				from 	projected_billings 
				where	report_date = @report_date
	            and     (business_unit_id = @business_unit_id
	             or     @business_unit_id is null)
	            and     (media_product_id = @media_product_id or (@media_product_id is null and media_product_id in (select media_product_id from media_product where media = 'N')))
	            and     finyear_end = @finyear
				and		branch_code in (select branch_code from branch where country_code = @country_code)
			end	
		end 

    	select  @prev_bill   = isnull(sum(billings_month_08),0)
        from    projected_billings
        where   report_date = @prev_report_date
        and     branch_code = @branch_code
        and     (business_unit_id = @business_unit_id
         or     @business_unit_id is null)
        and     (agency_deal = @agency_deal
         or     @agency_deal is null)
        and     (media_product_id = @media_product_id or (@media_product_id is null and media_product_id in (select media_product_id from media_product where media = 'Y')))
        and     finyear_end = @finyear

    	select  @prev_year_bill   = isnull(sum(billings_month_08),0)
        from    projected_billings
        where   report_date = @previous_year_run_date
        and     branch_code = @branch_code
        and     (business_unit_id = @business_unit_id
         or     @business_unit_id is null)
        and     (agency_deal = @agency_deal
         or     @agency_deal is null)
        and     (media_product_id = @media_product_id or (@media_product_id is null and media_product_id in (select media_product_id from media_product where media = 'Y')))
        and     finyear_end = @prev_year

    	select  @final_prev_year_bill   = isnull(sum(billings_month_08),0)
        from    projected_billings
        where   report_date = @final_year
        and     branch_code = @branch_code
        and     (business_unit_id = @business_unit_id
         or     @business_unit_id is null)
        and     (agency_deal = @agency_deal
         or     @agency_deal is null)
        and     (media_product_id = @media_product_id or (@media_product_id is null and media_product_id in (select media_product_id from media_product where media = 'Y')))
        and     finyear_end = @prev_year

        select  @manual_bill = 0, @budget_bill = 0
        select  @manual_bill = isnull(sum(film_manual_billings_total),0),
                @budget_bill = isnull(sum(film_billings_budget),0)
        from    monthly_billings
        where   billing_period = @account_period
        and     country_code = @country_code
        and     (budget_type = @business_unit_id
         or     @business_unit_id is null)
        and     (budget_type_id = @media_product_id or @media_product_id is null)

		update  #results
        set     period_8 = @account_period,
                bill_8 = @nett_billings,
                prev_bill_8 = @prev_bill,
                prev_date_8 = @prev_report_date,
                manual_bill_8 = @manual_bill,
                budget_bill_8 = @budget_bill,
                previous_year_8 = @prev_year_bill,
                final_previous_year_8 = @final_prev_year_bill,
				other_income_8 = @other_billings
        where   branch_code = @branch_code
        and     group_desc = @group_desc
        and     sub_group_desc = @sub_group_desc

   		if (@@error !=0)
			goto error

		if @adjustments = 'Y'
		begin

            select  @adjustment_amount = isnull(sum(amount),0)
            from    #intra_adj
            where   (business_unit_id = @business_unit_id
             or     @business_unit_id is null)
          and     (agency_deal = @agency_deal
             or     @agency_deal is null)
            and     branch_code in (select branch_code from branch where country_code = @country_code)
            and     (media_product_id = @media_product_id or (@media_product_id is null and media_product_id in (select media_product_id from media_product where media = 'Y')))
            and     benchmark_end = @account_period
            and     finyear_end = @finyear

			update  #results
	        set     period_8 = @account_period,
	                bill_8 = @adjustment_amount,
	                prev_bill_8 = 0,
	                prev_date_8 = @prev_report_date,
	                manual_bill_8 = 0,
	                budget_bill_8 = 0,
	                previous_year_8 = 0,
	                final_previous_year_8 = 0,
					other_income_8 = 0
	        where   branch_code = @adj_branch_code
	        and     group_desc = @group_desc
	        and     sub_group_desc = @sub_group_desc
		end

    end /*fetch*/

	/*
    * Calculate Results 9
    */
	fetch period_csr into @account_period
	if(@@fetch_status = 0)
	begin
        select  @nett_billings = 0, @prev_bill = 0
        if @intra_day = 'I' /* intra day report */
        begin
            /* get projected billing amount for period and branch */
            select  @nett_billings   = isnull(sum(amount),0)
            from    #intra
            where   branch_code = @branch_code
            and     (business_unit_id = @business_unit_id
             or     @business_unit_id is null)
            and     (agency_deal = @agency_deal
             or     @agency_deal is null)
            and     (media_product_id = @media_product_id or (@media_product_id is null and media_product_id in (select media_product_id from media_product where media = 'Y')))
            and     benchmark_end = @account_period
            and     finyear_end = @finyear
        end
        else
        begin
        	select  @nett_billings   = isnull(sum(billings_month_09),0)
            from    projected_billings
            where   report_date = @report_date
            and     branch_code = @branch_code
            and     (business_unit_id = @business_unit_id
             or     @business_unit_id is null)
            and     (agency_deal = @agency_deal
             or     @agency_deal is null)
            and     (media_product_id = @media_product_id or (@media_product_id is null and media_product_id in (select media_product_id from media_product where media = 'Y')))
            and     finyear_end = @finyear
        end

		if @mode = '1'
		begin
	        if @intra_day = 'I' /* intra day report */
	        begin
	            select  @other_billings   = isnull(sum(amount),0)
	            from    #intra
	            where   branch_code = @branch_code
	            and     (business_unit_id = @business_unit_id
	             or     @business_unit_id is null)
	            and     (agency_deal = @agency_deal
	             or     @agency_deal is null)
	            and     (media_product_id = @media_product_id or (@media_product_id is null and media_product_id in (select media_product_id from media_product where media = 'N')))
	            and     benchmark_end = @account_period
	            and     finyear_end = @finyear
			end
			else
			begin
				select 	@other_billings = isnull(sum(billings_month_09),0)
				from 	projected_billings 
				where	report_date = @report_date
	            and     (business_unit_id = @business_unit_id
	             or     @business_unit_id is null)
	            and     (media_product_id = @media_product_id or (@media_product_id is null and media_product_id in (select media_product_id from media_product where media = 'N')))
	            and     finyear_end = @finyear
				and		branch_code in (select branch_code from branch where country_code = @country_code)
			end	
		end 

    	select  @prev_bill   = isnull(sum(billings_month_09),0)
        from    projected_billings
        where   report_date = @prev_report_date
        and     branch_code = @branch_code
        and     (business_unit_id = @business_unit_id
         or     @business_unit_id is null)
        and     (agency_deal = @agency_deal
         or     @agency_deal is null)
        and     (media_product_id = @media_product_id or (@media_product_id is null and media_product_id in (select media_product_id from media_product where media = 'Y')))
        and     finyear_end = @finyear

    	select  @prev_year_bill   = isnull(sum(billings_month_09),0)
        from    projected_billings
        where   report_date = @previous_year_run_date
        and     branch_code = @branch_code
        and     (business_unit_id = @business_unit_id
         or     @business_unit_id is null)
        and     (agency_deal = @agency_deal
         or     @agency_deal is null)
        and     (media_product_id = @media_product_id or (@media_product_id is null and media_product_id in (select media_product_id from media_product where media = 'Y')))
        and     finyear_end = @prev_year

    	select  @final_prev_year_bill   = isnull(sum(billings_month_09),0)
        from    projected_billings
        where   report_date = @final_year
        and     branch_code = @branch_code
        and     (business_unit_id = @business_unit_id
         or     @business_unit_id is null)
        and     (agency_deal = @agency_deal
         or     @agency_deal is null)
        and     (media_product_id = @media_product_id or (@media_product_id is null and media_product_id in (select media_product_id from media_product where media = 'Y')))
        and     finyear_end = @prev_year

        select  @manual_bill = 0, @budget_bill = 0
        select  @manual_bill = isnull(sum(film_manual_billings_total),0),
                @budget_bill = isnull(sum(film_billings_budget),0)
        from    monthly_billings
        where   billing_period = @account_period
        and     country_code = @country_code
        and     (budget_type = @business_unit_id
         or     @business_unit_id is null)
        and     (budget_type_id = @media_product_id or @media_product_id is null)

		update  #results
        set     period_9 = @account_period,
                bill_9 = @nett_billings,
                prev_bill_9 = @prev_bill,
                prev_date_9 = @prev_report_date,
                manual_bill_9 = @manual_bill,
                budget_bill_9 = @budget_bill,
                previous_year_9 = @prev_year_bill,
                final_previous_year_9 = @final_prev_year_bill,
				other_income_9 = @other_billings
        where   branch_code = @branch_code
        and     group_desc = @group_desc
        and     sub_group_desc = @sub_group_desc
		if (@@error !=0)
			goto error

		if @adjustments = 'Y'
		begin

            select  @adjustment_amount = isnull(sum(amount),0)
            from    #intra_adj
            where   (business_unit_id = @business_unit_id
             or     @business_unit_id is null)
            and     (agency_deal = @agency_deal
             or     @agency_deal is null)
            and     branch_code in (select branch_code from branch where country_code = @country_code)
            and     (media_product_id = @media_product_id or (@media_product_id is null and media_product_id in (select media_product_id from media_product where media = 'Y')))
            and     benchmark_end = @account_period
            and     finyear_end = @finyear

			update  #results
	        set     period_9 = @account_period,
	                bill_9 = @adjustment_amount,
	                prev_bill_9 = 0,
	                prev_date_9 = @prev_report_date,
	                manual_bill_9 = 0,
	                budget_bill_9 = 0,
	                previous_year_9 = 0,
	                final_previous_year_9 = 0,
					other_income_9 = 0
	        where   branch_code = @adj_branch_code
	        and     group_desc = @group_desc
	        and     sub_group_desc = @sub_group_desc
		end

    end /*fetch*/

	/*
    * Calculate Results 10
    */
	fetch period_csr into @account_period
	if(@@fetch_status = 0)
	begin
        select  @nett_billings = 0, @prev_bill = 0
        if @intra_day = 'I' /* intra day report */
        begin
            /* get projected billing amount for period and branch */
            select  @nett_billings   = isnull(sum(amount),0)
            from    #intra
            where   branch_code = @branch_code
            and     (business_unit_id = @business_unit_id
             or     @business_unit_id is null)
            and     (agency_deal = @agency_deal
             or     @agency_deal is null)
            and     (media_product_id = @media_product_id or (@media_product_id is null and media_product_id in (select media_product_id from media_product where media = 'Y')))
            and     benchmark_end = @account_period
            and     finyear_end = @finyear
        end
        else
        begin
        	select  @nett_billings   = isnull(sum(billings_month_10),0)
            from    projected_billings
            where   report_date = @report_date
            and     branch_code = @branch_code
            and     (business_unit_id = @business_unit_id
             or     @business_unit_id is null)
            and     (agency_deal = @agency_deal
             or     @agency_deal is null)
            and     (media_product_id = @media_product_id or (@media_product_id is null and media_product_id in (select media_product_id from media_product where media = 'Y')))
            and     finyear_end = @finyear
        end

		if @mode = '1'
		begin
	        if @intra_day = 'I' /* intra day report */
	        begin
	            select  @other_billings   = isnull(sum(amount),0)
	            from    #intra
	            where   branch_code = @branch_code
	            and     (business_unit_id = @business_unit_id
	             or     @business_unit_id is null)
	            and     (agency_deal = @agency_deal
	             or     @agency_deal is null)
	            and     (media_product_id = @media_product_id or (@media_product_id is null and media_product_id in (select media_product_id from media_product where media = 'N')))
	            and     benchmark_end = @account_period
	            and     finyear_end = @finyear
			end
			else
			begin
				select 	@other_billings = isnull(sum(billings_month_10),0)
				from 	projected_billings 
				where	report_date = @report_date
	            and     (business_unit_id = @business_unit_id
	             or     @business_unit_id is null)
	            and     (media_product_id = @media_product_id or (@media_product_id is null and media_product_id in (select media_product_id from media_product where media = 'N')))
	            and     finyear_end = @finyear
				and		branch_code in (select branch_code from branch where country_code = @country_code)
			end	
		end 

    	select  @prev_bill   = isnull(sum(billings_month_10),0)
        from    projected_billings
        where   report_date = @prev_report_date
        and     branch_code = @branch_code
        and     (business_unit_id = @business_unit_id
         or     @business_unit_id is null)
        and     (agency_deal = @agency_deal
         or     @agency_deal is null)
        and     (media_product_id = @media_product_id or (@media_product_id is null and media_product_id in (select media_product_id from media_product where media = 'Y')))
        and     finyear_end = @finyear

    	select  @prev_year_bill   = isnull(sum(billings_month_10),0)
        from    projected_billings
        where   report_date = @previous_year_run_date
        and     branch_code = @branch_code
        and     (business_unit_id = @business_unit_id
         or     @business_unit_id is null)
        and     (agency_deal = @agency_deal
         or     @agency_deal is null)
        and     (media_product_id = @media_product_id or (@media_product_id is null and media_product_id in (select media_product_id from media_product where media = 'Y')))
        and     finyear_end = @prev_year

    	select  @final_prev_year_bill   = isnull(sum(billings_month_10),0)
        from    projected_billings
        where   report_date = @final_year
        and     branch_code = @branch_code
        and     (business_unit_id = @business_unit_id
         or     @business_unit_id is null)
        and     (agency_deal = @agency_deal
         or     @agency_deal is null)
        and     (media_product_id = @media_product_id or (@media_product_id is null and media_product_id in (select media_product_id from media_product where media = 'Y')))
        and     finyear_end = @prev_year

        select  @manual_bill = 0, @budget_bill = 0
        select  @manual_bill = isnull(sum(film_manual_billings_total),0),
                @budget_bill = isnull(sum(film_billings_budget),0)
        from    monthly_billings
        where   billing_period = @account_period
        and     country_code = @country_code
        and     (budget_type = @business_unit_id
         or     @business_unit_id is null)
        and     (budget_type_id = @media_product_id or @media_product_id is null)

		update  #results
        set     period_10 = @account_period,
                bill_10 = @nett_billings,
                prev_bill_10 = @prev_bill,
                prev_date_10 = @prev_report_date,
                manual_bill_10 = @manual_bill,
                budget_bill_10 = @budget_bill,
                previous_year_10 = @prev_year_bill,
                final_previous_year_10 = @final_prev_year_bill,
				other_income_10 = @other_billings
        where   branch_code = @branch_code
        and     group_desc = @group_desc
        and     sub_group_desc = @sub_group_desc
		if (@@error !=0)
			goto error

		if @adjustments = 'Y'
		begin

            select  @adjustment_amount = isnull(sum(amount),0)
            from    #intra_adj
            where   (business_unit_id = @business_unit_id
             or     @business_unit_id is null)
            and     (agency_deal = @agency_deal
             or     @agency_deal is null)
            and     branch_code in (select branch_code from branch where country_code = @country_code)
            and     (media_product_id = @media_product_id or (@media_product_id is null and media_product_id in (select media_product_id from media_product where media = 'Y')))
            and     benchmark_end = @account_period
            and     finyear_end = @finyear

			update  #results
	        set     period_10 = @account_period,
	                bill_10 = @adjustment_amount,
	                prev_bill_10 = 0,
	                prev_date_10 = @prev_report_date,
	                manual_bill_10 = 0,
	                budget_bill_10 = 0,
	                previous_year_10 = 0,
	                final_previous_year_10 = 0,
					other_income_10 = 0
	        where   branch_code = @adj_branch_code
	        and     group_desc = @group_desc
	        and     sub_group_desc = @sub_group_desc
		end

    end /*fetch*/

	/*
    * Calculate Results 11
    */
	fetch period_csr into @account_period
	if(@@fetch_status = 0)
	begin
        select  @nett_billings = 0, @prev_bill = 0
        if @intra_day = 'I' /* intra day report */
        begin
            /* get projected billing amount for period and branch */
            select  @nett_billings   = isnull(sum(amount),0)
            from    #intra
            where   branch_code = @branch_code
            and     (business_unit_id = @business_unit_id
             or     @business_unit_id is null)
            and     (agency_deal = @agency_deal
             or     @agency_deal is null)
            and     (media_product_id = @media_product_id or (@media_product_id is null and media_product_id in (select media_product_id from media_product where media = 'Y')))
            and     benchmark_end = @account_period
            and     finyear_end = @finyear
        end
        else
        begin
        	select  @nett_billings   = isnull(sum(billings_month_11),0)
            from    projected_billings
            where   report_date = @report_date
            and     branch_code = @branch_code
            and     (business_unit_id = @business_unit_id
             or     @business_unit_id is null)
            and     (agency_deal = @agency_deal
             or     @agency_deal is null)
            and     (media_product_id = @media_product_id or (@media_product_id is null and media_product_id in (select media_product_id from media_product where media = 'Y')))
            and     finyear_end = @finyear
        end

		if @mode = '1'
		begin
	        if @intra_day = 'I' /* intra day report */
	        begin
	            select  @other_billings   = isnull(sum(amount),0)
	            from    #intra
	            where   branch_code = @branch_code
	            and     (business_unit_id = @business_unit_id
	             or     @business_unit_id is null)
	            and     (agency_deal = @agency_deal
	             or     @agency_deal is null)
	            and     (media_product_id = @media_product_id or (@media_product_id is null and media_product_id in (select media_product_id from media_product where media = 'N')))
	            and     benchmark_end = @account_period
	            and     finyear_end = @finyear
			end
			else
			begin
				select 	@other_billings = isnull(sum(billings_month_11),0)
				from 	projected_billings 
				where	report_date = @report_date
	            and     (business_unit_id = @business_unit_id
	             or     @business_unit_id is null)
	            and     (media_product_id = @media_product_id or (@media_product_id is null and media_product_id in (select media_product_id from media_product where media = 'N')))
	            and     finyear_end = @finyear
				and		branch_code in (select branch_code from branch where country_code = @country_code)
			end	
		end 

    	select  @prev_bill   = isnull(sum(billings_month_11),0)
        from    projected_billings
        where   report_date = @prev_report_date
        and     branch_code = @branch_code
        and     (business_unit_id = @business_unit_id
         or     @business_unit_id is null)
        and     (agency_deal = @agency_deal
   or     @agency_deal is null)
        and     (media_product_id = @media_product_id or (@media_product_id is null and media_product_id in (select media_product_id from media_product where media = 'Y')))
        and     finyear_end = @finyear

    	select  @prev_year_bill   = isnull(sum(billings_month_11),0)
        from    projected_billings
        where   report_date = @previous_year_run_date
        and     branch_code = @branch_code
        and     (business_unit_id = @business_unit_id
         or     @business_unit_id is null)
        and     (agency_deal = @agency_deal
         or     @agency_deal is null)
        and     (media_product_id = @media_product_id or (@media_product_id is null and media_product_id in (select media_product_id from media_product where media = 'Y')))
        and     finyear_end = @prev_year

    	select  @final_prev_year_bill   = isnull(sum(billings_month_11),0)
        from    projected_billings
        where   report_date = @final_year
        and     branch_code = @branch_code
        and     (business_unit_id = @business_unit_id
         or     @business_unit_id is null)
        and     (agency_deal = @agency_deal
         or     @agency_deal is null)
        and     (media_product_id = @media_product_id or (@media_product_id is null and media_product_id in (select media_product_id from media_product where media = 'Y')))
        and     finyear_end = @prev_year

        select  @manual_bill = 0, @budget_bill = 0
        select  @manual_bill = isnull(sum(film_manual_billings_total),0),
                @budget_bill = isnull(sum(film_billings_budget),0)
        from    monthly_billings
        where   billing_period = @account_period
        and     country_code = @country_code
        and     (budget_type = @business_unit_id
         or     @business_unit_id is null)
        and     (budget_type_id = @media_product_id or @media_product_id is null)

		update  #results
        set     period_11 = @account_period,
                bill_11 = @nett_billings,
                prev_bill_11 = @prev_bill,
                prev_date_11 = @prev_report_date,
                manual_bill_11 = @manual_bill,
                budget_bill_11 = @budget_bill,
                previous_year_11 = @prev_year_bill,
                final_previous_year_11 = @final_prev_year_bill,
				other_income_11 = @other_billings
        where   branch_code = @branch_code
        and     sub_group_desc = @sub_group_desc
        and     group_desc = @group_desc
		if (@@error !=0)
			goto error

		if @adjustments = 'Y'
		begin

            select  @adjustment_amount = isnull(sum(amount),0)
            from    #intra_adj
            where   (business_unit_id = @business_unit_id
             or     @business_unit_id is null)
            and     (agency_deal = @agency_deal
             or     @agency_deal is null)
            and     branch_code in (select branch_code from branch where country_code = @country_code)
            and     (media_product_id = @media_product_id or (@media_product_id is null and media_product_id in (select media_product_id from media_product where media = 'Y')))
            and     benchmark_end = @account_period
            and     finyear_end = @finyear

			update  #results
	        set     period_11 = @account_period,
	                bill_11 = @adjustment_amount,
	                prev_bill_11 = 0,
	                prev_date_11 = @prev_report_date,
	                manual_bill_11 = 0,
	                budget_bill_11 = 0,
	                previous_year_1 = 0,
	                final_previous_year_11 = 0,
					other_income_11 = 0
	        where   branch_code = @adj_branch_code
	        and     group_desc = @group_desc
	        and     sub_group_desc = @sub_group_desc
		end

    end /*fetch*/

	/*
    * Calculate Results 12
    */
	fetch period_csr into @account_period
	if(@@fetch_status = 0)
	begin
        select  @nett_billings = 0, @prev_bill = 0
        if @intra_day = 'I' /* intra day report */
        begin
			/* get projected billing amount for period and branch */
            select  @nett_billings   = isnull(sum(amount),0)
            from    #intra
            where   branch_code = @branch_code
            and     (business_unit_id = @business_unit_id
             or     @business_unit_id is null)
            and     (agency_deal = @agency_deal
             or     @agency_deal is null)
            and     (media_product_id = @media_product_id or (@media_product_id is null and media_product_id in (select media_product_id from media_product where media = 'Y')))
            and     benchmark_end = @account_period
            and     finyear_end = @finyear
        end
        else
        begin
        	select  @nett_billings   = isnull(sum(billings_month_12),0)
            from    projected_billings
            where   report_date = @report_date
            and     branch_code = @branch_code
            and     (business_unit_id = @business_unit_id
             or     @business_unit_id is null)
            and     (agency_deal = @agency_deal
             or     @agency_deal is null)
            and     (media_product_id = @media_product_id or (@media_product_id is null and media_product_id in (select media_product_id from media_product where media = 'Y')))
            and     finyear_end = @finyear
        end

		if @mode = '1'
		begin
	        if @intra_day = 'I' /* intra day report */
	        begin
	            select  @other_billings   = isnull(sum(amount),0)
	            from    #intra
	            where   branch_code = @branch_code
	            and     (business_unit_id = @business_unit_id
	             or     @business_unit_id is null)
	            and     (agency_deal = @agency_deal
	             or     @agency_deal is null)
	            and     (media_product_id = @media_product_id or (@media_product_id is null and media_product_id in (select media_product_id from media_product where media = 'N')))
	            and     benchmark_end = @account_period
	            and     finyear_end = @finyear
			end
			else
			begin
				select 	@other_billings = isnull(sum(billings_month_12),0)
				from 	projected_billings 
				where	report_date = @report_date
	            and     (business_unit_id = @business_unit_id
	             or     @business_unit_id is null)
	            and     (media_product_id = @media_product_id or (@media_product_id is null and media_product_id in (select media_product_id from media_product where media = 'N')))
	            and     finyear_end = @finyear
				and		branch_code in (select branch_code from branch where country_code = @country_code)
			end	
		end 

    	select  @prev_bill   = isnull(sum(billings_month_12),0)
        from    projected_billings
        where   report_date = @prev_report_date
        and     branch_code = @branch_code
        and     (business_unit_id = @business_unit_id
         or     @business_unit_id is null)
        and     (agency_deal = @agency_deal
         or     @agency_deal is null)
        and     (media_product_id = @media_product_id or (@media_product_id is null and media_product_id in (select media_product_id from media_product where media = 'Y')))
        and     finyear_end = @finyear

    	select  @prev_year_bill   = isnull(sum(billings_month_12),0)
        from    projected_billings
        where   report_date = @previous_year_run_date
        and     branch_code = @branch_code
        and     (business_unit_id = @business_unit_id
         or     @business_unit_id is null)
        and     (agency_deal = @agency_deal
         or     @agency_deal is null)
        and     (media_product_id = @media_product_id or (@media_product_id is null and media_product_id in (select media_product_id from media_product where media = 'Y')))
        and     finyear_end = @prev_year

    	select  @final_prev_year_bill   = isnull(sum(billings_month_12),0)
        from    projected_billings
        where   report_date = @final_year
        and     branch_code = @branch_code
        and     (business_unit_id = @business_unit_id
         or     @business_unit_id is null)
        and     (agency_deal = @agency_deal
         or     @agency_deal is null)
        and     (media_product_id = @media_product_id or (@media_product_id is null and media_product_id in (select media_product_id from media_product where media = 'Y')))
        and     finyear_end = @prev_year

        select  @manual_bill = 0, @budget_bill = 0
        select  @manual_bill = isnull(sum(film_manual_billings_total),0),
                @budget_bill = isnull(sum(film_billings_budget),0)
        from    monthly_billings
        where   billing_period = @account_period
        and     country_code = @country_code
        and     (budget_type = @business_unit_id
         or     @business_unit_id is null)
        and     (budget_type_id = @media_product_id or @media_product_id is null)

--        exec @errorode = p_calendar_month_end	@account_period,
--									  		@end_of_month_date OUTPUT

		update  #results
        set     period_12 = @account_period,
                bill_12 = @nett_billings,
                prev_bill_12 = @prev_bill,
                prev_date_12 = @prev_report_date,
                manual_bill_12 = @manual_bill,
                budget_bill_12 = @budget_bill,
                previous_year_12 = @prev_year_bill,
                final_previous_year_12 = @final_prev_year_bill,
				other_income_12 = @other_billings
        where   branch_code = @branch_code
        and     group_desc = @group_desc
        and     sub_group_desc = @sub_group_desc
		if (@@error !=0)
			goto error

		if @adjustments = 'Y'
		begin

            select  @adjustment_amount = isnull(sum(amount),0)
            from    #intra_adj
            where   (business_unit_id = @business_unit_id
             or     @business_unit_id is null)
            and     (agency_deal = @agency_deal
             or     @agency_deal is null)
            and     branch_code in (select branch_code from branch where country_code = @country_code)
            and     (media_product_id = @media_product_id or (@media_product_id is null and media_product_id in (select media_product_id from media_product where media = 'Y')))
            and     benchmark_end = @account_period
            and     finyear_end = @finyear

			update  #results
	        set     period_12 = @account_period,
	                bill_12 = @adjustment_amount,
	                prev_bill_12 = 0,
	                prev_date_12 = @prev_report_date,
	                manual_bill_12 = 0,
	                budget_bill_12 = 0,
	                previous_year_12 = 0,
	                final_previous_year_12 = 0,
					other_income_12 = 0
	        where   branch_code = @adj_branch_code
	        and     group_desc = @group_desc
	        and     sub_group_desc = @sub_group_desc
		end

    end /*fetch*/

    /* insert future billing data */
    select  @nett_billings = 0, @prev_bill = 0

    if @intra_day = 'I' /* intra day report */
    begin
        select  @nett_billings   = isnull(sum(amount),0)
        from    #intra
        where   branch_code = @branch_code
        and     (business_unit_id = @business_unit_id
         or     @business_unit_id is null)
        and     (agency_deal = @agency_deal
         or     @agency_deal is null)
        and     (media_product_id = @media_product_id or (@media_product_id is null and media_product_id in (select media_product_id from media_product where media = 'Y')))
        and     finyear_end > @finyear
    end
    else
    begin
    	select  @nett_billings   = isnull(sum(billings_future),0)
        from    projected_billings
        where   report_date = @report_date
        and     branch_code = @branch_code
        and     (business_unit_id = @business_unit_id
         or     @business_unit_id is null)
        and     (agency_deal = @agency_deal
         or     @agency_deal is null)
        and     (media_product_id = @media_product_id or (@media_product_id is null and media_product_id in (select media_product_id from media_product where media = 'Y')))
        and     finyear_end = @finyear
    end

	if @mode = '1'
	begin
	        if @intra_day = 'I' /* intra day report */
	        begin
	            select  @other_billings   = isnull(sum(amount),0)
	            from    #intra
	            where   branch_code = @branch_code
	            and     (business_unit_id = @business_unit_id
	             or     @business_unit_id is null)
	            and     (agency_deal = @agency_deal
	             or     @agency_deal is null)
	            and     (media_product_id = @media_product_id or (@media_product_id is null and media_product_id in (select media_product_id from media_product where media = 'N')))
	            and     benchmark_end = @account_period
	            and     finyear_end = @finyear
			end
			else
			begin
				select 	@other_billings = isnull(sum(billings_future),0)
				from 	projected_billings 
				where	report_date = @report_date
	            and     (business_unit_id = @business_unit_id
	             or     @business_unit_id is null)
	            and     (media_product_id = @media_product_id or (@media_product_id is null and media_product_id in (select media_product_id from media_product where media = 'N')))
	            and     finyear_end = @finyear
				and		branch_code in (select branch_code from branch where country_code = @country_code)
			end	
	end 

	select  @prev_bill   = isnull(sum(billings_future),0)
    from    projected_billings
    where   report_date = @prev_report_date
    and     branch_code = @branch_code
    and     (business_unit_id = @business_unit_id
     or     @business_unit_id is null)
    and     (agency_deal = @agency_deal
     or     @agency_deal is null)
    and     (media_product_id = @media_product_id or (@media_product_id is null and media_product_id in (select media_product_id from media_product where media = 'Y')))
    and     finyear_end = @finyear

    select  @prev_year_bill   = isnull(sum(billings_future),0)
    from    projected_billings
    where   report_date = @previous_year_run_date
    and     branch_code = @branch_code
    and     (business_unit_id = @business_unit_id
     or     @business_unit_id is null)
    and     (agency_deal = @agency_deal
     or     @agency_deal is null)
    and     (media_product_id = @media_product_id or (@media_product_id is null and media_product_id in (select media_product_id from media_product where media = 'Y')))
    and     finyear_end = @prev_year

    select  @final_prev_year_bill   = isnull(sum(billings_future),0)
    from    projected_billings
    where   report_date = @final_year_end_date
    and     branch_code = @branch_code
    and     (business_unit_id = @business_unit_id
     or     @business_unit_id is null)
    and     (agency_deal = @agency_deal
     or     @agency_deal is null)
    and     (media_product_id = @media_product_id or (@media_product_id is null and media_product_id in (select media_product_id from media_product where media = 'Y')))
    and     finyear_end = @prev_year


    select  @manual_bill = 0, @budget_bill = 0

	update  #results
    set     period_ftr = @future_dummy_period,
            bill_ftr = @nett_billings,
            prev_bill_ftr = @prev_bill,
            prev_date_ftr = @prev_report_date,
            manual_bill_ftr = @manual_bill,
            budget_bill_ftr = @budget_bill,
            update_date_ftr = @report_date,
            previous_year_ftr = @prev_year_bill,
            final_previous_year_ftr = @final_prev_year_bill,
			other_income_ftr = @other_billings
    where   branch_code = @branch_code
    and     sub_group_desc = @sub_group_desc
    and     group_desc = @group_desc
	if (@@error !=0)
		goto error

	if @adjustments = 'Y'
	begin

        select  @adjustment_amount = isnull(sum(amount),0)
        from    #intra_adj
        where   (business_unit_id = @business_unit_id
         or     @business_unit_id is null)
        and     branch_code in (select branch_code from branch where country_code = @country_code)
        and     (agency_deal = @agency_deal
         or     @agency_deal is null)
        and     (media_product_id = @media_product_id or (@media_product_id is null and media_product_id in (select media_product_id from media_product where media = 'Y')))
        and     finyear_end > @finyear

		update  #results
        set     period_ftr = @future_dummy_period,
                bill_ftr = @adjustment_amount,
                prev_bill_ftr = 0,
                prev_date_ftr = @prev_report_date,
                manual_bill_ftr = 0,
                budget_bill_ftr = 0,
                previous_year_ftr = 0,
                final_previous_year_ftr = 0,
				other_income_ftr = 0
        where   branch_code = @adj_branch_code
        and     group_desc = @group_desc
        and     sub_group_desc = @sub_group_desc
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

       fetch report_csr into @business_unit_id, @media_product_id, @agency_deal, @group_desc, @sub_group_desc, @sort_add,@country_code, @branch_code, @sort_order
end    
deallocate report_csr
select @branch_csr_open = 0

/*
 * Return Result Set
 */

select 	country_code,
		branch_code,
		branch_name,
		period_1,
		bill_1,
		prev_bill_1,
		prev_date_1,
		manual_bill_1,
		budget_bill_1,
		previous_year_1,
		final_previous_year_1,
		period_2,
		bill_2,
		prev_bill_2,
		prev_date_2,
		manual_bill_2,
		budget_bill_2,
		previous_year_2,
		final_previous_year_2,
		period_3,
		bill_3,
		prev_bill_3,
		prev_date_3,
		manual_bill_3,
		budget_bill_3,
		previous_year_3,
		final_previous_year_3,
		period_4,
		bill_4,
		prev_bill_4,
		prev_date_4,
		manual_bill_4,
		budget_bill_4,
		previous_year_4,
		final_previous_year_4,
		period_5,
		bill_5,
		prev_bill_5,
		prev_date_5,
		manual_bill_5,
		budget_bill_5,
		previous_year_5,
		final_previous_year_5,
		period_6,
		bill_6,
		prev_bill_6,
		prev_date_6,
		manual_bill_6,
		budget_bill_6,
		previous_year_6,
		final_previous_year_6,
		period_7,
		bill_7,
		prev_bill_7,
		prev_date_7,
		manual_bill_7,
		budget_bill_7,
		previous_year_7,
		final_previous_year_7,
		period_8,
		bill_8,
		prev_bill_8,
		prev_date_8,
		manual_bill_8,
		budget_bill_8,
		previous_year_8,
		final_previous_year_8,
		period_9,
		bill_9,
		prev_bill_9,
		prev_date_9,
		manual_bill_9,
		budget_bill_9,
		previous_year_9,
		final_previous_year_9,
		period_10,
		bill_10,
		prev_bill_10,
		prev_date_10,
		manual_bill_10,
		budget_bill_10,
		previous_year_10,
		final_previous_year_10,
		period_11,
		bill_11,
		prev_bill_11,
		prev_date_11,
		manual_bill_11,
		budget_bill_11,
		previous_year_11,
		final_previous_year_11,
		period_12,
	   	bill_12,
       	prev_bill_12,
       	prev_date_12,
       	manual_bill_12,
       	budget_bill_12,
       	previous_year_12,
       	final_previous_year_12,
       	period_ftr,
	   	bill_ftr,
       	prev_bill_ftr,
       	prev_date_ftr,
       	manual_bill_ftr,
       	budget_bill_ftr,
       	update_date_ftr,
       	previous_year_ftr,
       	final_previous_year_ftr,
       	@finyear as 'financial_year',
       	sort_order,
       	@report_header,
       	group_desc,
       	sub_group_desc,
       	@previous_year_run_date,
		other_income_1,
		other_income_2,
		other_income_3,
		other_income_4,
		other_income_5,
		other_income_6,
		other_income_7,
		other_income_8,
		other_income_9,
		other_income_10,
		other_income_11,
		other_income_12,
		other_income_ftr,
		other_income_desc
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
