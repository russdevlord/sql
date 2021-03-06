/****** Object:  StoredProcedure [dbo].[p_sfin_proj_bill_sales_terr]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_sfin_proj_bill_sales_terr]
GO
/****** Object:  StoredProcedure [dbo].[p_sfin_proj_bill_sales_terr]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_sfin_proj_bill_sales_terr] @sales_territory_id		int,
                                        @account_period			datetime,
                                        @account_start			datetime,
                                        @curr_period 			datetime,
                                        @nett_billings			money		OUTPUT,
                                        @campaign_count			integer		OUTPUT,
                                        @suspended			money		OUTPUT,
                                        @cancelled			money		OUTPUT,
                                        @credits			money		OUTPUT

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
 * Initialise Variables
 */

select @nett_billings = 0,
       @campaign_count = 0,
       @suspended = 0,
       @cancelled = 0,
       @credits = 0

/*
 * Get Nett Billings
 */

select @campaign_count = count(distinct isnull(spot.campaign_no,0))
  from slide_campaign_spot spot,
	   slide_campaign sc,
       slide_campaign_sales_territory terr,
		slide_screening_dates_xref ssdx
 where  spot.billing_status in ('B', 'C', 'L' ) and
		spot.campaign_no = sc.campaign_no and
        terr.campaign_no = sc.campaign_no and
		terr.sales_territory_id = @sales_territory_id and
		spot.screening_date = ssdx.screening_date and 
		ssdx.benchmark_end = @account_period


select @error = @@error
if (@error !=0)
	goto error
            
select @nett_billings = sum(isnull(spot.nett_rate,0) * (convert(numeric(6,4),ssdx.no_days)/7.0))
  from slide_campaign_spot spot,
	   slide_campaign sc,
       slide_campaign_sales_territory terr,
		slide_screening_dates_xref ssdx
 where  spot.billing_status in ('B', 'C', 'L' ) and
	    spot.campaign_no = sc.campaign_no and
        terr.campaign_no = sc.campaign_no and
		terr.sales_territory_id = @sales_territory_id and
		spot.screening_date = ssdx.screening_date and 
		ssdx.benchmark_end = @account_period
        
            
select @error = @@error
if (@error !=0)
	goto error
  
/*
 * Calculate Suspended Spots
 */
select @suspended = sum(isnull(spot.nett_rate,0) * (convert(numeric(6,4),ssdx.no_days)/7.0))
  from slide_campaign_spot spot,
	   slide_campaign sc,
       slide_campaign_sales_territory terr,
		slide_screening_dates_xref ssdx
 where  spot.billing_status in ('S', 'X') and
		 spot.spot_status = 'S' and
		 spot.campaign_no = sc.campaign_no and
         terr.campaign_no = sc.campaign_no and
		 terr.sales_territory_id = @sales_territory_id and
		spot.screening_date = ssdx.screening_date and 
		ssdx.benchmark_end = @account_period
            
select @error = @@error
if (@error !=0)
	goto error
            

select @error = @@error
if (@error !=0)
	goto error

/*
 * Calculate Cancelled Spots
 */


select @cancelled = sum(isnull(spot.nett_rate,0) * (convert(numeric(6,4),ssdx.no_days)/7.0))
  from slide_campaign_spot spot,
	   slide_campaign sc,
       slide_campaign_sales_territory terr,
		slide_screening_dates_xref ssdx
 where spot.billing_status = 'X' and
        spot.spot_status <> 'S' and
		spot.campaign_no = sc.campaign_no and
        terr.campaign_no = sc.campaign_no and
		terr.sales_territory_id = @sales_territory_id and
		spot.screening_date = ssdx.screening_date and 
		ssdx.benchmark_end = @account_period
            
select @error = @@error
if (@error !=0)
	goto error


/*
 * Get Credits
 */

if(@account_period = @curr_period)
begin

	select @credits = sum(isnull(nett_amount,0))
	  from  slide_campaign sc,
            slide_transaction st,
            transaction_type tt,
            slide_campaign_sales_territory terr
	 where sc.campaign_no = st.campaign_no and
            terr.campaign_no = sc.campaign_no and
    		terr.sales_territory_id = @sales_territory_id and
		    st.accounting_period = null and
			 st.tran_type = tt.trantype_id and
		  ( tt.trantype_code = 'SUSCR' or
			 tt.trantype_code = 'SAUCR' or
			 tt.trantype_code = 'SBCR' )
             
             

end
else
begin

    select @end_date = end_date from accounting_period where benchmark_end = @account_period
    
	select @credits = sum(isnull(nett_amount,0))
	  from slide_campaign sc,
			 slide_transaction st,
            transaction_type tt,
            slide_campaign_sales_territory terr
	 where sc.campaign_no = st.campaign_no and
            terr.campaign_no = sc.campaign_no and
    		terr.sales_territory_id = @sales_territory_id and
		    st.accounting_period = @end_date and
			 st.tran_type = tt.trantype_id and
		  ( tt.trantype_code = 'SUSCR' or
			 tt.trantype_code = 'SAUCR' or
			 tt.trantype_code = 'SBCR' )

end

select @error = @@error
if (@error !=0)
	goto error

/*
 * Return
 */

return 0

/*
 * Error Handler
 */

error:
	
	return -1
GO
