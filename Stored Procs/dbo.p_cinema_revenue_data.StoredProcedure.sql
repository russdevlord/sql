/****** Object:  StoredProcedure [dbo].[p_cinema_revenue_data]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cinema_revenue_data]
GO
/****** Object:  StoredProcedure [dbo].[p_cinema_revenue_data]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create PROC [dbo].[p_cinema_revenue_data]  @cinema_agreement_id		    int,
                                   @accounting_period           datetime
as


 

declare @error     			            int,
        @start_date                     datetime,
        @end_date                       datetime,
        @complex_id                     int,
        @collection_amount              numeric(20,6),
        @billing_amount                 money,
        @agreement_amount               money,
        @payment                        money,
        @payment_total                  numeric(20,6),
        @collection_total               numeric(20,6),
        @collection_entitlement         money,
        @billing_entitlement            money,
        @revenue_source_desc            varchar(30),
        @revenue_source                 char(1)


 
create table #revenue_data
(
    accounting_period       datetime        null,
    revenue_source          varchar(30)     null,
    collection_amount       money           null,
    billing_amount          money           null,
    agreement_amount        money           null,
    payment_amount          money           null,
    collection_entitlement  money           null,
    billing_entitlement     money           null,    
    cinema_Agreement_id     int             null,
    revenue_source_desc     varchar(30)     null
) 

 

 declare accounting_period_csr cursor static for
  select accounting_period
    from cinema_agreement_revenue
   where cinema_agreement_id = @cinema_agreement_id
     and accounting_period <= @accounting_period
group by accounting_period
order by accounting_period
     for read only
     

open accounting_period_csr
fetch accounting_period_csr into @end_date
while(@@fetch_status=0)
begin
    
	 declare revenue_source_csr cursor static for
	  select car.revenue_source,
	         crs.revenue_desc
	    from cinema_agreement_revenue car,
	         cinema_revenue_source crs
	   where car.revenue_source = crs.revenue_source
	     and car.cinema_agreement_id = @cinema_agreement_id
	     and car.accounting_period = @end_date
	group by car.revenue_source,
	         crs.revenue_desc
	order by car.revenue_source,
	         crs.revenue_desc
	     for read only
	     

    open revenue_source_csr
    fetch revenue_source_csr into @revenue_source, @revenue_source_desc
    while(@@fetch_status=0)
    begin


     select @collection_amount = 0,
            @billing_amount = 0,
            @agreement_amount =  0,
            @payment = 0,
            @collection_total = 0,
            @payment_total = 0

     select @collection_amount = isnull(-1 * sum(cinema_amount),0)
       from cinema_agreement_revenue,
            liability_type,
            liability_category
      where cinema_agreement_revenue.accounting_period = @end_date
        and cinema_agreement_revenue.cinema_agreement_id = @cinema_agreement_id
        and cinema_agreement_revenue.liability_type_id =  liability_type.liability_type_id
        and liability_category.liability_category_id =  liability_type.liability_category_id
        and liability_category.liability_category_id in (select liability_category_id from liability_category_rent_xref where rent_mode in ('C', 'S'))
        and cinema_agreement_revenue.revenue_source = @revenue_source
    
     select @collection_total = isnull(-1 * sum(cinema_amount),0)
       from cinema_agreement_revenue,
            liability_type,
            liability_category
      where cinema_agreement_revenue.accounting_period = @end_date
        and cinema_agreement_revenue.cinema_agreement_id = @cinema_agreement_id
        and cinema_agreement_revenue.liability_type_id =  liability_type.liability_type_id
        and liability_category.liability_category_id =  liability_type.liability_category_id
        and liability_category.liability_category_id in (select liability_category_id from liability_category_rent_xref where rent_mode in ('C', 'S'))

     select @billing_amount = isnull(sum(cinema_amount),0)
       from cinema_agreement_revenue,
            liability_type,
            liability_category
      where cinema_agreement_revenue.accounting_period = @end_date
        and cinema_agreement_revenue.cinema_agreement_id = @cinema_agreement_id
        and cinema_agreement_revenue.liability_type_id =  liability_type.liability_type_id
        and liability_category.liability_category_id =  liability_type.liability_category_id
        and liability_category.liability_category_id in (select liability_category_id from liability_category_rent_xref where rent_mode in ('B', 'I'))
        and cinema_agreement_revenue.revenue_source = @revenue_source
            
     select @collection_entitlement = isnull(-1 * sum(cinema_amount * percentage_entitlement),0)
       from cinema_agreement_revenue,
            liability_type,
            liability_category
      where cinema_agreement_revenue.accounting_period = @end_date
        and cinema_agreement_revenue.cinema_agreement_id = @cinema_agreement_id
        and cinema_agreement_revenue.liability_type_id =  liability_type.liability_type_id
        and liability_category.liability_category_id =  liability_type.liability_category_id
        and liability_category.liability_category_id in (select liability_category_id from liability_category_rent_xref where rent_mode in ('C', 'S'))
        and cinema_agreement_revenue.revenue_source = @revenue_source
    
     select @billing_entitlement = isnull(sum(cinema_amount  * percentage_entitlement),0)
       from cinema_agreement_revenue,
            liability_type,
            liability_category
      where cinema_agreement_revenue.accounting_period = @end_date
        and cinema_agreement_revenue.cinema_agreement_id = @cinema_agreement_id
        and cinema_agreement_revenue.liability_type_id =  liability_type.liability_type_id
        and liability_category.liability_category_id =  liability_type.liability_category_id
        and liability_category.liability_category_id in (select liability_category_id from liability_category_rent_xref where rent_mode in ('B', 'I'))
        and cinema_agreement_revenue.revenue_source = @revenue_source

     select @agreement_amount = isnull(max(cinema_amount),0)
       from cinema_agreement_revenue,
            liability_type,
            liability_category
      where cinema_agreement_revenue.accounting_period = @end_date
        and cinema_agreement_revenue.cinema_agreement_id = @cinema_agreement_id
        and cinema_agreement_revenue.liability_type_id =  liability_type.liability_type_id
        and liability_category.liability_category_id =  liability_type.liability_category_id
        and liability_category.liability_category_id in (select liability_category_id from liability_category_rent_xref where rent_mode in ('F'))

        
     select @payment_total = isnull(sum(nett_amount),0)
       from cinema_agreement_transaction,
            cinema_rent_payment
      where cinema_agreement_transaction.tran_id = cinema_rent_payment.tran_id
        and cinema_agreement_transaction.cinema_agreement_id = @cinema_agreement_id
        and cinema_agreement_transaction.accounting_period = @end_date
        
     if @collection_total = 0
        select @payment = 0
     else
        select @payment = -1 * @payment_total * (@collection_amount / @collection_total)
        
        insert into #revenue_data
        (
         accounting_period,
         revenue_source,
         collection_amount,
         billing_amount,
         agreement_amount,
         collection_entitlement,
         billing_entitlement,
         payment_amount,
         cinema_agreement_id,
         revenue_source_desc
        ) values
        (
         @end_date,
         @revenue_source,
         @collection_amount,
         @billing_amount,
         @agreement_amount,
         @collection_entitlement,
         @billing_entitlement,
         @payment,
         @cinema_Agreement_id,
         @revenue_source_desc
        )
        
        
        fetch revenue_source_csr into @revenue_source, @revenue_source_desc
    end
    
    close revenue_source_csr
	deallocate revenue_source_csr
    
     select @payment = isnull(-1 * sum(nett_amount),0)
       from cinema_agreement_transaction,
            cinema_rent_payment
      where cinema_agreement_transaction.tran_id = cinema_rent_payment.tran_id
        and cinema_agreement_transaction.cinema_agreement_id = @cinema_agreement_id
        and cinema_agreement_transaction.accounting_period = @end_date


    
    fetch accounting_period_csr into @end_date
end

deallocate accounting_period_csr


select * from #revenue_data order by accounting_period, revenue_source

return 0
GO
