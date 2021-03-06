/****** Object:  StoredProcedure [dbo].[p_cag_revenue_data_report]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cag_revenue_data_report]
GO
/****** Object:  StoredProcedure [dbo].[p_cag_revenue_data_report]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create PROC [dbo].[p_cag_revenue_data_report]      @currency_code			char(3),
																							@start_date					datetime,
																							@end_date					datetime                              
as
 

declare	@error     									int,
				@cinema_agreement_id		    int,
				@cinema_agreement_desc	    varchar(100),
				@complex_id								int,
				@complex_name						varchar(100),
				@collection_amount					numeric(20,6),
				@billing_amount						money,
				@agreement_amount               money,
				@payment									money,
				@payment_total						numeric(20,6),
				@collection_total						numeric(20,6),
				@collection_entitlement			money,
				@billing_entitlement				money,
				@revenue_source_desc           varchar(30),
				@accounting_period					datetime,
				@revenue_source						char(1)


 
create table #revenue_data
(
    accounting_period			datetime					null,
    revenue_source					varchar(30)			null,
    collection_amount				money						null,
    billing_amount					money						null,
    agreement_amount			money						null,
    payment_amount				money						null,
    collection_entitlement		money						null,
    billing_entitlement			money						null,    
    cinema_agreement_id		int							null,
    revenue_source_desc		varchar(30)			null,
    agreement_desc				varchar(100)			null,
    complex_name					varchar(100)			null,
    complex_id							int							null
) 

declare		accounting_period_csr cursor static for
select			accounting_period,
					cinema_agreement_revenue.cinema_agreement_id,
					cinema_agreement_revenue.complex_id,
					complex_name,
					agreement_desc
from			cinema_agreement_revenue, complex, cinema_agreement
where			accounting_period between @start_date and @end_date
and				cinema_agreement.currency_code = @currency_code
and				cinema_agreement_revenue.cinema_agreement_id = cinema_agreement.cinema_agreement_id
and				cinema_agreement_revenue.complex_id = complex.complex_id
group by		accounting_period,
					cinema_agreement_revenue.cinema_agreement_id,
					cinema_agreement_revenue.complex_id,
					complex_name,
					agreement_desc
order by		accounting_period,
					cinema_agreement_revenue.cinema_agreement_id,
					cinema_agreement_revenue.complex_id,
					complex_name,
					agreement_desc
for				read only
     
open accounting_period_csr
fetch accounting_period_csr into @accounting_period,@cinema_agreement_id,@complex_id,@complex_name,@cinema_agreement_desc
while(@@fetch_status=0)
begin
    
	declare	revenue_source_csr cursor static for
	select		car.revenue_source,
					crs.revenue_desc
	from		cinema_agreement_revenue car,
					cinema_revenue_source crs
	where		car.revenue_source = crs.revenue_source
	and			car.cinema_agreement_id = @cinema_agreement_id
	and			car.accounting_period = @accounting_period
	and			car.complex_id = @complex_id
	group by	car.revenue_source,
					crs.revenue_desc
	order by car.revenue_source,
					crs.revenue_desc
	for			read only
	     

    open revenue_source_csr
    fetch revenue_source_csr into @revenue_source, @revenue_source_desc
    while(@@fetch_status=0)
    begin


     select		@collection_amount = 0,
					@billing_amount = 0,
					@agreement_amount =  0,
					@payment = 0,
					@collection_total = 0,
					@payment_total = 0

		select	@collection_amount = isnull(-1 * sum(cinema_amount),0)
		from	cinema_agreement_revenue,
					liability_type,
					liability_category
		where	cinema_agreement_revenue.accounting_period = @accounting_period
		and		cinema_agreement_revenue.cinema_agreement_id = @cinema_agreement_id
		and		cinema_agreement_revenue.complex_id = @complex_id 
		and		cinema_agreement_revenue.liability_type_id =  liability_type.liability_type_id
		and		liability_category.liability_category_id =  liability_type.liability_category_id
		and		liability_category.liability_category_id in (select liability_category_id from liability_category_rent_xref where rent_mode in ('C', 'S'))
		and		cinema_agreement_revenue.revenue_source = @revenue_source

		select	@collection_total = isnull(-1 * sum(cinema_amount),0)
		from	cinema_agreement_revenue,
					liability_type,
					liability_category
		where	cinema_agreement_revenue.accounting_period = @accounting_period
		and		cinema_agreement_revenue.cinema_agreement_id = @cinema_agreement_id
		and		cinema_agreement_revenue.complex_id = @complex_id 
		and		cinema_agreement_revenue.liability_type_id =  liability_type.liability_type_id
		and		liability_category.liability_category_id =  liability_type.liability_category_id
		and		liability_category.liability_category_id in (select liability_category_id from liability_category_rent_xref where rent_mode in ('C', 'S'))

		select	@billing_amount = isnull(sum(cinema_amount),0)
		from	cinema_agreement_revenue,
					liability_type,
					liability_category
		where	cinema_agreement_revenue.accounting_period = @accounting_period
		and		cinema_agreement_revenue.cinema_agreement_id = @cinema_agreement_id
		and		cinema_agreement_revenue.complex_id = @complex_id 
		and		cinema_agreement_revenue.liability_type_id =  liability_type.liability_type_id
		and		liability_category.liability_category_id =  liability_type.liability_category_id
		and		liability_category.liability_category_id in (select liability_category_id from liability_category_rent_xref where rent_mode in ('B', 'I'))
		and		cinema_agreement_revenue.revenue_source = @revenue_source

		select	@collection_entitlement = isnull(-1 * sum(cinema_amount * percentage_entitlement),0)
		from	cinema_agreement_revenue,
					liability_type,
					liability_category
		where	cinema_agreement_revenue.accounting_period = @accounting_period
		and		cinema_agreement_revenue.cinema_agreement_id = @cinema_agreement_id
		and		cinema_agreement_revenue.complex_id = @complex_id 
		and		cinema_agreement_revenue.liability_type_id =  liability_type.liability_type_id
		and		liability_category.liability_category_id =  liability_type.liability_category_id
		and		liability_category.liability_category_id in (select liability_category_id from liability_category_rent_xref where rent_mode in ('C', 'S'))
		and		cinema_agreement_revenue.revenue_source = @revenue_source

		select	@billing_entitlement = isnull(sum(cinema_amount  * percentage_entitlement),0)
		from	cinema_agreement_revenue,
					liability_type,
					liability_category
		where	cinema_agreement_revenue.accounting_period = @accounting_period
		and		cinema_agreement_revenue.cinema_agreement_id = @cinema_agreement_id
		and		cinema_agreement_revenue.complex_id = @complex_id 
		and		cinema_agreement_revenue.liability_type_id =  liability_type.liability_type_id
		and		liability_category.liability_category_id =  liability_type.liability_category_id
		and		liability_category.liability_category_id in (select liability_category_id from liability_category_rent_xref where rent_mode in ('B', 'I'))
		and		cinema_agreement_revenue.revenue_source = @revenue_source

		select	@agreement_amount = isnull(max(cinema_amount),0)
		from	cinema_agreement_revenue,
					liability_type,
					liability_category
		where	cinema_agreement_revenue.accounting_period = @accounting_period
		and		cinema_agreement_revenue.cinema_agreement_id = @cinema_agreement_id
		and		cinema_agreement_revenue.complex_id = @complex_id 
		and		cinema_agreement_revenue.liability_type_id =  liability_type.liability_type_id
		and		liability_category.liability_category_id =  liability_type.liability_category_id
		and		liability_category.liability_category_id in (select liability_category_id from liability_category_rent_xref where rent_mode in ('F'))


		select	@payment_total = isnull(sum(nett_amount),0)
		from	cinema_agreement_transaction,
					cinema_rent_payment
		where	cinema_agreement_transaction.tran_id = cinema_rent_payment.tran_id
		and		cinema_agreement_transaction.cinema_agreement_id = @cinema_agreement_id
		and		cinema_agreement_transaction.accounting_period = @accounting_period
        
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
			payment_amount,
			collection_entitlement,
			billing_entitlement, 
			cinema_agreement_id,
			revenue_source_desc,
			agreement_desc,
			complex_name,
			complex_id	
        )	values
        (
			@accounting_period,
			@revenue_source,
			@collection_amount,
			@billing_amount,
			@agreement_amount,
			@collection_entitlement,
			@billing_entitlement,
			@payment,
			@cinema_agreement_id,
			@revenue_source_desc,
			@cinema_agreement_desc,
			@complex_name,
			@complex_id	
        )
        
        fetch revenue_source_csr into @revenue_source, @revenue_source_desc
    end
    
    close revenue_source_csr
	deallocate revenue_source_csr
    
	fetch accounting_period_csr into @accounting_period,@cinema_agreement_id,@complex_id,@complex_name,@cinema_agreement_desc
end

deallocate accounting_period_csr

select * from #revenue_data order by accounting_period, revenue_source

return 0
GO
