/****** Object:  StoredProcedure [dbo].[p_cinema_revenue_contributors]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cinema_revenue_contributors]
GO
/****** Object:  StoredProcedure [dbo].[p_cinema_revenue_contributors]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create PROC [dbo].[p_cinema_revenue_contributors]  @cinema_agreement_id		    int,
                                           @accounting_period           datetime
as

declare @error     			int,
        @start_date         datetime,
        @end_date           datetime,
        @complex_id         int,
        @collection_amount  numeric(20,6),
        @billing_amount     money,
        @agreement_amount   money,
        @payment_accrual    money,
        @payment_total      numeric(20,6),
        @collection_total   numeric(20,6),
        @count_agr_amt      int
        

/*
 * Create Temp Tables
 */
 
create table #contributors
(   
    complex_id              int             null,
    complex_name            varchar(50)     null,
    collection_amount       money           null,
    billing_amount          money           null,
    agreement_amount        money           null,
    payment_accrual         money           null
) 

/*
 * Initialise Dates
 */     

select  @end_date = @accounting_period

select  @start_date = min(end_date)
from    accounting_period
where   finyear_end = (select finyear_end from accounting_period where end_date = @accounting_period)


/*
 * Start Processing
 */
 
insert into #contributors (
         complex_id,
         complex_name)
  select cinema_agreement_revenue.complex_id,
         complex.complex_name
    from cinema_agreement_revenue,
         complex
   where cinema_agreement_revenue.complex_id = complex.complex_id
     and cinema_agreement_revenue.origin_period >= @start_date
     and cinema_agreement_revenue.origin_period <= @end_date
     and cinema_agreement_revenue.cinema_agreement_id = @cinema_agreement_id
group by cinema_agreement_revenue.complex_id,
         complex.complex_name
order by cinema_agreement_revenue.complex_id,
         complex.complex_name


/*
 * Create Cursor
 */ 

 declare complex_csr cursor static for
  select complex_id
    from #contributors
order by complex_name
     for read only


open complex_csr
fetch complex_csr into @complex_id
while(@@fetch_status=0)
begin
    
     select @collection_amount = 0,
            @billing_amount = 0,
            @agreement_amount =  0,
            @payment_accrual = 0,
            @collection_total = 0,
            @payment_total = 0

     select @collection_amount = -1 * sum(cinema_amount/* * percentage_entitlement*/)
       from cinema_agreement_revenue,
            liability_type,
            liability_category
      where cinema_agreement_revenue.complex_id = @complex_id
        and cinema_agreement_revenue.origin_period >= @start_date
        and cinema_agreement_revenue.origin_period <= @end_date
        and cinema_agreement_revenue.cinema_agreement_id = @cinema_agreement_id
        and cinema_agreement_revenue.liability_type_id =  liability_type.liability_type_id
        and liability_category.liability_category_id =  liability_type.liability_category_id
        and liability_category.liability_category_id in (select liability_category_id from liability_category_rent_xref where rent_mode in ('C', 'S'))
    
     select @collection_total = -1 * sum(cinema_amount/* * percentage_entitlement*/)
       from cinema_agreement_revenue,
            liability_type,
            liability_category
      where cinema_agreement_revenue.origin_period >= @start_date
        and cinema_agreement_revenue.origin_period <= @end_date
        and cinema_agreement_revenue.cinema_agreement_id = @cinema_agreement_id
        and cinema_agreement_revenue.liability_type_id =  liability_type.liability_type_id
        and liability_category.liability_category_id =  liability_type.liability_category_id
        and liability_category.liability_category_id in (select liability_category_id from liability_category_rent_xref where rent_mode in ('C', 'S'))

     select @billing_amount = sum(cinema_amount/* * percentage_entitlement*/)
       from cinema_agreement_revenue,
            liability_type,
            liability_category
      where cinema_agreement_revenue.complex_id = @complex_id
        and cinema_agreement_revenue.origin_period >= @start_date
        and cinema_agreement_revenue.origin_period <= @end_date
        and cinema_agreement_revenue.cinema_agreement_id = @cinema_agreement_id
        and cinema_agreement_revenue.liability_type_id =  liability_type.liability_type_id
        and liability_category.liability_category_id =  liability_type.liability_category_id
        and liability_category.liability_category_id in (select liability_category_id from liability_category_rent_xref where rent_mode in ('B', 'I'))
    
     select @agreement_amount = max(cinema_amount/* * percentage_entitlement*/)
       from cinema_agreement_revenue,
            liability_type,
            liability_category
      where cinema_agreement_revenue.complex_id = @complex_id
        and cinema_agreement_revenue.origin_period >= @start_date
        and cinema_agreement_revenue.origin_period <= @end_date
        and cinema_agreement_revenue.cinema_agreement_id = @cinema_agreement_id
        and cinema_agreement_revenue.liability_type_id =  liability_type.liability_type_id
        and liability_category.liability_category_id =  liability_type.liability_category_id
        and liability_category.liability_category_id in (select liability_category_id from liability_category_rent_xref where rent_mode in ('F'))
        
     select @count_agr_amt = count(distinct origin_period)
       from cinema_agreement_revenue,
            liability_type,
            liability_category
      where cinema_agreement_revenue.complex_id = @complex_id
        and cinema_agreement_revenue.origin_period >= @start_date
        and cinema_agreement_revenue.origin_period <= @end_date
        and cinema_agreement_revenue.cinema_agreement_id = @cinema_agreement_id
        and cinema_agreement_revenue.liability_type_id =  liability_type.liability_type_id
        and liability_category.liability_category_id =  liability_type.liability_category_id
        and liability_category.liability_category_id in (select liability_category_id from liability_category_rent_xref where rent_mode in ('F'))
        

     select  @agreement_amount = @agreement_amount *    @count_agr_amt          
        
        
     select @payment_total = sum(nett_amount)
       from cinema_agreement_transaction,
            cinema_rent_payment
      where cinema_agreement_transaction.tran_id = cinema_rent_payment.tran_id
        and cinema_agreement_transaction.cinema_agreement_id = @cinema_agreement_id
        and cinema_agreement_transaction.accounting_period >= @start_date
        and cinema_agreement_transaction.accounting_period <= @end_date
        
     if @collection_total = 0
        select @payment_accrual = 0
     else
        select @payment_accrual = -1 * @payment_total * (@collection_amount / @collection_total)
        
    
    update #contributors
       set collection_amount = isnull(@collection_amount,0),
           billing_amount = isnull(@billing_amount,0),
           agreement_amount =  isnull(@agreement_amount,0),
           payment_accrual = isnull(@payment_accrual,0)
     where complex_id = @complex_id
    
    fetch complex_csr into @complex_id
end

deallocate complex_csr

/*
 * Select and Return 
 */

select  con.complex_name                 'complex_name',
        @start_date                      'start_date',
        @end_date                        'end_date',
        sum(con.collection_amount)       'collection_amount',
        sum(con.billing_amount)          'billing_amount' ,
        sum(con.agreement_amount)        'agreement_amount',
        sum(con.payment_accrual)         'payment_accrual'
from    #contributors con
group by con.complex_name

return 0
GO
