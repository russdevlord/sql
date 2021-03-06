/****** Object:  StoredProcedure [dbo].[p_calc_film_campaign_payments]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_calc_film_campaign_payments]
GO
/****** Object:  StoredProcedure [dbo].[p_calc_film_campaign_payments]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_calc_film_campaign_payments] @a_campaign_no			integer

as

declare	@gst_exempt					char(1),
			@gst_rate					decimal(6,4),
			@campaign_no				integer,
			@iteration					integer,
			@count						integer,
			@tran_id						integer,
			@gross_amount				money,
			@nett_amount				money,
			@sum_gross_amount			money,
			@sum_nett_amount			money,
			@unalloc_amount			money,
			@payments					money



/*
 * Initialise
 */

select @gst_exempt = gst_exempt
  from film_campaign
 where film_campaign.campaign_no = @a_campaign_no

select @gst_rate = gst_rate
  from film_campaign,
       branch,
       country
 where film_campaign.branch_code = branch.branch_code and
       branch.country_code = country.country_code and
       film_campaign.campaign_no  = @a_campaign_no

/*
 * Initialise Payment Variables
 */

select @payments = 0

/*
 * Declare Cursor
 */

 declare film_tran_csr cursor static for
  select campaign_transaction.tran_id,
         campaign_transaction.gross_amount
    from campaign_transaction
   where campaign_transaction.campaign_no = @a_campaign_no and
         campaign_transaction.tran_category = 'C'
order by campaign_transaction.tran_id
     for read only

/*
 * Calculate Campaign Payments
 */

open film_tran_csr
fetch film_tran_csr into @tran_id, @gross_amount
while(@@fetch_status = 0)
begin

	select @sum_gross_amount = isnull(sum(transaction_allocation.gross_amount), 0),
	       @sum_nett_amount = isnull(sum(transaction_allocation.nett_amount), 0)
	  from transaction_allocation
	 where transaction_allocation.from_tran_id = @tran_id and
	       transaction_allocation.to_tran_id is not null

	/*
    * Assume any Unallocated Portions of the Payment will be allocated
    * at the current rate of GST.
    */

	select @unalloc_amount = @gross_amount - @sum_gross_amount
	select @nett_amount = (@unalloc_amount / (1.0 + @gst_rate)) + @sum_nett_amount

	select @payments = isnull(@payments, 0) + @nett_amount

	/*
    * Fetch Next
    */

	fetch film_tran_csr into @tran_id, @gross_amount

end 

/*
 * Return Dataset
 */

select @a_campaign_no as campaign_no,
       abs(isnull(@payments, 0)) as payments

/*
 * Return
 */

return 0
GO
