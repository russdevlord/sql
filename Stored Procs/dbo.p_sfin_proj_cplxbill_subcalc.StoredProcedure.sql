/****** Object:  StoredProcedure [dbo].[p_sfin_proj_cplxbill_subcalc]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_sfin_proj_cplxbill_subcalc]
GO
/****** Object:  StoredProcedure [dbo].[p_sfin_proj_cplxbill_subcalc]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create PROC [dbo].[p_sfin_proj_cplxbill_subcalc] @campaign_no				char(7),
                                         @account_period			datetime,
                                         @account_start			datetime,
                                         @curr_period 			datetime,
                                         @nett_billings			money			OUTPUT,
                                         @suspended				money			OUTPUT,
                                         @cancelled				money			OUTPUT,
                                         @credits					money			OUTPUT,
                                         @campaign_count			integer		OUTPUT

as

set nocount on                                                            

declare @error							integer,
	     @sqlstatus					integer,
        @errorode							integer

                                                                

select @campaign_count = 0,
       @nett_billings = 0,
       @suspended = 0,
       @cancelled = 0,
       @credits = 0

                                                                                 

select 		@nett_billings = sum(isnull(spot.nett_rate,0) * (convert(numeric(6,4),ssdx.no_days)/7.0)),
			@campaign_count = isnull(count(distinct spot.campaign_no),0)
from 		slide_campaign_spot spot,
			slide_screening_dates_xref ssdx
where 		spot.campaign_no = @campaign_no and
			(spot.billing_status = 'B' or
			spot.billing_status = 'C' or
			spot.billing_status = 'L' ) and
			spot.screening_date = ssdx.screening_date and
			ssdx.benchmark_end = @account_period

select @error = @@error
if (@error !=0)
	goto error

                                
                                     
select 		@suspended = sum(isnull(spot.nett_rate,0)  * (convert(numeric(6,4),ssdx.no_days)/7.0))
from 		slide_campaign_spot spot,
			slide_screening_dates_xref ssdx
where 		spot.campaign_no = @campaign_no and
			(spot.billing_status = 'S' or
			spot.billing_status = 'X' ) and
			spot.spot_status = 'S' and
			spot.screening_date = ssdx.screening_date and
			ssdx.benchmark_end = @account_period

select @error = @@error
if (@error !=0)
	goto error

                                                                    

select 		@cancelled = sum(isnull(spot.nett_rate,0) * (convert(numeric(6,4),ssdx.no_days)/7.0))
from 		slide_campaign_spot spot,
			slide_screening_dates_xref ssdx
where 		spot.campaign_no = @campaign_no and
			spot.billing_status = 'X' and
			spot.spot_status <> 'S' and
			spot.screening_date = ssdx.screening_date and
			ssdx.benchmark_end = @account_period

select @error = @@error
if (@error !=0)
	goto error

                                                 
                    
if(@account_period = @curr_period)
begin

	select @credits = sum(isnull(nett_amount,0))
	  from slide_campaign sc,
			 slide_transaction st,
			 transaction_type tt
	 where sc.campaign_no = @campaign_no and
          sc.campaign_no = st.campaign_no and
		    st.accounting_period = null and
			 st.tran_type = tt.trantype_id and
		  ( tt.trantype_code = 'SUSCR' or
			 tt.trantype_code = 'SAUCR' or
			 tt.trantype_code = 'SBCR' )

end
else
begin

	select @credits = sum(isnull(nett_amount,0))
	  from slide_campaign sc,
			 slide_transaction st,
			 transaction_type tt
	 where sc.campaign_no = @campaign_no and
	       sc.campaign_no = st.campaign_no and
		    st.accounting_period = @account_period and
			 st.tran_type = tt.trantype_id and
		  ( tt.trantype_code = 'SUSCR' or
			 tt.trantype_code = 'SAUCR' or
			 tt.trantype_code = 'SBCR' )

end

select @error = @@error
if (@error !=0)
	goto error

                          
                  
return 0

                                                  

error:
	
	return -1
GO
