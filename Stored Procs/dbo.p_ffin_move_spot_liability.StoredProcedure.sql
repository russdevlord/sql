/****** Object:  StoredProcedure [dbo].[p_ffin_move_spot_liability]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_ffin_move_spot_liability]
GO
/****** Object:  StoredProcedure [dbo].[p_ffin_move_spot_liability]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create proc [dbo].[p_ffin_move_spot_liability]	@old_spot_id			int,
										@new_spot_id			int,
										@old_complex_id			int,
										@new_complex_id			int

as

set nocount on

declare		@error						int,
			@spot_liability_id			int,
			@new_spot_liability_id		int,
			@errorode						int,
            @creation_period            datetime,
			@database_name				varchar(50),
			@liability_type				int,
			@cancelled					int,
			@original_liability			int,
			@allocation_id				int


declare 	sl_csr cursor static forward_only for
select 		liability_type,
			cancelled,
			original_liability,
			creation_period,
			allocation_id
from 		spot_liability
where 		spot_id = @old_spot_id
and			complex_id = @old_complex_id	
group by 	liability_type,
			cancelled,
			original_liability,
			creation_period,
			allocation_id
order by 	liability_type,
			cancelled,
			original_liability,
			creation_period,
			allocation_id


select @database_name = db_name()


begin transaction

open sl_csr
fetch sl_csr into @liability_type, @cancelled, @original_liability, @creation_period, @allocation_id
while(@@fetch_status=0)
begin

	/*
	 * Get Liability Id
	 */
	
	execute @errorode = p_get_sequence_number 'spot_liability', 5, @new_spot_liability_id OUTPUT
	if(@errorode !=0)
	begin
		goto error
	end

	insert into spot_liability (
				spot_liability_id,
				spot_id,
				complex_id,
				liability_type,
				spot_amount,
				cinema_amount,
				cinema_rent,
				cancelled,
				original_liability,
		        creation_period,
				allocation_id ) 
	select  	@new_spot_liability_id,
				@new_spot_id,
				@new_complex_id,
				@liability_type,
				sum(spot_amount),
				sum(cinema_amount),
				sum(cinema_rent),
				@cancelled,
				@original_liability,
		        @creation_period,
				@allocation_id
	from 		spot_liability 
	where 		liability_type = @liability_type
	and			cancelled = @cancelled
	and 		original_liability = @original_liability
	and			creation_period = @creation_period
	and			allocation_id = @allocation_id
	and			spot_id = @old_spot_id
	and			complex_id = @old_complex_id

	select @error = @@error
	if @error != 0 
	begin
		goto error
	end 	

	/*
	 * Get Liability Id
	 */
	
	execute @errorode = p_get_sequence_number 'spot_liability', 5, @new_spot_liability_id OUTPUT
	if(@errorode !=0)
	begin
		goto error
	end
	
	insert into spot_liability (
				spot_liability_id,
				spot_id,
				complex_id,
				liability_type,
				spot_amount,
				cinema_amount,
				cinema_rent,
				cancelled,
				original_liability,
		        creation_period,
				allocation_id) 
	select  	@new_spot_liability_id,
				@old_spot_id,
				@old_complex_id,
				@liability_type,
				-1 * sum(spot_amount),
				-1 * sum(cinema_amount),
				-1 * sum(cinema_rent),
				@cancelled,
				@original_liability,
		        @creation_period,
				@allocation_id
	from 		spot_liability 
	where 		liability_type = @liability_type
	and			cancelled = @cancelled
	and 		original_liability = @original_liability
	and			creation_period = @creation_period
	and			allocation_id = @allocation_id
	and			spot_id = @old_spot_id
	and			complex_id = @old_complex_id

	select @error = @@error
	if @error != 0 
	begin
		goto error
	end 	



fetch sl_csr into @liability_type, @cancelled, @original_liability, @creation_period, @allocation_id
end

deallocate sl_csr

commit transaction
return 0

error:
	rollback transaction
	deallocate sl_csr	
	return -100
GO
