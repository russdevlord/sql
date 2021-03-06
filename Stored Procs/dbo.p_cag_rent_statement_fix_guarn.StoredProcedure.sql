/****** Object:  StoredProcedure [dbo].[p_cag_rent_statement_fix_guarn]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cag_rent_statement_fix_guarn]
GO
/****** Object:  StoredProcedure [dbo].[p_cag_rent_statement_fix_guarn]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create PROC [dbo].[p_cag_rent_statement_fix_guarn]  @cinema_agreement_id  int, 
                                            @statement_no int, 
                                            @mode tinyint as
                                            
/*
* SP p_cag_rent_statement_fix_guarn retrieves data for Fixed Guarantee Summary page of a Cinema Rent Statement
*
*  mode: 1 - details by complex - revenue source
*        0 - details by revenue source only
*/

/* ALL YEAR TO DATE AMOUNTS calculated from 01-01-2004 */                                            

declare @error     				     int,
        @err_msg                     varchar(150),
        @revenue_source              char(1),
        @amount_this_month           money,
        @amount_year_to_date         money,
        @amount_agreement_to_date    money,
        @cur_revenue_source_open     int,
        @cal_year_start              datetime,
        @complex_id                  int,
        @complex_name                char(50),
        @statement_period            datetime,
        @agreement_desc              varchar(50),
        @cnt                         int,
		@abn_no						 varchar(20)

             
CREATE TABLE #result_set
(   cinema_agreement_id         int null,
    complex_id                  int null,
    complex_name                varchar(50) null,
    revenue_source              char(1) null,
    amount_this_month           money null,
    amount_year_to_date         money null,
    amount_agreement_to_date    money null,
    agreement_desc              varchar(50) null,
    accounting_period           datetime null,
    message                     varchar(255) null,
	abn_no						varchar(20)
    )

select @error = 0 
select @statement_period = accounting_period
from cinema_agreement_statement
where cinema_Agreement_id = @cinema_agreement_id and statement_no = @statement_no

select @agreement_desc = agreement_desc, @abn_no = abn_no from cinema_Agreement where cinema_agreement_id = @cinema_Agreement_id

if @mode = 0 
     declare cur_revenue_source cursor static for                               
     SELECT DISTINCT	cinema_agreement_policy.revenue_source, 0, ''
      FROM cinema_agreement_policy
      WHERE  policy_status_code in ('A', 'I') and 
             cinema_agreement_id = @cinema_agreement_id
         
if @mode = 1 
     declare cur_revenue_source cursor static for                               
     SELECT DISTINCT cinema_agreement_policy.revenue_source, complex.complex_id, complex_name
      FROM cinema_agreement_policy, complex
      WHERE  cinema_agreement_policy.complex_id = complex.complex_id and
             policy_status_code in ('A', 'I') and 
             cinema_agreement_id = @cinema_agreement_id

open cur_revenue_source
if @@error != 0
    begin
        select @error = 500050
        select @err_msg = 'p_cag_rent_statement_fix_guarn: OPEN CURSOR error'
        GOTO PROC_END
    end
select @cur_revenue_source_open = 1


fetch cur_revenue_source into @revenue_source, @complex_id, @complex_name
while(@@fetch_status = 0)
    begin

  SELECT @amount_this_month = isnull(sum(cinema_agreement_entitlement.nett_amount),0)
    FROM cinema_agreement_transaction,   
         cinema_rent_payment_allocation,   
         transaction_type,   
         cinema_agreement_entitlement  
   WHERE ( transaction_type.trantype_id = cinema_agreement_transaction.trantype_id ) and  
         ( cinema_rent_payment_allocation.entitlement_tran_id = cinema_agreement_transaction.tran_id ) and  
         ( cinema_agreement_entitlement.tran_id = cinema_agreement_transaction.tran_id ) and  
         ( cinema_agreement_entitlement.revenue_source = @revenue_source ) and  
         (cinema_agreement_entitlement.complex_id = @complex_id or @complex_id = 0) and
         ( cinema_agreement_transaction.cinema_agreement_id = @cinema_agreement_id ) AND  
         ( cinema_agreement_transaction.statement_no = @statement_no ) AND  
         ( cinema_agreement_transaction.show_on_statement = 'Y' ) AND  
         cinema_rent_payment_allocation.payment_tran_id is not null   and         
         ( cinema_agreement_transaction.transaction_status_code <> 'X' ) AND  
         ( cinema_agreement_transaction.trantype_id in (202) )

     SELECT @cal_year_start = accounting_period_b.end_date  
        FROM accounting_period accounting_period_a,   
             accounting_period accounting_period_b  
       WHERE ( accounting_period_a.end_date = @statement_period) and  
             ( accounting_period_a.calendar_end = accounting_period_b.calendar_end )   and
             ( accounting_period_b.period_no = 1 )  
             
  SELECT @amount_year_to_date = isnull(sum(cinema_agreement_entitlement.nett_amount),0)
    FROM cinema_agreement_transaction,   
         cinema_rent_payment_allocation,   
         transaction_type,   
         cinema_agreement_entitlement  
   WHERE ( transaction_type.trantype_id = cinema_agreement_transaction.trantype_id ) and  
         ( cinema_rent_payment_allocation.entitlement_tran_id = cinema_agreement_transaction.tran_id ) and  
         ( cinema_agreement_entitlement.tran_id = cinema_agreement_transaction.tran_id ) and  
         ( cinema_agreement_entitlement.revenue_source = @revenue_source ) and  
         (cinema_agreement_entitlement.complex_id = @complex_id or @complex_id = 0) and
         ( cinema_agreement_transaction.cinema_agreement_id = @cinema_agreement_id ) AND  
         ( cinema_agreement_transaction.accounting_period >= @cal_year_start ) AND  
         ( cinema_agreement_transaction.accounting_period >= '2004-01-01' ) AND  
         ( cinema_agreement_transaction.show_on_statement = 'Y' ) AND  
         cinema_rent_payment_allocation.payment_tran_id is not null   and
         ( cinema_agreement_transaction.transaction_status_code <> 'X' ) AND  
         ( cinema_agreement_transaction.trantype_id in (202) )


  SELECT @amount_agreement_to_date = isnull(sum(cinema_agreement_entitlement.nett_amount),0)
    FROM cinema_agreement_transaction,   
         cinema_rent_payment_allocation,   
         transaction_type,   
         cinema_agreement_entitlement  
   WHERE ( transaction_type.trantype_id = cinema_agreement_transaction.trantype_id ) and  
         ( cinema_rent_payment_allocation.entitlement_tran_id = cinema_agreement_transaction.tran_id ) and  
         ( cinema_agreement_entitlement.tran_id = cinema_agreement_transaction.tran_id ) and  
         ( cinema_agreement_entitlement.revenue_source = @revenue_source ) and  
         (cinema_agreement_entitlement.complex_id = @complex_id or @complex_id = 0) and
         ( cinema_agreement_transaction.cinema_agreement_id = @cinema_agreement_id ) AND  
         ( cinema_agreement_transaction.accounting_period >= @cal_year_start ) AND  
         ( cinema_agreement_transaction.accounting_period >= '2004-01-01' ) AND  
         ( cinema_agreement_transaction.show_on_statement = 'Y' ) AND  
         cinema_rent_payment_allocation.payment_tran_id is not null   and
         ( cinema_agreement_transaction.transaction_status_code <> 'X' )  AND  
         ( cinema_agreement_transaction.trantype_id in (202) )
        
        if IsNull(@amount_this_month, 0) <> 0 or isNull(@amount_year_to_date, 0) <> 0 or IsNull(@amount_agreement_to_date, 0) <> 0
            Insert into #result_set    
            ( cinema_agreement_id,
              complex_id,
              complex_name,
              revenue_source,
              amount_this_month,
              amount_year_to_date,
              amount_agreement_to_date, agreement_desc, accounting_period, message, abn_no  )
             values ( @cinema_Agreement_id,   @complex_id, @complex_name, @revenue_source, @amount_this_month,
                  @amount_year_to_date, @amount_agreement_to_date, @agreement_desc, @statement_period, '', @abn_no)
                  
        if @@error != 0
            begin
            select @error = 500050
            select @err_msg = 'p_cag_rent_statement_fix_guarn: INSERT INTO error'
            GOTO PROC_END
        end

         
    fetch cur_revenue_source into @revenue_source, @complex_id, @complex_name
end    

select @cnt = count(*) from #result_set
if isnull(@cnt,0) = 0
   Insert into #result_set    
       ( cinema_agreement_id,
         complex_id,
         complex_name,
         revenue_source,
         amount_this_month,
         amount_year_to_date,
         amount_agreement_to_date, agreement_desc, accounting_period, message, abn_no  )
   values ( @cinema_Agreement_id,   0, '', '', 0,
            0, 0, @agreement_desc, @statement_period, 'No fixed guarantee transactions found for the cinema agreement.', @abn_no)


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
