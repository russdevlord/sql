/****** Object:  StoredProcedure [dbo].[p_cag_nett_return_graph]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cag_nett_return_graph]
GO
/****** Object:  StoredProcedure [dbo].[p_cag_nett_return_graph]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create proc [dbo].[p_cag_nett_return_graph] @cinema_agreement_id            int

as

declare @error                          int,
        @accounting_period              datetime,
        @collection_total               money,
        @payment_total                  money,
        @nett_return                    money
        
        
/*
 * Create Temporary Table
 */
 
create table #nett_return
(
    accounting_period       datetime        null,
    nett_return             money           null
)           

/*
 * Declare Cursor
 */

 declare accounting_period_csr cursor static for
  select end_date
    from accounting_period
   where end_date > '1-jul-2000' 
     and status <> 'O'       
order by end_date
     for read only
     
/*
 * Begin Processing
 */
     
open accounting_period_csr
fetch accounting_period_csr into @accounting_period
while(@@fetch_status=0)
begin

     select @collection_total = isnull( -1 * sum(cinema_amount),0)
       from cinema_agreement_revenue,
            liability_type,
            liability_category
      where cinema_agreement_revenue.origin_period = @accounting_period
        and cinema_agreement_revenue.cinema_agreement_id = @cinema_agreement_id
        and cinema_agreement_revenue.liability_type_id =  liability_type.liability_type_id
        and liability_category.liability_category_id =  liability_type.liability_category_id
        and liability_category.liability_category_id in (select liability_category_id from  liability_category_rent_xref where rent_mode in ('C','S'))

        
        
     select @payment_total = isnull(sum(nett_amount),0)
       from cinema_agreement_transaction,
            cinema_rent_payment
      where cinema_agreement_transaction.tran_id = cinema_rent_payment.tran_id
        and cinema_agreement_transaction.cinema_agreement_id = @cinema_agreement_id
        and cinema_agreement_transaction.accounting_period = @accounting_period
    
    insert into #nett_return 
    (accounting_period,
    nett_return)
    values
    (@accounting_period,
    @collection_total - @payment_total)
    
    fetch accounting_period_csr into @accounting_period        
end

select * from #nett_return order by accounting_period

return 0
GO
