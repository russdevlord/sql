/****** Object:  StoredProcedure [dbo].[p_ffin_allocate_transaction]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_ffin_allocate_transaction]
GO
/****** Object:  StoredProcedure [dbo].[p_ffin_allocate_transaction]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_ffin_allocate_transaction]		@from_tran_id		integer,
													@to_tran_id	   		integer,                               
													@nett_amount		money,
													@entry_date			datetime
as

/*
 * Declare Variables
 */

declare @tran_type				 	integer,
        @new_alloc_id				integer,
        @gst_amount			 	 	money,
        @gst_rate			 	 	decimal(6,4),
        @gross_amount			 	money,
        @errorode					 	integer,
        @alloc_amount			 	money,
        @pay_gst					money,
        @rowcount				 	integer,
        @error					 	integer,
        @to_tran_type				integer,
        @to_tran_age				smallint,
        @from_tran_type		 		integer,
        @from_tran_cat		 		char(1),
        @to_tran_cat			 	char(1)
 
/*
 * Get Target Transaction Information
 */

select @gst_rate = ta.gst_rate,
       @to_tran_cat = ct.tran_category,
       @to_tran_type = ct.tran_type,
       @to_tran_age = ct.age_code
  from transaction_allocation ta,
       campaign_transaction ct
 where ta.from_tran_id is null and
       ta.to_tran_id = @to_tran_id and
       ta.to_tran_id = ct.tran_id 

select @error = @@error,
       @rowcount = @@rowcount

if (@error !=0)
begin
	raiserror ('p_ffin_allocate_transaction:  Error retrieving target transaction information.', 16, 1)
	return -1
end

if (@rowcount != 1)
begin
	raiserror (50031, 16, 1)
	return -1
end

/*
 * Get Source Transaction Information
 */

select @from_tran_type = ct.tran_type,
       @from_tran_cat = ct.tran_category
  from campaign_transaction ct
 where ct.tran_id = @from_tran_id

select @error = @@error,
       @rowcount = @@rowcount

if (@error !=0)
begin
	raiserror (@error, 16, 1)
	return -1
end

/*
 * Determine Gross Amount and GST
 */

if (@from_tran_cat = 'C')
begin
	
	/*
    * Move nett amount to gross amount and calulate backwards.
    */

	select @gross_amount = @nett_amount 
	if (@to_tran_cat = 'C')
	begin
		select @nett_amount = 0
		select @gst_amount = 0
	end
	else
	begin
		select @nett_amount = round(@gross_amount / (1 + @gst_rate),2)
		select @gst_amount = @gross_amount - @nett_amount
	end

end
else
begin
	select @gross_amount = round(@nett_amount * (1 + @gst_rate),2)
	select @gst_amount = @gross_amount - @nett_amount
end

/*
 * Determine if this should be allocated to spots
 */

if(@to_tran_cat = 'B')
	select @alloc_amount = @nett_amount
else
	select @alloc_amount = 0

/*
 * Begin Transaction
 */

begin transaction

/*
 * Get Transaction Allocation Id
 */

execute @errorode = p_get_sequence_number 'transaction_allocation',5,@new_alloc_id OUTPUT
if (@errorode !=0)
begin
	rollback transaction
	raiserror ('p_ffin_allocate_transaction: Get transaction_allocation ID failed.', 16, 1)
	return -1
end

/*
 * Insert New Transaction Allocation
 */

insert into transaction_allocation (
       allocation_id,
       from_tran_id,
       to_tran_id,
       nett_amount,
       gst_amount,
       gst_rate,
       gross_amount,
       alloc_amount,
       pay_gst,
       process_period,
       entry_date ) values (
       @new_alloc_id,
       @from_tran_id,
       @to_tran_id,
       @nett_amount,
       @gst_amount,
       @gst_rate,
       @gross_amount,
       @alloc_amount,
       0,
       null,
       @entry_date)

select @error = @@error
if (@error !=0)
begin
	rollback transaction
	return -1
end	

/*
 * Commit and Return
 */

commit transaction
return 0
GO
