/****** Object:  StoredProcedure [dbo].[p_swap_certificate_package]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_swap_certificate_package]
GO
/****** Object:  StoredProcedure [dbo].[p_swap_certificate_package]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create proc [dbo].[p_swap_certificate_package]	@screening_date			datetime,
										@old_package_id			int,
										@new_package_id			int,
										@exhibitor_id			int
												

as

declare			@error						int,
				@print_count_old			int,
				@print_count_new			int,
				@print_loop					int,
				@print_spacing_old			int,
				@shell_section_old			int,
				@shell_block_old			int,
				@print_spacing_new			int,
				@shell_section_new			int,
				@shell_block_new			int,
				@print_id_old				int,
				@print_id_new				int

select			@print_count_old = count(*)
from			print_package
where			package_id = @old_package_id

select	@error = @@ERROR
if (@error != 0)
begin
	raiserror	('Failed to get number of prints in the old package.', 16, 1)
	return -1
end

select			@print_count_new = count(*)
from			print_package
where			package_id = @new_package_id

select	@error = @@ERROR
if (@error != 0)
begin
	raiserror	('Failed to get number of prints in the new package.', 16, 1)
	return -1
end

if @print_count_old <> @print_count_new
begin
	raiserror	('Cannot swap packages with different numbers of prints.', 16, 1)
	return -1
end

set @print_loop = 1

while (@print_loop <= @print_count_old)
begin
	select			@print_spacing_old = print_spacing,
					@shell_section_old = shell_section,
					@shell_block_old = shell_block
	from			print_package
	where			package_id = @old_package_id
	and				print_sequence = @print_loop

	select	@error = @@ERROR
	if (@error != 0)
	begin
		raiserror	('Failed to get print details for the old package.', 16, 1)
		return -1
	end

	select			@print_spacing_new = print_spacing,
					@shell_section_new = shell_section,
					@shell_block_new = shell_block
	from			print_package
	where			package_id = @new_package_id
	and				print_sequence = @print_loop

	select	@error = @@ERROR
	if (@error != 0)
	begin
		raiserror	('Failed to get print details for the new package.', 16, 1)
		return -1
	end

	if @print_spacing_old <> @print_spacing_new 
	begin
		raiserror	('Print Spacing for print sequence %d does not match.', 16, 1, @print_loop)
		return -1
	end

	if @shell_section_old <> @shell_section_new 
	begin
		raiserror	('Shell Section for print sequence %d does not match.', 16, 1, @print_loop)
		return -1
	end

	if @shell_block_old <> @shell_block_new 
	begin
		raiserror	('Shell Block for print sequence %d does not match.', 16, 1, @print_loop)
		return -1
	end

	select @print_loop = @print_loop + 1

end

begin transaction

set @print_loop = 1

while (@print_loop <= @print_count_old)
begin
	select			@print_id_old = print_id
	from			print_package
	where			package_id = @old_package_id
	and				print_sequence = @print_loop

	select	@error = @@ERROR
	if (@error != 0)
	begin
		raiserror	('Failed to get print id for the old package.', 16, 1)
		rollback transaction
		return -1
	end

	select			@print_id_new = print_id
	from			print_package
	where			package_id = @new_package_id
	and				print_sequence = @print_loop

	select	@error = @@ERROR
	if (@error != 0)
	begin
		raiserror	('Failed to get print id for the new package.', 16, 1)
		rollback transaction
		return -1
	end

	update			certificate_item
	set				print_id = @print_id_new
	from			certificate_item
	inner join		campaign_spot on certificate_item.spot_reference = campaign_spot.spot_id
	inner join		complex on campaign_spot.complex_id = complex.complex_id
	where			certificate_item.print_id = @print_id_old
	and				campaign_spot.package_id = @old_package_id
	and				screening_date = @screening_date
	and				(@exhibitor_id = 0 
	or				exhibitor_id = @exhibitor_id)

	select	@error = @@ERROR
	if (@error != 0)
	begin
		raiserror	('Failed to update print id for the new package for print sequence %n.', 16, 1, @print_loop)
		rollback transaction
		return -1
	end

	select @print_loop = @print_loop + 1
end

update			campaign_spot
set				package_id = @new_package_id
from			campaign_spot
inner join		complex on campaign_spot.complex_id = complex.complex_id
where			campaign_spot.package_id = @old_package_id
and				screening_date = @screening_date
and				(@exhibitor_id = 0 
or				exhibitor_id = @exhibitor_id)

select	@error = @@ERROR
if (@error != 0)
begin
	raiserror	('Failed to update spots for the new package.', 16, 1)
	rollback transaction
	return -1
end

commit transaction

return 0
GO
