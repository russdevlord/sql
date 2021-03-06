/****** Object:  StoredProcedure [dbo].[p_cag_analysis_bill_coll]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cag_analysis_bill_coll]
GO
/****** Object:  StoredProcedure [dbo].[p_cag_analysis_bill_coll]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create PROC [dbo].[p_cag_analysis_bill_coll]  @cinema_agreement_id  int,
                                      @accounting_period   datetime,
                                      @billing_group       char, 
                                      @collect_group       char, 
                                      @mode int                            
as
 

/* Proc name:   p_cag_analysis_bill_coll
 * Author:      Victoria Tyshchenko
 * Date:        17/02/2004
 * Description: Cinema Agreement Analysis window. Billings summary; Collection summary tabs are using this SP
 *
 * PVCS Tags - DO NOT MODIFY
 *
 * $Date:   May 24 2004 12:43:38  $ 
 * $Author:   vtyshchenko  $ 
 * $Revision:   1.2  $
 * $Workfile:   cag_analysis_bill_coll.sql  $
 *
*/ 

declare @proc_name varchar(30)
select  @proc_name = 'p_cag_analysis_bill_coll'
/*exec    p_audit_proc @proc_name,'start' */

declare @error      int,
        @err_msg    varchar(150),
        --@error         int,
        @revenue_source         char(1),
        @amount_this_month           money,
        @amount_year_to_date         money,
        @amount_agreement_to_date    money,
        @fin_year_start              datetime,
        @complex_id                  int,
        @complex_name                char(50),
        @agreement_desc              varchar(50),
        @cnt                         int,
        @msg                         varchar(255)

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
    message                     varchar(255) null
 )

select @error = 0 

select @agreement_desc = agreement_desc from cinema_Agreement
where cinema_Agreement_id = @cinema_Agreement_id

if @mode = 0 
     declare cur_revenue_source cursor static for                               
     SELECT DISTINCT	revenue_source, 0, ''
      FROM cinema_agreement_revenue
      WHERE  cinema_agreement_id = @cinema_agreement_id
         
if @mode = 1 
     declare cur_revenue_source cursor static for                               
     SELECT DISTINCT cinema_agreement_revenue.revenue_source, complex.complex_id, complex_name
      FROM cinema_agreement_revenue, complex
      WHERE  cinema_agreement_revenue.complex_id = complex.complex_id and
             cinema_agreement_id = @cinema_agreement_id
        

open cur_revenue_source
select @error = @@error
if @error != 0
    goto rollbackerror

fetch cur_revenue_source into @revenue_source, @complex_id, @complex_name
while(@@fetch_status = 0)
    begin
    
      SELECT @amount_this_month = isnull(sum(cinema_agreement_revenue.cinema_amount),0)
        FROM cinema_agreement_revenue,
             liability_type, liability_category
       WHERE cinema_agreement_revenue.liability_type_id = liability_type.liability_type_id and
             liability_type.liability_category_id = liability_category.liability_category_id and  
             cinema_agreement_revenue.cancelled = 'N' and
             cinema_agreement_revenue.origin_period = @accounting_period and
             liability_category.billing_group = @billing_group and             
             liability_category.collect_group = @collect_group and             
             ( cinema_agreement_revenue.cinema_agreement_id = @cinema_agreement_id ) And  
             cinema_agreement_revenue.revenue_source = @revenue_source and
             ( cinema_agreement_revenue.complex_id = @complex_id or @mode = 0 )

     SELECT @fin_year_start = accounting_period_b.end_date  
        FROM accounting_period accounting_period_a,   
             cinema_agreement_revenue,   
             accounting_period accounting_period_b  
       WHERE ( accounting_period_a.end_date = @accounting_period) and  
             ( accounting_period_a.finyear_end = accounting_period_b.finyear_end )   and
             ( accounting_period_b.period_no = 7 )  
             
      SELECT @amount_year_to_date = isnull(sum(cinema_agreement_revenue.cinema_amount),0)
        FROM cinema_agreement_revenue,   
             liability_type, liability_category
       WHERE cinema_agreement_revenue.liability_type_id = liability_type.liability_type_id and
             liability_type.liability_category_id = liability_category.liability_category_id and
             cinema_agreement_revenue.cancelled = 'N' and
             liability_category.billing_group = @billing_group and             
             liability_category.collect_group = @collect_group and             
             cinema_agreement_revenue.origin_period <= @accounting_period and
             ( cinema_agreement_revenue.origin_period >= @fin_year_start )   and
             ( cinema_agreement_revenue.cinema_agreement_id = @cinema_agreement_id ) And  
             cinema_agreement_revenue.revenue_source = @revenue_source and
             ( cinema_agreement_revenue.complex_id = @complex_id or @mode = 0 )
        
      SELECT @amount_agreement_to_date = isnull(sum(cinema_agreement_revenue.cinema_amount), 0)
        FROM cinema_agreement_revenue,   
             liability_type, liability_category
       WHERE cinema_agreement_revenue.liability_type_id = liability_type.liability_type_id and
             liability_type.liability_category_id = liability_category.liability_category_id and
             cinema_agreement_revenue.cancelled = 'N' and
             liability_category.billing_group = @billing_group and             
             liability_category.collect_group = @collect_group and             
             cinema_agreement_revenue.origin_period <= @accounting_period and
             ( cinema_agreement_revenue.cinema_agreement_id = @cinema_agreement_id ) And  
             cinema_agreement_revenue.revenue_source = @revenue_source and
             ( cinema_agreement_revenue.complex_id = @complex_id or @mode = 0 )
             
             if @billing_group = 'N' and @collect_group = 'Y'
                begin
                    select @amount_this_month        = - @amount_this_month
                    select @amount_year_to_date      = - @amount_year_to_date
                    select @amount_agreement_to_date = - @amount_agreement_to_date
                end
             
        if IsNull(@amount_this_month, 0) <> 0 or isNull(@amount_year_to_date, 0) <> 0 or IsNull(@amount_agreement_to_date, 0) <> 0
            begin
               Insert into #result_set    
                ( cinema_agreement_id,
                  complex_id,
                  revenue_source,
                  amount_this_month,
                  amount_year_to_date,
                  amount_agreement_to_date,
                  complex_name, agreement_desc, accounting_period, message )
                 values ( @cinema_Agreement_id,   @complex_id, @revenue_source, @amount_this_month,
                  @amount_year_to_date, @amount_agreement_to_date, @complex_name,
                  @agreement_desc, @accounting_period, '')
                  
                   select @error = @@error
                   if @error != 0
                    goto rollbackerror
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
             ( cinema_agreement_id,
               complex_id,
               revenue_source,
               amount_this_month,
               amount_year_to_date,
               amount_agreement_to_date,
               complex_name, agreement_desc, accounting_period, message )
       values ( @cinema_Agreement_id,   null, '', null,
                  null, null, null,
                  @agreement_desc, @accounting_period, @msg)
       select @error = @@error
       if @error != 0
             goto rollbackerror
   end
    

select #result_set.cinema_agreement_id, #result_set.complex_id, #result_set.revenue_source, #result_set.amount_this_month, #result_set.amount_year_to_date, #result_set.amount_agreement_to_date, #result_set.complex_name, #result_set.agreement_desc, #result_set.accounting_period, #result_set.message from #result_set


deallocate cur_revenue_source

/*exec p_audit_proc @proc_name,'end'*/
return 0

rollbackerror:
error:
deallocate cur_revenue_source

if @error >= 50000 
   begin
      select @err_msg = @proc_name + ': ' + @err_msg
      raiserror (@err_msg, 16, 1)
   end
--else
--   raiserror ( @error, 16, 1)

return -100
GO
