/****** Object:  StoredProcedure [dbo].[p_cag_analysis_source_dtls]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cag_analysis_source_dtls]
GO
/****** Object:  StoredProcedure [dbo].[p_cag_analysis_source_dtls]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create PROC [dbo].[p_cag_analysis_source_dtls]  @cinema_agreement_id		   int,
                                          @revenue_source              char,
                                          @accounting_period           datetime
as


/* Proc name:   p_cag_analysis_source_dtls
 * Author:      Victoria Tyshchenko
 * Date:        
 * Description: Cinema Agreement Analysis window, Revenue Details Tab, details DW
 *              Retrieves Origin period, collections, billings for <revenue_source - accounting_period>
 *
 * PVCS Tags - DO NOT MODIFY
 *
 * $Date:   Mar 25 2004 11:13:38  $ 
 * $Author:   vtyshchenko  $ 
 * $Revision:   1.1  $
 * $Workfile:   cag_analysis_source_dtls.sql  $
 *
*/ 

declare @error     			            int,
        @end_date                       datetime,
        @collection_amount              numeric(20,6),
        @billing_amount                 money,
        @revenue_source_desc            varchar(30)

/*
 * Create Temp Tables
 */
 
create table #revenue_data
(
    origin_period          datetime        null,
    collection_amount       money           null,
    billing_amount          money           null,
    revenue_source_desc     varchar(30)     null
) 

 SELECT @revenue_source_desc = revenue_desc
   FROM cinema_revenue_source
  where revenue_source = @revenue_source

/*
 * Create Cursor
 */ 

 declare origin_period_csr cursor static for
  select distinct origin_period
    from cinema_agreement_revenue
   where cinema_agreement_id = @cinema_agreement_id
     and accounting_period = @accounting_period
     and revenue_source = @revenue_source
group by origin_period
order by origin_period
     for read only

/*
 * Start Processing
 */
 
open origin_period_csr
fetch origin_period_csr into @end_date
while(@@fetch_status=0)
begin
    
    select @collection_amount = 0,
           @billing_amount = 0

     select @collection_amount = isnull(-1 * sum(cinema_amount),0)
       from cinema_agreement_revenue,
            liability_type,
            liability_category
      where cinema_agreement_revenue.origin_period = @end_date
        and cinema_agreement_revenue.accounting_period = @accounting_period
        and cinema_agreement_revenue.cinema_agreement_id = @cinema_agreement_id
        and cinema_agreement_revenue.liability_type_id =  liability_type.liability_type_id
        and liability_category.liability_category_id =  liability_type.liability_category_id
        and liability_category.liability_category_id in (select liability_category_id from liability_category_rent_xref where rent_mode in ('C','S'))
        and cinema_agreement_revenue.revenue_source = @revenue_source
    
     select @billing_amount = isnull(sum(cinema_amount),0)
       from cinema_agreement_revenue,
            liability_type,
            liability_category
      where cinema_agreement_revenue.origin_period = @end_date
        and cinema_agreement_revenue.accounting_period = @accounting_period
        and cinema_agreement_revenue.cinema_agreement_id = @cinema_agreement_id
        and cinema_agreement_revenue.liability_type_id =  liability_type.liability_type_id
        and liability_category.liability_category_id =  liability_type.liability_category_id
        and liability_category.liability_category_id in (select liability_category_id from liability_category_rent_xref where rent_mode in ('B','I'))
        and cinema_agreement_revenue.revenue_source = @revenue_source
            
--     select @agreement_amount = isnull(max(cinema_amount),0)
--       from cinema_agreement_revenue,
--            liability_type,
--            liability_category
--      where cinema_agreement_revenue.origin_period = @end_date
--        and cinema_agreement_revenue.accounting_period = @accounting_period
--        and cinema_agreement_revenue.cinema_agreement_id = @cinema_agreement_id
--        and cinema_agreement_revenue.liability_type_id =  liability_type.liability_type_id
--        and liability_category.liability_category_id =  liability_type.liability_category_id
--        and liability_category.rent_mode = 'F'        
--        and cinema_agreement_transaction.accounting_period = @end_date
        
        
        insert into #revenue_data
        (
         origin_period,
         collection_amount,
         billing_amount,
         revenue_source_desc
        ) values
        (
         @end_date,
         @collection_amount,
         @billing_amount,
         @revenue_source_desc
        )
        
    fetch origin_period_csr into @end_date
end

deallocate origin_period_csr

/*
 * Select and Return 
 */

select * from #revenue_data order by origin_period

return 0
GO
