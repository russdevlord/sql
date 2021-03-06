/****** Object:  StoredProcedure [dbo].[p_certificate_substitution]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_certificate_substitution]
GO
/****** Object:  StoredProcedure [dbo].[p_certificate_substitution]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_certificate_substitution]			@complex_id				int,
																	@screening_date		datetime
																	
as																	

declare			@error										int,
						@original_print_id					int, 
						@substitution_print_id			int, 
						@print_package_id					int, 
						@spot_id									int,
						@item_threed							int,
						@item_medium							char(1),
						@print_row								int,
						@medium_count						int,
						@threed_count							int
						
/*
 * Begin Transaction
 */

begin transaction 
  
/*
 * Change over tag substitution prints
 */
 
declare		print_substitution_csr cursor for 
select			original_print_id,
					substitution_print_id,
					film_campaign_print_substitution.print_package_id,
					spot_id
from			film_campaign_print_substitution,
					print_package,
					campaign_spot
where			campaign_spot.package_id = print_package.package_id
and				campaign_spot.complex_id = film_campaign_print_substitution.complex_id
and				print_package.print_package_id = film_campaign_print_substitution.print_package_id
and				print_package.print_id = film_campaign_print_substitution.original_print_id
and				campaign_spot.complex_id = @complex_id
and				campaign_spot.screening_date = @screening_date
order by		spot_id, 
					original_print_id
for			read only			

open print_substitution_csr
fetch print_substitution_csr into @original_print_id, @substitution_print_id, @print_package_id, @spot_id
while(@@fetch_status = 0)
begin

	select		@item_medium = print_medium,
					@item_threed = three_d_type
	from		certificate_item
	where		spot_reference = @spot_id
	and			print_id = @original_print_id
	
	select	@error = @@error,
			@print_row = @@rowcount
			
	if @error <> 0
	begin
		rollback transaction
		raiserror ('Error: Failed to find subsitution row', 16, 1)
		return -1 
	end
	
	select		@medium_count = count(*)
	from		film_campaign_print_sub_medium
	where		original_print_id = @original_print_id
	and			substitution_print_id = @substitution_print_id
	and			print_package_id = @print_package_id
	and			complex_id = @complex_id
	and			print_medium = @item_medium
	
	select @error = @@error 
	if @error <> 0
	begin
		rollback transaction
		raiserror ('Error: Failed to find subsitution medium', 16, 1)
		return -1 
	end

	select		@threed_count = count(*)
	from		film_campaign_print_sub_threed
	where		original_print_id = @original_print_id
	and			substitution_print_id = @substitution_print_id
	and			print_package_id = @print_package_id
	and			complex_id = @complex_id
	and			three_d_type = @item_threed
	
	select @error = @@error 
	if @error <> 0
	begin
		rollback transaction
		raiserror ('Error: Failed to find subsitution dimension', 16, 1)
		return -1 
	end	

	if @threed_count = 0 and @item_threed > 1
	begin
		select		@item_threed = 1
	
		select		@threed_count = count(*)
		from		film_campaign_print_sub_threed
		where		original_print_id = @original_print_id
		and			substitution_print_id = @substitution_print_id
		and			print_package_id = @print_package_id
		and			complex_id = @complex_id
		and			three_d_type = @item_threed
		
		select @error = @@error 
		if @error <> 0
		begin
			rollback transaction
			raiserror ('Error: Failed to find subsitution dimension', 16, 1)
			return -1 
		end		
	end
	
	if @print_row > 0 and @medium_count = 1 and @threed_count = 1
	begin
	
		update		certificate_item
		set			print_id = @substitution_print_id,
					three_d_type = @item_threed,
					print_medium = @item_medium
		where		spot_reference = @spot_id
		and			print_id = @original_print_id	
		
		select @error = @@error 
		if @error <> 0
		begin
			rollback transaction
			raiserror ('Error: Failed to find subsitution dimension', 16, 1)
			return -1 
		end				
	end

	fetch print_substitution_csr into @original_print_id, @substitution_print_id, @print_package_id, @spot_id
end 

commit transaction
return 0
GO
