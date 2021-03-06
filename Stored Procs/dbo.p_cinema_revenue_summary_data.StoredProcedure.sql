/****** Object:  StoredProcedure [dbo].[p_cinema_revenue_summary_data]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cinema_revenue_summary_data]
GO
/****** Object:  StoredProcedure [dbo].[p_cinema_revenue_summary_data]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create proc [dbo].[p_cinema_revenue_summary_data]   @cinema_agreement_id		int,
                                            @start_date                 datetime,
                                            @end_date                   datetime
as
                             
declare @error                          int,
        @mode                           varchar(30),
        @revenue_source_desc            varchar(30),
        @revenue_source                 char(1),
        @collection                     money,
        @billing                        money,
        @payment                        money,
        @agreement_amount               money,
        @loop                           int,
        @finyear_start                  datetime,
        @rowcount                       int

/*
 * Create Temp Tables
 */
 
create table #nett_return_summary
(
    loop                int                 null,
    mode                varchar(30)         null,
    revenue_source      varchar(30)         null,
    collection          money               null,
    billing             money               null,
    payment             money               null,
    agreement_amount    money               null
)


 
/*
 * Initialise Variables
 */
 
if @start_date is null /* presume both null, which means that we are selecting all dates */
begin
    /* Data truncated from 1/7/2000 when all dates selected for analysis/reporting */
    select  @start_date = convert(datetime,'1-jul-2000'),
            @end_date = max(accounting_period)
    from    cinema_agreement_revenue
    where   cinema_agreement_id = @cinema_agreement_id
end

select @finyear_start = finyear_start
  from financial_year 
 where finyear_end >= @end_date
   and finyear_start <= @end_date

select @loop = 1

/*
 * Start Processing
 */

while(@loop < 4)
begin

    select @mode = ''
    if @loop = 1
        select @mode = ' CURRENT'
    if @loop = 2
        select @mode = ' YTD'
    if @loop = 3
        select @mode = ' TOTAL'

	/*
	 * Declare Cursors
	 */
	 
	 declare revenue_source_csr cursor static for
	  select car.revenue_source,
	         crs.revenue_desc
	    from cinema_agreement_revenue car,
	         cinema_revenue_source crs
	   where car.revenue_source = crs.revenue_source
	--     and car.revenue_source != 'P'
	--     and car.revenue_source != 'A'
	     and car.cinema_agreement_id = @cinema_agreement_id
	     and ((@loop = 1
	     and car.origin_period = @end_date)
	      or (@loop = 2
	     and car.origin_period >= @finyear_start
	     and car.origin_period <= @end_date)
	     or (@loop = 3
	     and car.origin_period >= @start_date
	     and car.origin_period <= @end_date))
	group by car.revenue_source,
	         crs.revenue_desc
	order by car.revenue_source,
	         crs.revenue_desc
	     for read only

        
    open revenue_source_csr
    fetch revenue_source_csr into @revenue_source, @revenue_source_desc
    while(@@fetch_status=0)
    begin

         select @collection = isnull(-1 * sum(cinema_amount),0)
           from cinema_agreement_revenue,
                liability_type,
                liability_category
          where cinema_agreement_revenue.cinema_agreement_id = @cinema_agreement_id
            and ((@loop = 1
            and cinema_agreement_revenue.origin_period = @end_date)
             or (@loop = 2
            and cinema_agreement_revenue.origin_period >= @finyear_start
            and cinema_agreement_revenue.origin_period <= @end_date)
            or (@loop = 3
            and cinema_agreement_revenue.origin_period >= @start_date
            and cinema_agreement_revenue.origin_period <= @end_date))
            and cinema_agreement_revenue.liability_type_id =  liability_type.liability_type_id
            and liability_category.liability_category_id =  liability_type.liability_category_id
            and liability_category.liability_category_id in (select liability_category_id from liability_category_rent_xref where rent_mode in ('C', 'S'))
            and cinema_agreement_revenue.revenue_source = @revenue_source

         select @billing = isnull(sum(cinema_amount),0)
           from cinema_agreement_revenue,
                liability_type,
                liability_category
          where ((@loop = 1
            and cinema_agreement_revenue.origin_period = @end_date)
             or (@loop = 2
            and cinema_agreement_revenue.origin_period >= @finyear_start
            and cinema_agreement_revenue.origin_period <= @end_date)
            or (@loop = 3
            and cinema_agreement_revenue.origin_period >= @start_date
            and cinema_agreement_revenue.origin_period <= @end_date))
            and cinema_agreement_revenue.cinema_agreement_id = @cinema_agreement_id
            and cinema_agreement_revenue.liability_type_id =  liability_type.liability_type_id
            and liability_category.liability_category_id =  liability_type.liability_category_id
            and liability_category.liability_category_id in (select liability_category_id from liability_category_rent_xref where rent_mode in ('B', 'I'))
             and cinema_agreement_revenue.revenue_source = @revenue_source
        

        insert into #nett_return_summary
        (
        loop,
        mode,
        revenue_source,
        billing,
        collection
        ) values
        (
        @loop,
        @mode,
        @revenue_source_desc,
        @billing,
        @collection
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
        and ((@loop = 1
        and cinema_agreement_transaction.accounting_period = @end_date)
         or (@loop = 2
        and cinema_agreement_transaction.accounting_period >= @finyear_start
        and cinema_agreement_transaction.accounting_period <= @end_date)
        or (@loop = 3
        and cinema_agreement_transaction.accounting_period >= @start_date
        and cinema_agreement_transaction.accounting_period <= @end_date))

     select @agreement_amount = isnull(sum(cinema_amount),0)
       from cinema_agreement_revenue,
            liability_type,
            liability_category
      where cinema_agreement_revenue.cinema_agreement_id = @cinema_agreement_id
        and cinema_agreement_revenue.liability_type_id =  liability_type.liability_type_id
        and liability_category.liability_category_id =  liability_type.liability_category_id
            and liability_category.liability_category_id in (select liability_category_id from liability_category_rent_xref where rent_mode in ('F'))
        and ((@loop = 1
        and cinema_agreement_revenue.origin_period = @end_date)
         or (@loop = 2
        and cinema_agreement_revenue.origin_period >= @finyear_start
        and cinema_agreement_revenue.origin_period <= @end_date)
        or (@loop = 3
        and cinema_agreement_revenue.origin_period >= @start_date
        and cinema_agreement_revenue.origin_period <= @end_date))

     select @rowcount = count(*)
       from #nett_return_summary
      where loop = @loop

     if @rowcount > 0 
     begin
         update #nett_return_summary
            set payment = @payment / @rowcount,
                agreement_amount = @agreement_amount / @rowcount
          where loop = @loop
     end
     else
     begin
        insert into #nett_return_summary
        (
        loop,
        mode,
        revenue_source,
        billing,
        collection,
        payment,
        agreement_amount) values
        (
        @loop,
        @mode,
        '',
        0,
        0,
        0,
        0
        )
     end
                 
     select @loop = @loop + 1
end

select * from #nett_return_summary order by loop, revenue_source

return 0
GO
