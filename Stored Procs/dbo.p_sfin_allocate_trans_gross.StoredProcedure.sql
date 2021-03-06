/****** Object:  StoredProcedure [dbo].[p_sfin_allocate_trans_gross]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_sfin_allocate_trans_gross]
GO
/****** Object:  StoredProcedure [dbo].[p_sfin_allocate_trans_gross]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_sfin_allocate_trans_gross] @from_tran_id		integer,
                                        @to_tran_id		integer,
                                        @nett_amount		money,
                                        @gross_amount    money
as

declare @tran_type				 	integer,
        @gst_amount			 	 	money,
        @gst_rate			 	 		decimal(6,4),
        @errorode					 		integer,
        @slide_allocation_id  	integer,
        @alloc_amount			 	money,
        @pay_gst						money,
        @rowcount				 		integer,
        @error					 		integer,
        @to_tran_type				integer,
        @to_tran_age					smallint,
        @from_tran_type		 		integer,
        @from_tran_cat		 		char(1),
        @to_tran_cat			 		char(1)

/*
 * Get Target Transaction Information
 */

select @gst_rate = sa.gst_rate,
       @to_tran_cat = st.tran_category,
       @to_tran_type = st.tran_type,
       @to_tran_age = st.age_code
  from slide_allocation sa,
       slide_transaction st
 where sa.from_tran_id is null and
       sa.to_tran_id = @to_tran_id and
       sa.to_tran_id = st.tran_id 

select @error = @@error,
       @rowcount = @@rowcount

if (@error !=0)
begin
	raiserror ('Transaction Allocation - Error retrieving target transaction information.', 16, 1)
	return -1
end

if (@rowcount != 1)
begin
	raiserror ('p_sfin_allocate_trans_gross : No rows selected', 16, 1)
	return -1
end

/*
 * Get Source Transaction Information
 */

select @from_tran_type = st.tran_type,
       @from_tran_cat = st.tran_category
  from slide_transaction st
 where st.tran_id = @from_tran_id

select @error = @@error,
       @rowcount = @@rowcount

if (@error !=0)
begin
	raiserror ('p_sfin_allocate_trans_gross : select error', 16, 1)
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

	if (@to_tran_cat = 'C')
	begin
		select @gross_amount = @nett_amount 
		select @nett_amount = 0
		select @gst_amount = 0
	end
	else
	begin
		select @gst_amount = @gross_amount - @nett_amount
	end

end
else
begin
	select @gst_amount = @gross_amount - @nett_amount
end

/*
 * Determine if this should be allocated to spots
 */

if(@from_tran_cat = 'C')
begin
	if(@to_tran_cat = 'M' or @to_tran_cat = 'B')
		select @alloc_amount = @nett_amount * -1
	else
		select @alloc_amount = 0
end
else
	select @alloc_amount = 0

/*
 * Begin Transaction
 */

begin transaction

/*
 * Get a New Transaction Id
 */

execute @errorode = p_get_sequence_number 'slide_allocation',5,@slide_allocation_id OUTPUT
if (@errorode !=0)
begin
	rollback transaction
	return -1
end

/*
 * Create Allocation
 */

insert into slide_allocation (
       slide_allocation_id,
       from_tran_id,
       to_tran_id,
       nett_amount,
       gst_amount,
       gst_rate,
       gross_amount,
       alloc_amount,
       pay_gst,
       process_period,
       age_code,
       entry_date ) values (
       @slide_allocation_id,
       @from_tran_id, 
       @to_tran_id,
       @nett_amount,
       @gst_amount,
       @gst_rate,
       @gross_amount,
       @alloc_amount,
       0,
       null,
       @to_tran_age,
       getdate() )

select @error = @@error
if (@error !=0)
begin
	rollback transaction
	return -1
end	

/*
 * Commit Transaction and Return
 */

commit transaction
return 0
GO
