/****** Object:  StoredProcedure [dbo].[p_slide_invoiced_bill_mon_view]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_slide_invoiced_bill_mon_view]
GO
/****** Object:  StoredProcedure [dbo].[p_slide_invoiced_bill_mon_view]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_slide_invoiced_bill_mon_view] @period_from	datetime, @country_code char(2)
as
set nocount on 
/*
 * Declare Valiables
 */ 

declare @error							integer,
	    @sqlstatus					    integer,
        @errorode							integer,
        @end_date                       datetime,
        @nett_billings                  money,
        @credits                        money,
        @budget                         money,
        @sales_territory_id             int,
        @report_period                  datetime,
        @period_cnt                     int,
        @err_msg                        varchar(255),
        @proc_name                      varchar(30)
        
select @proc_name =  'p_slide_invoiced_bill_mon_view'
        
        
CREATE TABLE   #result
(   country_code            char         Null,
    sales_territory_id      int          Null,
    period_1                datetime     Null,
    bill_1             money        Null,
    credit_1           money        Null,
    target_1            money        Null,
    period_2                datetime     Null,
    bill_2             money        Null,
    credit_2           money        Null,
    target_2            money        Null,
    period_3                datetime     Null,
    bill_3             money        Null,
    credit_3           money        Null,
    target_3            money        Null,
    period_4                datetime     Null,
    bill_4             money        Null,
    credit_4           money        Null,
    target_4            money        Null,
    period_5                datetime     Null,
    bill_5             money        Null,
    credit_5           money        Null,
    target_5            money        Null,
    period_6                datetime     Null,
    bill_6             money        Null,
    credit_6           money        Null,
    target_6            money        Null,
    period_7                datetime     Null,
    bill_7             money        Null,
    credit_7           money        Null,
    target_7            money        Null,
    period_8                datetime     Null,
    bill_8             money        Null,
    credit_8           money        Null,
    target_8            money        Null,
    period_9                datetime     Null,
    bill_9             money        Null,
    credit_9           money        Null,
    target_9            money        Null,
    period_10                datetime     Null,
    bill_10             money        Null,
    credit_10           money        Null,
    target_10            money        Null,
    period_11                datetime     Null,
    bill_11             money        Null,
    credit_11           money        Null,
    target_11            money        Null,
    period_12                datetime     Null,
    bill_12             money        Null,
    credit_12           money        Null,
    target_12            money        Null
)
        
        
/*
* If reporting_period is end_date then change it to be benchmark period
*/
if not exists(select 1 from accounting_period where benchmark_end = @period_from)
    select @period_from = benchmark_end
    from accounting_period
    where end_date = @period_from
    
select @end_date = end_date
from   accounting_period
where  benchmark_end = @period_from

--select @curr_period = max(benchmark_end)
--from   accounting_period
--where  status = 'O'

 declare territory_csr cursor static for
  select sales_territory_id,
         country_code
    from sales_territory
 where   country_code = @country_code
     for read only
     
     
open territory_csr
fetch territory_csr into @sales_territory_id, @country_code

while (@@fetch_status = 0)
    begin
    insert into #result (country_code, sales_territory_id ) values (@country_code, @sales_territory_id)
	select @error = @@error
	if (@error !=0)
        begin
        select @err_msg = 'p_slide_invoiced_bill_mon_view::Error Inserting a row into TMP table.'
		goto error
        end

	declare period_csr cursor static for
	select  benchmark_end
	from    accounting_period
	where	benchmark_end >=  @period_from
	order by end_date ASC
	for read only

	/*
  	 * Open Period Cursor
	 */
	open period_csr

	fetch period_csr into @report_period
    select @period_cnt  = 1
	while(@@fetch_status = 0 and @period_cnt <= 12)
    	begin
            execute @errorode = p_slide_invoiced_bill @sales_territory_id, @report_period, @nett_billings OUTPUT, @credits OUTPUT, @budget OUTPUT
            
    		if (@errorode !=0)
                begin
                    select @err_msg = 'p_slide_invoiced_bill_mon_view:: exec p_slide_invoiced_bill failed.'
            		goto error
                end
	
            if @period_cnt = 1
            		update #result
                     set period_1 = @report_period,
                         bill_1 = @nett_billings,
                         credit_1 = @credits,
                         target_1 = @budget
                   where sales_territory_id = @sales_territory_id
                
            if @period_cnt = 2
            		update #result
                     set period_2 = @report_period,
                         bill_2 = @nett_billings,
                         credit_2 = @credits,
                         target_2 = @budget
                   where sales_territory_id = @sales_territory_id
                
            if @period_cnt = 3
            		update #result
                     set period_3 = @report_period,
                         bill_3 = @nett_billings,
                         credit_3 = @credits,
                         target_3 = @budget
                   where sales_territory_id = @sales_territory_id
                   
            if @period_cnt = 4
            		update #result
                     set period_4 = @report_period,
                         bill_4 = @nett_billings,
                         credit_4 = @credits,
                         target_4 = @budget
                   where sales_territory_id = @sales_territory_id
                   
            if @period_cnt = 5
            		update #result
                     set period_5 = @report_period,
                         bill_5 = @nett_billings,
                         credit_5 = @credits,
                         target_5 = @budget
                   where sales_territory_id = @sales_territory_id
                   
                   
            if @period_cnt = 6
            		update #result
                     set period_6 = @report_period,
                         bill_6 = @nett_billings,
                         credit_6 = @credits,
                         target_6 = @budget
                   where sales_territory_id = @sales_territory_id
                   
                   
            if @period_cnt = 7
            		update #result
                     set period_7 = @report_period,
                         bill_7 = @nett_billings,
                         credit_7 = @credits,
                         target_7 = @budget
                   where sales_territory_id = @sales_territory_id
                   
                   
            if @period_cnt = 8
            		update #result
                     set period_8 = @report_period,
                         bill_8 = @nett_billings,
                         credit_8 = @credits,
                         target_8 = @budget
                   where sales_territory_id = @sales_territory_id
                   
                   
            if @period_cnt = 9
            		update #result
                     set period_9 = @report_period,
                         bill_9 = @nett_billings,
                         credit_9 = @credits,
                         target_9 = @budget
                   where sales_territory_id = @sales_territory_id
                   
                   
            if @period_cnt = 10
            		update #result
                     set period_10 = @report_period,
                         bill_10 = @nett_billings,
                         credit_10 = @credits,
                         target_10 = @budget
                   where sales_territory_id = @sales_territory_id
                   
                   
            if @period_cnt = 11
            		update #result
                     set period_11 = @report_period,
                         bill_11 = @nett_billings,
                         credit_11 = @credits,
                         target_11 = @budget
                   where sales_territory_id = @sales_territory_id
                   
            if @period_cnt = 12
            		update #result
                     set period_12 = @report_period,
                         bill_12 = @nett_billings,
                         credit_12 = @credits,
                         target_12 = @budget
                   where sales_territory_id = @sales_territory_id
                   
            	select @error = @@error
           		if (@error !=0)
                begin
                    select @err_msg = 'p_slide_invoiced_bill_mon_view::Failed to update row in the TMP RESULT table.'
            		goto error
                end
                

        	fetch period_csr into @report_period
            select @period_cnt = @period_cnt + 1
	end
    close period_csr
	deallocate period_csr
    
    fetch territory_csr into @sales_territory_id, @country_code
    
end    

select * from #result

/*
 * Return
 */
deallocate territory_csr
return 0

/*
 * Error Handler
 */
error:
    deallocate territory_csr
    deallocate period_csr
    
    if @error >= 50000 -- developer generated errors
        begin
        select @err_msg = @proc_name + ': ' + @err_msg
        raiserror (@err_msg, 16, 1)
        end
    else
        raiserror ( 'p_slide_invoiced_bill_mon_view', 16, 1) 
        
	return -100
GO
