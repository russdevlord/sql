/****** Object:  StoredProcedure [dbo].[p_banking_tran_summary]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_banking_tran_summary]
GO
/****** Object:  StoredProcedure [dbo].[p_banking_tran_summary]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_banking_tran_summary]	@tran_date		datetime

as

declare		@batch_no			integer,
			@payments			money,
			@deposits			money,
			@reversals			money,
			@nt_in				money,
			@nt_out				money,
			@batch_type			char(1),
			@branch_code		char(3)

/*
 * Create Temporary Table
 */
create table #report (
		branch_code			char(1)			null,
		payments			money			null,
		deposits			money			null,
		reversals			money			null,
		nt_in				money			null,
		nt_out				money			null,
		batch_no			integer			null
)

/*
 * Declare Cursors
 */
 declare batch_csr cursor static for
  select batch_no,
         batch_type,
         branch_code
    from batch_header
   where batch_date = @tran_date and
         batch_type in ('N','P','Z') --non trading, payments or payment reversals.
order by batch_no
     for read only

/*
 * Loop Batch Cursor
 */
open batch_csr
fetch batch_csr into @batch_no, @batch_type, @branch_code
while(@@fetch_status = 0) 
begin

	select	@payments	= 0,
			@deposits	= 0,
			@reversals	= 0,
			@nt_in		= 0,
			@nt_out		= 0

	if(@batch_type = 'P')
	begin

		/*
       * Sum Payment Transactions
       */

		select @payments = sum(st.gross_amount)
        from	slide_transaction st,
				batch_item bi
       where	gross_amount < 0 and
				bi.batch_item_no = st.batch_item_no and
				bi.batch_no = @batch_no and
				st.tran_type = 53 and --Payments
				st.payment_source_id <> 6 and --Debtors
				st.payment_source_id <> 7 and --Non-Trading
				not exists (select 1 from non_trading where non_trading.tran_id = st.tran_id)

		select @payments = isnull(@payments,0)

		select @deposits = sum(st.gross_amount)
        from	slide_transaction st,
				batch_item bi
       where	gross_amount < 0 and
				bi.batch_item_no = st.batch_item_no and
				bi.batch_no = @batch_no and
				st.tran_type = 57 and --Deposits
				st.payment_source_id <> 6 and --Debtors
				st.payment_source_id <> 7 and --Non-Trading
				not exists (select 1 from non_trading where non_trading.tran_id = st.tran_id)

		select @deposits = isnull(@deposits,0)

	end

	if(@batch_type = 'Z')
	begin

		/*
       * Sum Payment Reversals transactions.
       */

		select	@reversals = sum(st.gross_amount)
        from	slide_transaction st,
				batch_item bi
       where	gross_amount > 0 and
				bi.batch_item_no = st.batch_item_no and
				bi.batch_no = @batch_no and
				(st.tran_type = 53 or st.tran_type = 57) and
				st.payment_source_id is null and -- Straight Reversal will not have a Payment Source
				not exists (select 1 from non_trading where non_trading.tran_id = st.tran_id)

		select @reversals = isnull(@reversals,0)

	end

	if(@batch_type = 'N')
	begin

		/*
       * Sum non trading transactions. 
       */

		select @nt_in = sum(nt.amount)
        from	non_trading nt,
				batch_item bi
       where	bi.batch_item_no = nt.batch_item_no and
				bi.batch_no = @batch_no and
				 nt.amount > 0 and
				nt.payment_source_id <> 6 and
				nt.payment_source_id <> 7 and
				tran_id is null

		select	@nt_in = isnull(@nt_in,0)

		select	@nt_out = sum(nt.amount)
        from	non_trading nt,
				batch_item bi
       where	bi.batch_no = @batch_no and
				bi.batch_item_no = nt.batch_item_no and
				 nt.amount < 0 and
				tran_id is null and
				nt.nt_group_no is null

		select @nt_out = isnull(@nt_out,0)

	end

	if(@nt_out <> 0) OR
		 (@nt_in <> 0) OR
		 (@reversals <> 0) OR
		 (@deposits <> 0) OR
		 (@payments <> 0) 
	begin

		insert into #report (
			 branch_code,
			 payments,
			 deposits,
			 reversals,
			 nt_in,
			 nt_out,
			 batch_no ) 
		values ( @branch_code,
			 @payments,
			 @deposits,
			 @reversals,
			 @nt_in,
			 @nt_out,
			 @batch_no )
	end

	fetch batch_csr into @batch_no, @batch_type, @branch_code

end
deallocate batch_csr

 declare branch_csr cursor static for
  select branch_code
    from branch
order by branch_code
     for read only

open branch_csr
fetch branch_csr into @branch_code
while(@@fetch_status = 0) 
begin

	select @payments  = 0,
			@deposits	= 0,
			@reversals	= 0,
			@nt_in		= 0,
			@nt_out		= 0

	/*
	 * Sum Payment transactions.
	 */

	select @payments = sum(st.gross_amount)
	  from	slide_transaction st,
			slide_campaign sc
	 where gross_amount < 0 and
			 st.batch_item_no is null and
          tran_date = @tran_date and
			 sc.campaign_no = st.campaign_no and
			 sc.branch_code = @branch_code and
			 st.tran_type = 53 and --Payments
			 st.payment_source_id <> 6 and --Debtors
			 st.payment_source_id <> 7 and --Non-Trading
			 not exists (select 1 from non_trading where non_trading.tran_id = st.tran_id)

	select @payments = isnull(@payments,0)

	select @deposits = sum(st.gross_amount)
	  from slide_transaction st,
          slide_campaign sc
	 where gross_amount < 0 and
			 st.batch_item_no is null and
          tran_date = @tran_date and
			 sc.campaign_no = st.campaign_no and
			 sc.branch_code = @branch_code and
			 st.tran_type = 57 and --Deposits
			 st.payment_source_id <> 6 and --Debtors
			 st.payment_source_id <> 7 and --Non-Trading
			 not exists (select 1 from non_trading where non_trading.tran_id = st.tran_id)

	select @deposits = isnull(@deposits,0)

	/*
	 * Sum Payment Reversals transactions.
	 */

	select @reversals = sum(st.gross_amount)
	  from slide_transaction st,
          slide_campaign sc
	 where gross_amount > 0 and
			 st.batch_item_no is null and
			 sc.campaign_no = st.campaign_no and
			 sc.branch_code = @branch_code and
          st.tran_date = @tran_date and
			 (st.tran_type = 53 or st.tran_type = 57) and
			 st.payment_source_id is null and -- Straight Reversal will not have a Payment Source
			 not exists (select 1 from non_trading where non_trading.tran_id = st.tran_id)

	select @reversals = isnull(@reversals,0)

	/*
	 * Sum non trading transactions. 
	 */

	select @nt_in = sum(nt.amount)
	  from non_trading nt,
          slide_campaign sc
	 where nt.batch_item_no is null and
			 sc.campaign_no = nt.campaign_no and
			 sc.branch_code = @branch_code and
          tran_date = @tran_date and
			 nt.amount > 0 and
			 nt.payment_source_id <> 6 and
			 nt.payment_source_id <> 7 and
			 tran_id is null

	select @nt_in = isnull(@nt_in,0)

	select @nt_out = sum(nt.amount)
	  from non_trading nt,
          slide_campaign sc
	 where nt.batch_item_no is null and
			 sc.campaign_no = nt.campaign_no and
			 sc.branch_code = @branch_code and
          tran_date = @tran_date and
			 nt.amount < 0 and
			 tran_id is null and
			 nt.nt_group_no is null

	select @nt_out = isnull(@nt_out,0)

	if(@nt_out <> 0) OR
     (@nt_in <> 0) OR
     (@reversals <> 0) OR
     (@deposits <> 0) OR
     (@payments <> 0) 
	begin
		insert into #report (
					branch_code,
					payments,
					deposits,
					reversals,
					nt_in,
					nt_out,
					batch_no ) 
		values ( @branch_code,
					@payments,
					@deposits,
					@reversals,
					@nt_in,
					@nt_out,
					null )
	end

	fetch branch_csr into @branch_code

end
deallocate branch_csr

/*
 * Return Dataset
 */

select r.batch_no,
       b.batch_code,
		 r.branch_code,
		 r.payments,
		 r.deposits,
		 r.reversals,
		 r.nt_in,
		 r.nt_out,
       @tran_date
 -- from #report r,
 --      batch_header b
 --where r.batch_no *= b.batch_no
FROM	#report AS r LEFT OUTER JOIN batch_header AS b ON r.batch_no = b.batch_no


/*
 * Return Success
 */

return 0
GO
