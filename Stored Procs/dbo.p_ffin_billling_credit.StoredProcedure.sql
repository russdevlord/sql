/****** Object:  StoredProcedure [dbo].[p_ffin_billling_credit]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_ffin_billling_credit]
GO
/****** Object:  StoredProcedure [dbo].[p_ffin_billling_credit]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create PROC [dbo].[p_ffin_billling_credit] 	@billing_tran_id			integer,
									 			@credit_amount 			money

as

set nocount on                              

declare @error							integer,
		@sqlstatus						integer,
		@new_bill_id					integer,
		@new_acomm_id					integer,
		@acomm_amount					money,
		@errorode							integer,
		@tran_type						smallint,
		@tran_desc						varchar(50),
		@rowcount						integer,
		@nett_amount					money,
		@gst_amount						money,
		@gst_rate						numeric(6,4),
		@money_pass						money,
		@campaign_no					integer,
		@tran_id						integer,
		@tran_date						datetime


       


if(@credit_amount > 0)
	select @credit_amount = (@credit_amount * -1)

                                       
 
select @tran_date = getdate()

select @gst_rate = ct.gst_rate,
       @nett_amount = ct.nett_amount,
		 @campaign_no = ct.campaign_no, 
		 @tran_type = ct.tran_type
  from campaign_transaction ct
 where ct.tran_id = @billing_tran_id

if(@tran_type <> 1  or @nett_amount < 0)
begin
	raiserror ('Transaction is not a Billing and/or is a Reversal', 16, 1)
	return -1
end

                             

begin transaction

                                     

select @tran_desc = 'Authorised Credit - Reference: ' + convert(varchar(10),@billing_tran_id)

execute @errorode = p_ffin_create_transaction 'FBILL', @campaign_no, @tran_date, @tran_desc, @credit_amount, @gst_rate, 'Y', @new_bill_id OUTPUT
if (@errorode !=0)
begin
	rollback transaction
	return -1
end

                                                                         

execute @errorode = p_ffin_allocate_transaction @new_bill_id, @billing_tran_id, @credit_amount, @tran_date
if (@errorode !=0)
begin
	rollback transaction
	return -1
end

                                     

execute @errorode = p_ffin_campaign_balances @campaign_no
if (@errorode !=0)
begin
	rollback transaction
	return -1
end
                             

commit transaction
return 0
GO
