/****** Object:  StoredProcedure [dbo].[p_cag_allagr_rent_summary_rpt]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cag_allagr_rent_summary_rpt]
GO
/****** Object:  StoredProcedure [dbo].[p_cag_allagr_rent_summary_rpt]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create PROC [dbo].[p_cag_allagr_rent_summary_rpt]		@acc_period_from		datetime, 
														@acc_period_to			datetime,  
														@currency_code			char(3) 

as

/* Proc name:   p_aaa_cag_rent_summary_rpt
 * Author:      Victoria Tyshchenko 
 * Date:        20/02/2004
 * Description: Cinema Agreement Reports -> Cinema Rent Summary report
 *              @mode = 0 do not detail by complex
 *              @mode = 1 details by complex
 *
 * PVCS Tags - DO NOT MODIFY
 *
 * $Date:   Jul 27 2004 13:42:24  $ 
 * $Author:   vtyshchenko  $ 
 * $Revision:   1.2  $
 * $Workfile:   cag_rent_summary_rpt.sql  $
 *
*/ 

declare @error     		    int,
        @err_msg            varchar(150),
        @revenue_source     char(1),
        @billings           money,
        @commission         money,
        @collection         money,
        @payment            money,
        @finyear_end        datetime,
        @accounting_period  datetime,
        @agreement_desc     varchar(50),
        @proc_name          varchar(50),
        @complex_id         int,
        @complex_name       varchar(50),
        @cinema_agreement_id  int,
        @percent            numeric(6,4)

set nocount on




CREATE TABLE #result_set
(   cinema_agreement_id int null,
    agreement_desc      varchar(50) null,
    finyear_end         datetime null,
    accounting_period   datetime null,
    revenue_source      char(1) null,
    billings            money null,
    commission            money null,
    collections         money null,
    payments            money null,
    complex_id          int  null,
    complex_name        varchar(50) null,
    percent_amt             numeric(6,4) null
 )

select @error = 0 

declare     cur_accounting_period cursor static for                               
SELECT   DISTINCT	accounting_period, 
                    finyear_end,
                    cinema_agreement.cinema_agreement_id
FROM                cinema_agreement_revenue,
                    accounting_period,
                    cinema_agreement
WHERE       cinema_agreement_revenue.accounting_period =  accounting_period.end_date
and         accounting_period.end_date >= isnull(@acc_period_from, '1990-01-01')
and         accounting_period.end_date <= isnull(@acc_period_to, '2100-01-01')
and			cinema_agreement.cinema_agreement_id = cinema_agreement_revenue.cinema_agreement_id
and			cinema_agreement.currency_code =	@currency_code


order by    cinema_agreement_revenue.accounting_period

open cur_accounting_period
select @error = @@error
    if @error != 0
        goto error 

fetch cur_accounting_period into @accounting_period, @finyear_end, @cinema_agreement_id
while(@@fetch_status = 0)
    begin

    select @agreement_desc = agreement_desc from cinema_agreement where cinema_Agreement_id = @cinema_Agreement_id

    select @percent = max(percentage_entitlement) from cinema_agreement_policy where cinema_Agreement_id = @cinema_Agreement_id

		declare cur_revenue_source cursor static for                               
		SELECT DISTINCT	revenue_source
		FROM cinema_agreement_revenue
		WHERE  cinema_agreement_id = @cinema_agreement_id 

        open cur_revenue_source
        select @error = @@error
        if @error != 0
                goto error_rev 
        fetch cur_revenue_source into @revenue_source
        while(@@fetch_status = 0)
            begin
				declare cur_complex cursor static for                               
				SELECT DISTINCT	r.complex_id, c.complex_name
				FROM cinema_agreement_revenue r, complex c
				WHERE r.complex_id = c.complex_id
				and r.cinema_agreement_id = @cinema_agreement_id
				and r.revenue_source = @revenue_source

                open cur_complex                     
                fetch cur_complex into @complex_id, @complex_name
                while(@@fetch_status = 0)
                    begin
                     SELECT @billings = abs(isnull(sum(cinema_agreement_revenue.cinema_amount), 0))
                        FROM cinema_agreement_revenue,
                             liability_type, liability_category
                       WHERE cinema_agreement_revenue.liability_type_id = liability_type.liability_type_id and
                             liability_type.liability_category_id = liability_category.liability_category_id and  
                             cinema_agreement_revenue.cancelled = 'N' and
                             cinema_agreement_revenue.accounting_period = @accounting_period and
                            liability_category.billing_group = 'Y' and             
                            ( cinema_agreement_revenue.cinema_agreement_id = @cinema_agreement_id ) And  
                             cinema_agreement_revenue.revenue_source = @revenue_source 
                        and (cinema_agreement_revenue.complex_id = @complex_id or @complex_id = 0) 
                        and liability_category.liability_category_id <> 3

                     SELECT @commission = abs(isnull(sum(cinema_agreement_revenue.cinema_amount), 0))
                        FROM cinema_agreement_revenue,
                             liability_type, liability_category
                       WHERE cinema_agreement_revenue.liability_type_id = liability_type.liability_type_id and
                             liability_type.liability_category_id = liability_category.liability_category_id and  
                             cinema_agreement_revenue.cancelled = 'N' and
                             cinema_agreement_revenue.accounting_period = @accounting_period and
                            liability_category.billing_group = 'Y' and             
                            ( cinema_agreement_revenue.cinema_agreement_id = @cinema_agreement_id ) And  
                             cinema_agreement_revenue.revenue_source = @revenue_source 
                        and (cinema_agreement_revenue.complex_id = @complex_id or @complex_id = 0) 
                        and liability_category.liability_category_id = 3

                     SELECT @collection = abs(isnull(sum(cinema_agreement_revenue.cinema_amount), 0))
                        FROM cinema_agreement_revenue,
                             liability_type, liability_category
                       WHERE cinema_agreement_revenue.liability_type_id = liability_type.liability_type_id and
                             liability_type.liability_category_id = liability_category.liability_category_id and  
                             cinema_agreement_revenue.cancelled = 'N' and
                             cinema_agreement_revenue.accounting_period = @accounting_period and
                            liability_category.collect_group = 'Y' and             
                            ( cinema_agreement_revenue.cinema_agreement_id = @cinema_agreement_id ) And  
                             cinema_agreement_revenue.revenue_source = @revenue_source 
                        and (cinema_agreement_revenue.complex_id = @complex_id or @complex_id = 0)
                         
                    select  @payment = abs(isnull(sum(cinema_agreement_entitlement.nett_amount), 0))
                    from    cinema_agreement_entitlement, 
                            cinema_agreement_transaction, 
                            cinema_rent_payment_allocation,
                            cinema_rent_payment,
                            transaction_type 
                   where	cinema_agreement_transaction.tran_id = cinema_rent_payment_allocation.payment_tran_id
                   and		cinema_rent_payment_allocation.entitlement_tran_id = cinema_agreement_entitlement.tran_id
                   and		cinema_agreement_transaction.tran_id = cinema_rent_payment.tran_id
                   and		cinema_rent_payment.payment_status_code in ('P','D')
                   and		cinema_agreement_transaction.trantype_id = transaction_type.trantype_id
                   and		transaction_type.trantype_code in ('CAGPJ','CAGXP','CAGRP','CAGFP', 'CAGMP') -- payments
                   and		cinema_agreement_transaction.transaction_status_code = 'P'
                   and		cinema_agreement_transaction.process_period = @accounting_period
                   and cinema_agreement_entitlement.revenue_source = @revenue_source
                   and cinema_agreement_entitlement.cinema_agreement_id = @cinema_Agreement_id
                   and (cinema_agreement_entitlement.complex_id = @complex_id or @complex_id = 0)
                         
                if @billings <> 0 or @collection <> 0 or @payment <> 0
                    Insert into #result_set    
                            (   cinema_agreement_id, agreement_desc, finyear_end, accounting_period, revenue_source,
                                billings, commission, collections, payments, complex_id, complex_name, percent_amt)
                     values ( @cinema_Agreement_id,   @agreement_desc, @finyear_end, @accounting_period,  @revenue_source, 
                              @billings, @commission, @collection, @payment, @complex_id, @complex_name, @percent)
                
                    select @error = @@error  
                    if @error != 0
                        GOTO error_rev
                        
                        fetch cur_complex into @complex_id, @complex_name
             break
                end -- complex cursor
                
              deallocate cur_complex
           fetch cur_revenue_source into @revenue_source
        end    
		deallocate cur_revenue_source
	    select @error = @@error  
        if @error != 0
               GOTO error
    fetch cur_accounting_period into @accounting_period, @finyear_end, @cinema_Agreement_id
end

select * from #result_set


deallocate cur_accounting_period

return

error_cplx:
deallocate cur_complex
error_rev:
deallocate cur_revenue_source
error:
deallocate cur_accounting_period
if @error > 50000 
    begin
        select @err_msg = @proc_name + ': ' + @err_msg
        raiserror (@err_msg, 16, 1)
    end
--    else
--         raiserror @error 'Error'

return
GO
