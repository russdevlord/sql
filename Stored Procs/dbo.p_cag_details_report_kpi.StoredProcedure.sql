/****** Object:  StoredProcedure [dbo].[p_cag_details_report_kpi]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cag_details_report_kpi]
GO
/****** Object:  StoredProcedure [dbo].[p_cag_details_report_kpi]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create PROC [dbo].[p_cag_details_report_kpi]  @cinema_agreement_id		integer,
                                    @start_date                 datetime

as
                             
declare @error     				int,
        @err_msg                varchar(150),
        @revenue_source         char(1),
        @bill_this_month           money,
        @bill_year_to_date         money,
        @bill_agreement_to_date    money,
        @cur_revenue_source_open        int,
        @fin_year_start                 datetime,
        @coll_this_month             money,
        @coll_year_to_date           money,
        @coll_agreement_to_date      money,
        @rent_paid_this_month        money,
        @rent_paid_year_to_date      money,
        @rent_paid_agreement_to_date    money

CREATE TABLE #result_set
(   cinema_agreement_id         int null,
    revenue_source              char(1) null,
    bill_this_month             money null,
    bill_year_to_date           money null,
    bill_agreement_to_date      money null,
    coll_this_month             money null,
    coll_year_to_date           money null,
    coll_agreement_to_date      money null,
    rent_paid_this_month        money null,
    rent_paid_year_to_date      money null,
    rent_paid_agreement_to_date    money null )
    
SELECT @fin_year_start = accounting_period_b.end_date  
  FROM accounting_period accounting_period_a,   
       accounting_period accounting_period_b  
 WHERE ( accounting_period_a.end_date = @start_date ) and  
       ( accounting_period_a.finyear_end = accounting_period_b.finyear_end )   and
       ( accounting_period_b.period_no = 7 )  


declare cur_revenue_source cursor static for                               
    SELECT DISTINCT	cinema_agreement_policy.revenue_source
    FROM cinema_agreement_policy
    WHERE cinema_agreement_id = @cinema_agreement_id
 
open cur_revenue_source
if @@error != 0
    begin
        select @error = 500050
        select @err_msg = 'p_cag_details_report_kpi: OPEN CURSOR error'
        GOTO PROC_END
    end
select @cur_revenue_source_open = 1

fetch cur_revenue_source into @revenue_source
while(@@fetch_status = 0)
    begin

      /*
      *  Billings
      */    
      SELECT @bill_this_month = isnull(sum(cinema_agreement_revenue.cinema_amount), 0)
        FROM cinema_agreement_revenue,   
             liability_type, liability_category
       WHERE cinema_agreement_revenue.liability_type_id = liability_type.liability_type_id and
             liability_type.liability_category_id = liability_category.liability_category_id and
             liability_category.billing_group = 'Y' and           
             cinema_agreement_revenue.cancelled  = 'N' and
             ( cinema_agreement_revenue.cinema_agreement_id = @cinema_agreement_id ) And  
             cinema_agreement_revenue.revenue_source = @revenue_source and
             accounting_period = @start_date
             
      SELECT @bill_year_to_date = isnull(sum(cinema_agreement_revenue.cinema_amount), 0)
        FROM cinema_agreement_revenue,   
             liability_type, liability_category
       WHERE cinema_agreement_revenue.liability_type_id = liability_type.liability_type_id and
             liability_type.liability_category_id = liability_category.liability_category_id and
             liability_category.billing_group = 'Y' and             
             cinema_agreement_revenue.cancelled  = 'N' and
             ( cinema_agreement_revenue.accounting_period >= @fin_year_start )   and
             accounting_period <= @start_date and
             (cinema_agreement_revenue.cinema_agreement_id = @cinema_agreement_id ) And  
             cinema_agreement_revenue.revenue_source = @revenue_source 
    
      SELECT @bill_agreement_to_date = isnull(sum(cinema_agreement_revenue.cinema_amount), 0)
        FROM cinema_agreement_revenue,   
             liability_type, liability_category
       WHERE cinema_agreement_revenue.liability_type_id = liability_type.liability_type_id and
             liability_type.liability_category_id = liability_category.liability_category_id and
             cinema_agreement_revenue.cancelled  = 'N' and
             liability_category.billing_group = 'Y' and             
             ( cinema_agreement_revenue.cinema_agreement_id = @cinema_agreement_id ) And  
             cinema_agreement_revenue.revenue_source = @revenue_source and
             accounting_period <= @start_date 
              /*
              *  Collections
              */            
      SELECT @coll_agreement_to_date = isnull(sum(cinema_agreement_revenue.cinema_amount), 0)
        FROM cinema_agreement_revenue,   
             liability_type, liability_category
       WHERE cinema_agreement_revenue.liability_type_id = liability_type.liability_type_id and
             liability_type.liability_category_id = liability_category.liability_category_id and
             liability_category.collect_group = 'Y' and             
             cinema_agreement_revenue.cancelled  = 'N' and
             ( cinema_agreement_revenue.cinema_agreement_id = @cinema_agreement_id ) And  
             cinema_agreement_revenue.revenue_source = @revenue_source and
             accounting_period = @start_date 
             
      SELECT @coll_year_to_date = isnull(sum(cinema_agreement_revenue.cinema_amount), 0)
        FROM cinema_agreement_revenue,   
             liability_type, liability_category
       WHERE cinema_agreement_revenue.liability_type_id = liability_type.liability_type_id and
             liability_type.liability_category_id = liability_category.liability_category_id and
             liability_category.collect_group = 'Y' and             
             cinema_agreement_revenue.cancelled  = 'N' and
             ( cinema_agreement_revenue.accounting_period >= @fin_year_start )   and
             accounting_period <= @start_date and
             ( cinema_agreement_revenue.cinema_agreement_id = @cinema_agreement_id ) And  
             cinema_agreement_revenue.revenue_source = @revenue_source 
        
      SELECT @coll_agreement_to_date = isnull(sum(cinema_agreement_revenue.cinema_amount), 0)
        FROM cinema_agreement_revenue,   
             liability_type, liability_category
       WHERE cinema_agreement_revenue.liability_type_id = liability_type.liability_type_id and
             liability_type.liability_category_id = liability_category.liability_category_id and
             liability_category.collect_group = 'Y' and             
             cinema_agreement_revenue.cancelled  = 'N' and
             ( cinema_agreement_revenue.cinema_agreement_id = @cinema_agreement_id ) And  
             cinema_agreement_revenue.revenue_source = @revenue_source and
             accounting_period <= @start_date 
        
              /*
              *  Rent Paid
             */                            

       SELECT @rent_paid_this_month = isnull(sum(cinema_agreement_transaction.nett_amount), 0)
        FROM cinema_agreement_transaction,   
             cinema_rent_payment  
       WHERE ( cinema_rent_payment.tran_id = cinema_agreement_transaction.tran_id )   and
             ( cinema_agreement_transaction.cinema_agreement_id = @cinema_agreement_id ) and  
             ( cinema_agreement_transaction.accounting_period = @start_date ) And  
             ( cinema_rent_payment.payment_status_code = 'P' )   and
              cinema_agreement_transaction.accounting_period = @start_date 
             
       SELECT @rent_paid_year_to_date = isnull(sum(cinema_agreement_transaction.nett_amount), 0)
        FROM cinema_agreement_transaction,   
             cinema_rent_payment  
       WHERE ( cinema_rent_payment.tran_id = cinema_agreement_transaction.tran_id )   and
             ( cinema_agreement_transaction.cinema_agreement_id = @cinema_agreement_id ) and  
             ( cinema_agreement_transaction.accounting_period >= @fin_year_start ) And  
             ( cinema_rent_payment.payment_status_code = 'P' )   and
              cinema_agreement_transaction.accounting_period <= @start_date 
             
       SELECT @rent_paid_agreement_to_date = isnull(sum(cinema_agreement_transaction.nett_amount), 0)
        FROM cinema_agreement_transaction,   
             cinema_rent_payment  
       WHERE ( cinema_rent_payment.tran_id = cinema_agreement_transaction.tran_id )   and
             ( cinema_agreement_transaction.cinema_agreement_id = @cinema_agreement_id ) and  
             ( cinema_rent_payment.payment_status_code = 'P' )   and
              cinema_agreement_transaction.accounting_period <= @start_date 
             
        SELECT @bill_this_month = IsNull(@bill_this_month, 0)
        SELECT @bill_year_to_date = IsNull(@bill_year_to_date, 0)
        SELECT @bill_agreement_to_date = IsNull(@bill_agreement_to_date, 0)
        SELECT @coll_this_month = -IsNull(@coll_this_month, 0)
        SELECT @coll_year_to_date = -IsNull(@coll_year_to_date, 0)
        SELECT @coll_agreement_to_date = -IsNull(@coll_agreement_to_date, 0)
        SELECT @rent_paid_this_month = -IsNull(@rent_paid_this_month, 0)
        SELECT @rent_paid_year_to_date = -IsNull(@rent_paid_year_to_date, 0)
        SELECT @rent_paid_agreement_to_date = -IsNull(@rent_paid_agreement_to_date, 0)
        
            Insert into #result_set    
            (   cinema_agreement_id,
                revenue_source,
                bill_this_month,
                bill_year_to_date,
                bill_agreement_to_date,
                coll_this_month,
                coll_year_to_date,
                coll_agreement_to_date,
                rent_paid_this_month,
                rent_paid_year_to_date,
                rent_paid_agreement_to_date)
             values ( @cinema_Agreement_id, 
                        @revenue_source,
                        @bill_this_month,
                        @bill_year_to_date,
                        @bill_agreement_to_date,
                        @coll_this_month,
                        @coll_year_to_date,
                        @coll_agreement_to_date,
                        @rent_paid_this_month,
                        @rent_paid_year_to_date,
                        @rent_paid_agreement_to_date )
                  
        if @@error != 0
            begin
            select @error = 500050
            select @err_msg = 'p_cag_details_report_kpi: INSERT INTO error'
            GOTO PROC_END
        end

         
    fetch cur_revenue_source into @revenue_source
end    

select * from #result_set

PROC_END:
if @cur_revenue_source_open > 0 
    close cur_revenue_source 
        
if @error >= 50000
    begin
       raiserror (@err_msg, 16, 1)        
       return -1
    end
        
return 0
GO
