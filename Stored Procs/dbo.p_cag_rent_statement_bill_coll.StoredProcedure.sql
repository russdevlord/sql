/****** Object:  StoredProcedure [dbo].[p_cag_rent_statement_bill_coll]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cag_rent_statement_bill_coll]
GO
/****** Object:  StoredProcedure [dbo].[p_cag_rent_statement_bill_coll]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create PROC [dbo].[p_cag_rent_statement_bill_coll]  @cinema_agreement_id  	int,
                                            @statement_no  			int, 
                                            @billing_group 			char(1), 
                                            @collect_group 			char(1),  
                                            @mode 					int 
as                              

/*
 * SP p_cag_rent_statement_bill_coll retrieves data for Billing Summary page of a Cinema Rent Statement
 *
 *   mode: 0 - details by complex - revenue source
 *         1 - details by revenue source only
 */

/* ALL YEAR TO DATE AMOUNTS calculated from 01-01-2004 */                                            

declare @error     								int,
        @err_msg                				varchar(150),
        @revenue_source         				char(1),
        @amount_this_month           			money,
        @amount_year_to_date         			money,
        @amount_agreement_to_date   			money,
        @diffcurr_amount_this_month           	money,
        @diffcurr_amount_year_to_date         	money,
        @diffcurr_amount_agreement_to_date   	money,
        @cal_year_start             			datetime,
        @complex_id                  			int,
        @complex_name                			char(50),
        @statement_period            			datetime,
        @agreement_desc              			varchar(50),
        @cnt                         			int,
        @msg                         			varchar(255),
        @currency_code               			varchar(5),
		@abn_no									varchar(20)



select @currency_code = currency_code from cinema_agreement where cinema_agreement_id = @cinema_agreement_id        

CREATE TABLE #result_set
(   cinema_agreement_id         int null,
    complex_id                  int null,
    revenue_source              char(1) null,
    amount_this_month           money null,
    amount_year_to_date         money null,
    amount_agreement_to_date    money null,
    complex_name                varchar(50) null, 
    agreement_desc              varchar(50) null,
    accounting_period           datetime null,
    message                     varchar(255) null,
	abn_no						varchar(20) null
 )

select 	@error = 0 

select 	@agreement_desc = agreement_desc ,
		@abn_no	= abn_no
from 	cinema_agreement
where 	cinema_agreement_id = @cinema_agreement_id

select 	@statement_period = accounting_period 
from 	cinema_agreement_statement
where 	cinema_agreement_id = @cinema_agreement_id 
and 	statement_no = @statement_no

SELECT 	@cal_year_start = max(accounting_period.end_date)
FROM 	accounting_period
WHERE 	end_date <= @statement_period
and		period_no = 1

if @mode = 0 
	declare 	cur_revenue_source cursor static for                               
	SELECT 		DISTINCT cinema_agreement_policy.revenue_source, 
				0, 
				''
	FROM 		cinema_agreement_policy
	WHERE  		policy_status_code in ('A', 'I') 
	and 		cinema_agreement_id = @cinema_agreement_id
         
if @mode = 1 
	declare 	cur_revenue_source cursor static for 
	SELECT 		DISTINCT cinema_agreement_policy.revenue_source, 
				complex.complex_id, 
				complex_name
	FROM 		cinema_agreement_policy, 
				complex
	WHERE  		cinema_agreement_policy.complex_id = complex.complex_id 
	and			policy_status_code in ('A', 'I') 
	and 		cinema_agreement_id = @cinema_agreement_id




open cur_revenue_source
if @@error != 0
    begin
        select @error = 500050
        select @err_msg = 'p_cag_rent_statement_bill_coll: OPEN CURSOR error'
        GOTO PROC_END
    end
fetch cur_revenue_source into @revenue_source, @complex_id, @complex_name
while(@@fetch_status = 0)
begin
    
	SELECT 		@amount_this_month = isnull(sum(cinema_agreement_revenue.cinema_amount),0)
	FROM 		cinema_agreement_revenue,
				liability_type, 
				liability_category
	WHERE 		cinema_agreement_revenue.liability_type_id = liability_type.liability_type_id 
	and			liability_type.liability_category_id = liability_category.liability_category_id 
	and  		cinema_agreement_revenue.cancelled = 'N' 
	and			cinema_agreement_revenue.accounting_period = @statement_period 
	and			liability_category.billing_group = @billing_group 
	and     	liability_category.collect_group = @collect_group 
	and     	cinema_agreement_revenue.cinema_agreement_id = @cinema_agreement_id 
	and  		cinema_agreement_revenue.revenue_source = @revenue_source 
	and			(cinema_agreement_revenue.complex_id = @complex_id 
	or 			@mode = 0 )
	and			cinema_agreement_revenue.currency_code = @currency_code
	
	SELECT 		@amount_year_to_date = isnull(sum(cinema_agreement_revenue.cinema_amount),0)
	FROM 		cinema_agreement_revenue,   
				liability_type, 
				liability_category, 
				cinema_agreement
	WHERE 		cinema_agreement_revenue.liability_type_id = liability_type.liability_type_id 
	and			liability_type.liability_category_id = liability_category.liability_category_id 
	and			cinema_agreement.cinema_agreement_id = cinema_agreement_revenue.cinema_agreement_id 
	and			cinema_agreement_revenue.cancelled = 'N' 
	and			liability_category.billing_group = @billing_group 
	and 		liability_category.collect_group = @collect_group 
	and    		cinema_agreement_revenue.accounting_period <= @statement_period 
	and			cinema_agreement_revenue.accounting_period >= @cal_year_start
	and			cinema_agreement_revenue.cinema_agreement_id = @cinema_agreement_id
	and  		cinema_agreement_revenue.revenue_source = @revenue_source 
	and			cinema_agreement_revenue.accounting_period >= ( case @currency_code when 'NZD' then '2004-07-01'  else '2004-1-1' end)
	and			(cinema_agreement_revenue.complex_id = @complex_id 
	or	 		@mode = 0)
	and			cinema_agreement_revenue.currency_code = @currency_code
	
	SELECT 		@amount_agreement_to_date = isnull(sum(cinema_agreement_revenue.cinema_amount), 0)
	FROM 		cinema_agreement_revenue,   
				liability_type, 
				liability_category
	WHERE 		cinema_agreement_revenue.liability_type_id = liability_type.liability_type_id 
	and			liability_type.liability_category_id = liability_category.liability_category_id 
	and			cinema_agreement_revenue.cancelled = 'N' 
	and			liability_category.billing_group = @billing_group 
	and     	liability_category.collect_group = @collect_group
	and     	cinema_agreement_revenue.accounting_period <= @statement_period 
	and			cinema_agreement_revenue.accounting_period >= ( case @currency_code when 'NZD' then '2004-07-01'  else '2004-1-1' end) 
	and			cinema_agreement_revenue.cinema_agreement_id = @cinema_agreement_id
	and  		cinema_agreement_revenue.revenue_source = @revenue_source 
	and			(cinema_agreement_revenue.complex_id = @complex_id 
	or 			@mode = 0)
	and			cinema_agreement_revenue.currency_code = @currency_code
	
	SELECT 		@diffcurr_amount_this_month = isnull(sum(conversion_rate * cinema_agreement_revenue.cinema_amount),0)
	FROM 		cinema_agreement_revenue,
				liability_type, 
				liability_category,
				exchange_rates
	WHERE 		cinema_agreement_revenue.liability_type_id = liability_type.liability_type_id 
	and			liability_type.liability_category_id = liability_category.liability_category_id 
	and  		cinema_agreement_revenue.cancelled = 'N' 
	and			cinema_agreement_revenue.accounting_period = @statement_period 
	and			liability_category.billing_group = @billing_group 
	and     	liability_category.collect_group = @collect_group 
	and     	cinema_agreement_revenue.cinema_agreement_id = @cinema_agreement_id 
	and  		cinema_agreement_revenue.revenue_source = @revenue_source 
	and			(cinema_agreement_revenue.complex_id = @complex_id 
	or 			@mode = 0 )
	and			cinema_agreement_revenue.currency_code <> @currency_code
	and			exchange_rates.accounting_period = cinema_agreement_revenue.accounting_period
	and			exchange_rates.currency_code_from = cinema_agreement_revenue.currency_code
	and			exchange_rates.currency_code_to = @currency_code
	
	SELECT 		@diffcurr_amount_year_to_date = isnull(sum(conversion_rate * cinema_agreement_revenue.cinema_amount),0)
	FROM 		cinema_agreement_revenue,   
				liability_type, 
				liability_category, 
				cinema_agreement,
				exchange_rates
	WHERE 		cinema_agreement_revenue.liability_type_id = liability_type.liability_type_id 
	and			liability_type.liability_category_id = liability_category.liability_category_id 
	and			cinema_agreement.cinema_agreement_id = cinema_agreement_revenue.cinema_agreement_id 
	and			cinema_agreement_revenue.cancelled = 'N' 
	and			liability_category.billing_group = @billing_group 
	and 		liability_category.collect_group = @collect_group 
	and    		cinema_agreement_revenue.accounting_period <= @statement_period 
	and			cinema_agreement_revenue.accounting_period >= @cal_year_start
	and			cinema_agreement_revenue.cinema_agreement_id = @cinema_agreement_id
	and  		cinema_agreement_revenue.revenue_source = @revenue_source 
	and			cinema_agreement_revenue.accounting_period >= ( case @currency_code when 'NZD' then '2004-07-01'  else '2004-1-1' end)
	and			(cinema_agreement_revenue.complex_id = @complex_id 
	or	 		@mode = 0)
	and			cinema_agreement_revenue.currency_code <> @currency_code
	and			exchange_rates.accounting_period = cinema_agreement_revenue.accounting_period
	and			exchange_rates.currency_code_from = cinema_agreement_revenue.currency_code
	and			exchange_rates.currency_code_to = @currency_code
	
	SELECT 		@diffcurr_amount_agreement_to_date =  isnull(sum(conversion_rate * cinema_agreement_revenue.cinema_amount), 0)
	FROM 		cinema_agreement_revenue,   
				liability_type, 
				liability_category,
				exchange_rates
	WHERE 		cinema_agreement_revenue.liability_type_id = liability_type.liability_type_id 
	and			liability_type.liability_category_id = liability_category.liability_category_id 
	and			cinema_agreement_revenue.cancelled = 'N' 
	and			liability_category.billing_group = @billing_group 
	and     	liability_category.collect_group = @collect_group
	and     	cinema_agreement_revenue.accounting_period <= @statement_period 
	and			cinema_agreement_revenue.accounting_period >= ( case @currency_code when 'NZD' then '2004-07-01'  else '2004-1-1' end) 
	and			cinema_agreement_revenue.cinema_agreement_id = @cinema_agreement_id
	and  		cinema_agreement_revenue.revenue_source = @revenue_source 
	and			(cinema_agreement_revenue.complex_id = @complex_id 
	or 			@mode = 0)
	and			cinema_agreement_revenue.currency_code <> @currency_code
	and			exchange_rates.accounting_period = cinema_agreement_revenue.accounting_period
	and			exchange_rates.currency_code_from = cinema_agreement_revenue.currency_code
	and			exchange_rates.currency_code_to = @currency_code

	select 		@amount_this_month = isnull(@amount_this_month,0) + isnull(@diffcurr_amount_this_month,0),
				@amount_year_to_date = isnull(@amount_year_to_date,0) + isnull(@diffcurr_amount_year_to_date,0),
				@amount_agreement_to_date = isnull(@amount_agreement_to_date,0) + isnull(@diffcurr_amount_agreement_to_date,0)
		
	if @billing_group = 'N' and @collect_group = 'Y'
	begin
		select @amount_this_month        = - @amount_this_month
		select @amount_year_to_date      = - @amount_year_to_date
		select @amount_agreement_to_date = - @amount_agreement_to_date
	end
	
	if IsNull(@amount_this_month, 0) <> 0 or isNull(@amount_year_to_date, 0) <> 0 or IsNull(@amount_agreement_to_date, 0) <> 0
		Insert into #result_set    
		(cinema_agreement_id,
		complex_id,
		revenue_source,
		amount_this_month,
		amount_year_to_date,
		amount_agreement_to_date,
		complex_name, 
		agreement_desc, 
		accounting_period, 
		message,
		abn_no )
		values 
		(@cinema_agreement_id,   
		@complex_id, 
		@revenue_source, 
		@amount_this_month,
		@amount_year_to_date, 
		@amount_agreement_to_date,
		@complex_name,
		@agreement_desc, 
		@statement_period, 
		'',
		@abn_no)
	
	if @@error != 0
	begin
		select @error = 500050
		select @err_msg = 'p_cag_rent_statement_bill_coll: INSERT INTO error'
		GOTO PROC_END
	end
         
    fetch cur_revenue_source into @revenue_source, @complex_id, @complex_name
end    

select @cnt = count(*) from #result_set
if isnull(@cnt, 0) = 0 
begin
	if @billing_group = 'Y'
		select @msg = 'No billings for this agreement.'

	if @collect_group = 'Y'
		select @msg = 'No collections for this agreement.'

	Insert into #result_set    
	(cinema_agreement_id,
	complex_id,
	revenue_source,
	amount_this_month,
	amount_year_to_date,
	amount_agreement_to_date,
	complex_name, agreement_desc, 
	accounting_period, 
	message,
	abn_no )	values 
	(@cinema_agreement_id,
	null, 
	'', 
	null,
	null, 
	null, 
	null,
	@agreement_desc, 
	@statement_period, 
	@msg,
	@abn_no)
end
    

select * from #result_set

PROC_END:
deallocate cur_revenue_source 
        
if @error >= 50000
    begin
       raiserror (@err_msg, 16, 1)        
       return -1
    end
        
return 0
GO
