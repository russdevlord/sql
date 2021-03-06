/****** Object:  StoredProcedure [dbo].[p_spot_liability_gen]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_spot_liability_gen]
GO
/****** Object:  StoredProcedure [dbo].[p_spot_liability_gen]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_spot_liability_gen] @campaign_no			    int,
                                 @accounting_period	        datetime,
                                 @cutoff					datetime
as

declare @error              	int,
        @advance_ratio			float,
        @csr_open				tinyint,
        @bill_total				money,
        @bill_curr				money,
        @acomm_total			money,
        @acomm_curr				money,
        @bill_adv				money,
        @acomm_adv				money,
        @deductions				money,
        @rent_held				money,
        @uwl					money,
        @spot_id				int,
        @billing_start			datetime,
        @billing_end			datetime,
        @diff					int,
        @no_liability			char(1),
        @atb_flag				tinyint,
        @atb_alloc				money,
        @spot_status			char(1)

select @atb_flag = 0

/*
 * Declare Cursor
 */

 declare spot_csr cursor static for
  select spot_id,
         billing_date,
         spot_status
    from #liability_gen
   where campaign_no = @campaign_no
order by spot_id
     for read only



/*
 * Loop Through Spots for the Campaign
 */

open spot_csr
select @csr_open = 1
fetch spot_csr into @spot_id, @billing_start, @spot_status
while(@@fetch_status = 0)
begin

	/*
    * Calculate In Advance Ratio (Assumes 7 Days)
    */

	select @billing_end = dateadd(day,6,@billing_start)
	select @diff = datediff(day, @cutoff, @billing_end)

	if(@diff < 0)
 		select @advance_ratio = 0
	else
	begin
		if(@diff >= 7)
			select @advance_ratio = 1
		else
			select @advance_ratio = convert(float,@diff) / 7
	end

	/*
	 * Select Total Billings
	 */
	
	select @bill_total = IsNull(sum(spot_amount),0)
	  from spot_liability
	 where spot_id = @spot_id
       and liability_type = 1
       and original_liability = 0
       and cancelled = 0
           
	
	/*
	 * Select Total Agency Comm
	 */
	
	select @acomm_total = IsNull(sum(spot_amount),0)
	  from spot_liability
	 where spot_id = @spot_id and
			 liability_type = 2
       and original_liability = 0
       and cancelled = 0

	/*
	 * Calculate Deductions
	 */
	
	select @deductions = IsNull(sum(spot_amount),0)
	  from spot_liability
	 where spot_id = @spot_id and
			 liability_type not in (1,2)
       and original_liability = 0
       and cancelled = 0
	
	/*
	 * Calculate Current and In Advance Components
	 */
	
	select @bill_adv = @advance_ratio * @bill_total
	select @acomm_adv = @advance_ratio * @acomm_total
	select @bill_curr = @bill_total - @bill_adv
	select @acomm_curr = @acomm_total - @acomm_adv
	
	/*
	 * Calculate Cinema Rent Held
	 */
	
	select @rent_held = IsNull(sum(cinema_rent),0)
	  from spot_liability
	 where spot_id = @spot_id and
          cinema_rent <> 0 and
			 release_period is null
       and original_liability = 0
       and cancelled = 0
	
	/*
	 * Calculate Unweighted Liability
	 */
	
	select @uwl = round(@bill_curr + @acomm_curr + @deductions, 2)

	/*
    * Determine if this is a Liability
    */

	select @no_liability = 'N'

	if(@uwl = 0 and @bill_adv = 0)
	begin
		if(@rent_held = 0)
			select @no_liability = 'Y'
	end			

	/*
    * Update Liability Generation Table
    */

	update #liability_gen
      set adv_ratio = @advance_ratio,
          bill_curr = @bill_curr,
          bill_adv = @bill_adv,
          acomm_curr = @acomm_curr,
          acomm_adv = @acomm_adv,
          uwl = @uwl,
          held_rent = @rent_held,
          no_liability = @no_liability
    where spot_id = @spot_id

	select @error = @@error
	if (@error !=0)
	begin
		rollback transaction
		goto error
	end

	/*
    * Fetch Next Row
    */

	fetch spot_csr into @spot_id, @billing_start, @spot_status

end
close spot_csr
select @csr_open = 0
deallocate spot_csr

/*
 * Return
 */

return 0

/*
 * Error Handler
 */

error:

	if (@csr_open = 1)
   begin
		close spot_csr
		deallocate spot_csr
	end

	return -1
GO
