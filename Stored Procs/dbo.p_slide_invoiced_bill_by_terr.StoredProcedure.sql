/****** Object:  StoredProcedure [dbo].[p_slide_invoiced_bill_by_terr]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_slide_invoiced_bill_by_terr]
GO
/****** Object:  StoredProcedure [dbo].[p_slide_invoiced_bill_by_terr]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
create PROC [dbo].[p_slide_invoiced_bill_by_terr]  @reporting_period  datetime, @country_code char, @mode int                            
as
/* Proc name:   p_slide_invoiced_bill_by_terr
 * Author:      
 * Date:        
 * Description: 
 *
 * PVCS Tags - DO NOT MODIFY
 *
 * $Date:   Jul 27 2004 13:44:04  $ 
 * $Author:   vtyshchenko  $ 
 * $Revision:   1.1  $
 * $Workfile:   slide_invoiced_bill_by_terri.sql  $
 *
*/ 
set nocount on 

declare @proc_name varchar(30)
select  @proc_name = 'p_slide_invoiced_bill_by_terr'
--exec    p_audit_proc @proc_name,'start' -- This is optional. Useful for debugging and performance tuning

declare @sales_territory_id     int,
        @campaign_no             varchar(10),
        @tran_date               datetime,
        @tran_id                 int,
        @tran_desc               varchar(255),
        @nett_amount             money,
        @error                  int,
        @err_msg                varchar(200),
        @curr_period            datetime,
        @end_date               datetime
        

CREATE TABLE   #result
(   country_code            char         Null,
    sales_territory_id      int          Null,
    reporting_period       datetime     Null,
    campaign_no             varchar(10)  Null,
    tran_date               datetime     Null,
    tran_id                 int          Null,
    tran_desc               varchar(255) Null,
    nett_amount             money        Null,
    campaign_desc           varchar(255) Null,
    trans_amount            money        Null
)

/*
* If reporting_period is end_date then change it to be benchmark period
*/
if not exists(select 1 from accounting_period where benchmark_end = @reporting_period)
    select @reporting_period = benchmark_end
    from accounting_period
    where end_date = @reporting_period
    
select @end_date = end_date
from   accounting_period
where  benchmark_end = @reporting_period  

select  @curr_period = max(benchmark_end)
from accounting_period
where status = 'O'

declare territory_csr cursor static for
select  sales_territory_id
from    sales_territory
where   country_code =  @country_code
for read only

open territory_csr

fetch territory_csr into @sales_territory_id
while (@@fetch_status = 0)
    begin
    
    
         insert into #result
        (country_code, sales_territory_id, reporting_period, campaign_no, tran_date,
         tran_id, tran_desc, nett_amount)
         select @country_code, @sales_territory_id, @reporting_period, 
               trans.campaign_no, 
               trans.tran_date, 
               trans.tran_id, 
               trans.tran_desc, 
               isnull(sum( spot.nett_rate * (convert(numeric, scr_date.no_days) / 7 ) ), 0)
        from slide_campaign_spot spot, slide_spot_trans_xref xref, slide_transaction trans, 
             slide_screening_dates_xref scr_date, transaction_type trans_type, slide_campaign_sales_territory terr
        where spot.spot_id = xref.spot_id
        and xref.billing_tran_id = trans.tran_id
        and spot.screening_date = scr_date.screening_date
        and trans_type.trantype_id = trans.tran_type
        and terr.campaign_no = trans.campaign_no
        and terr.sales_territory_id = @sales_territory_id
        and trans_type.trantype_code = 'SBILL'
        and scr_date.benchmark_end = @reporting_period
        group by trans.campaign_no, trans.tran_date, trans.tran_id, trans.tran_desc
        
        select @error = @@error
        if (@error !=0)
        	goto error
        

--        if datediff(day, @curr_period, @reporting_period) = 0
--             insert into #result
--            (country_code, sales_territory_id, reporting_period, campaign_no, tran_date,
--             tran_id, tran_desc, nett_amount)
--             select @country_code, @sales_territory_id, @reporting_period, 
--                   trans.campaign_no, 
--                 trans.tran_date, 
--                   trans.tran_id, 
--                   trans.tran_desc, 
--                   isnull(sum(nett_amount), 0)
--            from slide_transaction trans, transaction_type trans_type, slide_campaign_sales_territory terr
--            where trans_type.trantype_id = trans.tran_type
--            and terr.campaign_no = trans.campaign_no
--            and terr.sales_territory_id = @sales_territory_id
--            and trans_type.trantype_code in ('SBCR', 'SUSCR','SAUCR')
--            and trans.accounting_period is null
--            group by trans.campaign_no, trans.tran_date, trans.tran_id, trans.tran_desc
--        else         
             insert into #result
            (country_code, sales_territory_id, reporting_period, campaign_no, tran_date,
             tran_id, tran_desc, nett_amount)
             select @country_code, @sales_territory_id, @reporting_period, 
                   trans.campaign_no, 
                   trans.tran_date, 
                   trans.tran_id, 
                   trans.tran_desc, 
                   isnull(sum(nett_amount), 0)
            from slide_transaction trans, transaction_type trans_type, slide_campaign_sales_territory terr
            where trans_type.trantype_id = trans.tran_type
            and terr.campaign_no = trans.campaign_no
            and terr.sales_territory_id = @sales_territory_id
            and trans_type.trantype_code in ('SBCR', 'SUSCR','SAUCR')
            and trans.accounting_period = @end_date
            group by trans.campaign_no, trans.tran_date, trans.tran_id, trans.tran_desc
         
        select @error = @@error
        if @error != 0
            goto error 
            
        fetch territory_csr into @sales_territory_id
    end

deallocate territory_csr
---exec p_audit_proc @proc_name,'end'

delete from #result where nett_amount = 0

update #result set campaign_desc = slide_campaign.name_on_slide
from slide_campaign
where slide_campaign.campaign_no = #result.campaign_no

update #result set trans_amount = slide_transaction.nett_amount
from slide_transaction
where slide_transaction.tran_id = #result.tran_id

select * from #result

return 0

error:
    deallocate territory_csr

    if @error >= 50000 -- developer generated errors
        begin
            select @err_msg = @proc_name + ': ' + @err_msg
            raiserror (@err_msg, 16, 1)
        end
    else
        raiserror ( 'p_slide_invoiced_bill_by_terr', 16, 1) 

    return -100
GO
