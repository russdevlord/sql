/****** Object:  StoredProcedure [dbo].[p_calc_slide_campaign_payments]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_calc_slide_campaign_payments]
GO
/****** Object:  StoredProcedure [dbo].[p_calc_slide_campaign_payments]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_calc_slide_campaign_payments] @a_campaign_no			char(7)

as

declare	@gst_exempt					char(1),
			@gst_rate					decimal(6,4),
			@campaign_no				char(7),
			@iteration					integer,
			@count						integer,
			@tran_id						integer,
			@gross_amount				money,
			@nett_amount				money,
			@sum_gross_amount			money,
			@sum_nett_amount			money,
			@unalloc_amount			money,
			@payments					money,
         @billings					money

/*
 * Create Temporary Tables
 */

create table #campaigns
(
	campaign_no							char(7)				null,
	relation								char(1)				null,
	iteration							integer				null
)



/*
 * Initialise
 */

select @gst_exempt = gst_exempt
  from slide_campaign
 where slide_campaign.campaign_no = @a_campaign_no

select @gst_rate = gst_rate
  from slide_campaign,
       branch,
       country
 where slide_campaign.branch_code = branch.branch_code and
       branch.country_code = country.country_code and
       slide_campaign.campaign_no  = @a_campaign_no

insert into #campaigns (
       campaign_no,
       relation,
       iteration )
select @a_campaign_no, 'O', 1

/*
 * Get Supercede & Extension Parents
 */

select @iteration = 1,
	    @count = 1

while (@count > 0)
begin

	insert into #campaigns (
          campaign_no,
		    relation,
		    iteration )
	select slide_family.parent_campaign,
	       'P',
	       (@iteration + 1)
	  from slide_family,
	       #campaigns
	 where slide_family.child_campaign = #campaigns.campaign_no and
          slide_family.payment_release = 'Y' and
	       (slide_family.relationship_type = 'S'  or
	       slide_family.relationship_type = 'E')and
	       #campaigns.iteration = @iteration and
	       (#campaigns.relation = 'P' or #campaigns.relation = 'O')

	select @count = count(*)
	  from #campaigns
	 where #campaigns.iteration = (@iteration + 1) and
	       #campaigns.relation = 'P'

	select @iteration = @iteration + 1

end

/*
 * Get Supercede & Extension Children
 */

select @iteration = 1,
	    @count = 1

while (@count > 0)
begin

	insert into #campaigns (
          campaign_no,
		    relation,
		    iteration )
	select slide_family.child_campaign,
	       'C',
	       (@iteration + 1)
	  from slide_family,
	       #campaigns
	 where slide_family.parent_campaign = #campaigns.campaign_no and
          slide_family.payment_release = 'Y' and
	       (slide_family.relationship_type = 'S' or
	       slide_family.relationship_type = 'E') and
	       #campaigns.iteration = @iteration and
	       (#campaigns.relation = 'C' or #campaigns.relation = 'O')

	select @count = count(*)
	  from #campaigns
	 where #campaigns.iteration = (@iteration + 1) and
	       #campaigns.relation = 'C'

	select @iteration = @iteration + 1

end

/*
 * Insert Immediate Associates
 */

insert into #campaigns (
       campaign_no,
		 relation,
		 iteration )
select slide_family.child_campaign,
       'A',
       1
  from slide_family
 where slide_family.parent_campaign = @a_campaign_no and
       slide_family.payment_release = 'Y' and
       slide_family.relationship_type = 'A' and
       slide_family.parent_campaign not in ( select campaign_no from #campaigns )

insert into #campaigns (
       campaign_no,
		 relation,
		 iteration )
select slide_family.parent_campaign,
       'A',
       1
  from slide_family
 where slide_family.child_campaign = @a_campaign_no and
       slide_family.payment_release = 'Y' and
       slide_family.relationship_type = 'A' and
       slide_family.child_campaign not in ( select campaign_no from #campaigns )


/*
 * Initialise Payment Variables
 */

select @payments = 0

/*
 * Declare Cursor
 */

 declare slide_tran_csr cursor static for
  select slide_transaction.tran_id,
         slide_transaction.gross_amount
    from slide_transaction,
         #campaigns
   where slide_transaction.campaign_no = #campaigns.campaign_no and
         slide_transaction.tran_category = 'C'
union all
  select slide_transaction.tran_id,
         slide_transaction.gross_amount
    from slide_transaction,
         #campaigns
   where slide_transaction.campaign_no = #campaigns.campaign_no and
         slide_transaction.tran_category = 'X'
order by slide_transaction.tran_id
     for read only

/*
 * Calculate Campaign Payments
 */

open slide_tran_csr
fetch slide_tran_csr into @tran_id, @gross_amount
while(@@fetch_status = 0)
begin

	if @gross_amount < 0 
		select @sum_gross_amount = isnull(sum(slide_allocation.gross_amount), 0),
				 @sum_nett_amount = isnull(sum(slide_allocation.nett_amount), 0)
		  from slide_allocation
		 where slide_allocation.from_tran_id = @tran_id and
				 slide_allocation.to_tran_id is not null and
				 gross_amount < 0
	else
		select @sum_gross_amount = isnull(sum(slide_allocation.gross_amount), 0),
				 @sum_nett_amount = isnull(sum(slide_allocation.nett_amount), 0)
		  from slide_allocation
		 where slide_allocation.to_tran_id = @tran_id and
				 gross_amount > 0


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

	fetch slide_tran_csr into @tran_id, @gross_amount

end 
deallocate slide_tran_csr

select @billings = sum(st.nett_amount)
 from slide_transaction st,
      transaction_type tt,
      #campaigns
 where st.campaign_no = #campaigns.campaign_no and
       st.tran_type = tt.trantype_id and
       tt.trantype_code in ('SBILL','SACOMM','SDISC','SBCR','SUSCR')
/*
 * Return Dataset
 */

select @a_campaign_no as campaign_no,
       abs(isnull(@payments, 0)) as payments,
       abs(isnull(@billings, 0)) as billings
  
/*
 * Return
 */

return 0
GO
