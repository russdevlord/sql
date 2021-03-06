/****** Object:  StoredProcedure [dbo].[p_slide_invoiced_bill]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_slide_invoiced_bill]
GO
/****** Object:  StoredProcedure [dbo].[p_slide_invoiced_bill]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_slide_invoiced_bill] @sales_territory_id		int,
                                  @benchmark_period	        datetime,
                                  @nett_billings             money   OUTPUT,
                                  @credits                  money   OUTPUT,
                                  @budget                   money   OUTPUT
                                  

as
set nocount on 
/*
 * Declare Valiables
 */ 

declare @error							integer,
	    @sqlstatus					    integer,
        @errorode							integer,
        @leading_week_amount            money,
        @trailing_week_amount           money,
        @end_date                       datetime    
        
        
/*
* If reporting_period is end_date then change it to be benchmark period
*/
select @end_date = end_date
from   accounting_period
where  benchmark_end = @benchmark_period

/*
 * Get Nett Billings
 */
select @nett_billings = isnull(sum( spot.nett_rate * (convert(numeric, scr_date.no_days) / 7 ) ), 0)
        from slide_campaign_spot spot, slide_spot_trans_xref xref, slide_transaction trans, 
             slide_screening_dates_xref scr_date, transaction_type trans_type, slide_campaign_sales_territory terr
        where spot.spot_id = xref.spot_id
        and xref.billing_tran_id = trans.tran_id
        and spot.screening_date = scr_date.screening_date
        and trans_type.trantype_id = trans.tran_type
        and terr.campaign_no = trans.campaign_no
        and terr.sales_territory_id = @sales_territory_id
        and trans_type.trantype_code = 'SBILL'
        and scr_date.benchmark_end = @benchmark_period
 
select @error = @@error
if (@error !=0)
	goto error
            
  select @credits = isnull(sum(nett_amount), 0)
    from slide_transaction trans, transaction_type trans_type, slide_campaign_sales_territory terr
    where trans_type.trantype_id = trans.tran_type
     and terr.campaign_no = trans.campaign_no
     and terr.sales_territory_id = @sales_territory_id
     and trans_type.trantype_code in ('SBCR', 'SUSCR','SAUCR')
     and trans.accounting_period = @end_date

select @error = @@error
if (@error !=0)
	goto error
    
  select @budget  = isnull(billing_target, 0)
  from sales_territory_targets
  where accounting_period = @end_date
  and sales_territory_id = @sales_territory_id

  select @budget  = isnull(@budget, 0)


return 0

error:
	return -1
GO
