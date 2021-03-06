/****** Object:  StoredProcedure [dbo].[p_sfin_payment_credit]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_sfin_payment_credit]
GO
/****** Object:  StoredProcedure [dbo].[p_sfin_payment_credit]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_sfin_payment_credit] @campaign_no		char(7),
											 @amount				money,
                                  @tran_date			datetime
as

declare @error							integer,
	     @sqlstatus					integer,
        @new_tran_id					integer,
        @errorode							integer,
        @rowcount						integer,
        @gross_amount				money,
        @adj_amount					money,
        @tran_desc					varchar(255),
        @payment_credit				money,
        @tran_id						integer,
        @done							tinyint,
        @total_pay					money,
        @total_credit				money,
        @p_desc						varchar(200),
        @is_closed					char(1)



/*
 * Check Campaign Closed
 */

select @is_closed = is_closed
  from slide_campaign
 where campaign_no = @campaign_no

select @error = @@error
if (@error !=0)
begin
	raiserror ('Payment Credit - Error Retrieving Campaign Information.', 16, 1)
	return -1
end

if(@is_closed = 'Y')
begin
	raiserror ('Payment Credit - Campaign is Closed.', 16, 1)
	return -1
end

/*
 * Check Campaign has suffiecent payments in total to handle the request.
 */

select @total_pay = isnull(sum(gross_amount),0)
  from slide_transaction
 where tran_category = 'C' and
       gross_amount < 0 and
       campaign_no = @campaign_no

select @total_credit = isnull(sum(gross_amount),0)
  from slide_transaction
 where (tran_category = 'X' or tran_category = 'C') and
       gross_amount > 0 and
       campaign_no = @campaign_no

if abs((@total_pay + @total_credit)) < @amount
begin
	raiserror ('Cannot reverse payments. Insuffient payments made for this campaign.', 16, 1)
	return -1
end

/*
 * Begin Transaction
 */

begin transaction

/*
 * Create Payment Adjustment Transaction
 */

select @done = 0

/*
 * Declare Cursor
 */

 declare pay_csr cursor static for
  select tran_id, gross_amount
    from slide_transaction
   where tran_category = 'C' and 
	 	   gross_amount < 0 and
         reversal = 'N' and
         campaign_no = @campaign_no
order by tran_date desc 
     for read only

open pay_csr 
fetch pay_csr into @tran_id, @gross_amount
while (@@fetch_status = 0 and @done = 0)
begin

	select @payment_credit = isnull(sum(sa.gross_amount),0)
	  from slide_allocation sa,
			 slide_transaction st
	 where sa.from_tran_id = @tran_id and
			 sa.to_tran_id = st.tran_id and
			 st.tran_category = 'C'
	
	select @adj_amount = abs(@gross_amount - @payment_credit)
	if @adj_amount > @amount
		select @adj_amount = @amount

	if @adj_amount > 0
	begin

		/*
	 	 * Adjust the payment
		 */

		 exec @errorode = p_sfin_payment_adjustment @tran_id, @tran_date, @adj_amount
		 if (@errorode !=0)
		 begin
			close pay_csr
			rollback transaction
         return -1
  		 end
	end

	select @amount = @amount - @adj_amount
	if @amount = 0
		select @done = 1	

	/*
    * Fetch Next
    */

	fetch pay_csr into @tran_id, @gross_amount

end
close pay_csr
deallocate pay_csr

/*
 * Commit and Return
 */

commit transaction
return 0
GO
