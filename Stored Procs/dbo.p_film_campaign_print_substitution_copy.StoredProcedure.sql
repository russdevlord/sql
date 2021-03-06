/****** Object:  StoredProcedure [dbo].[p_film_campaign_print_substitution_copy]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_film_campaign_print_substitution_copy]
GO
/****** Object:  StoredProcedure [dbo].[p_film_campaign_print_substitution_copy]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_film_campaign_print_substitution_copy]		@print_package_id				int,
																									@source_id							int
																									
as

declare				@error				int,
							@print_id			int

select			@print_id = print_id
from			print_package
where			print_package_id = @print_package_id

begin transaction

delete		film_campaign_print_sub_medium
where		print_package_id = @print_package_id

select		@error = @@error
if @error <> 0
begin
	rollback transaction
	raiserror ('Error: Failed to delete existing substitutions for this print package', 16, 1)
	return -1
end

delete		film_campaign_print_sub_threed
where		print_package_id = @print_package_id

select		@error = @@error
if @error <> 0
begin
	rollback transaction
	raiserror ('Error: Failed to delete existing substitutions for this print package', 16, 1)
	return -1
end

delete		film_campaign_print_substitution
where		print_package_id = @print_package_id

select		@error = @@error
if @error <> 0
begin
	rollback transaction
	raiserror ('Error: Failed to delete existing substitutions for this print package', 16, 1)
	return -1
end

insert		into film_campaign_print_substitution
select		substitution_print_id,
				@print_id,
				complex_id,
				@print_package_id
from		film_campaign_print_substitution
where		print_package_id = @source_id

select		@error = @@error
if @error <> 0
begin
	rollback transaction
	raiserror ('Error: Failed to insert new substitutions for this print package', 16, 1)
	return -1
end

insert		into film_campaign_print_sub_medium
select		print_medium,
				substitution_print_id,
				@print_id,
				complex_id,
				@print_package_id
from		film_campaign_print_sub_medium
where		print_package_id = @source_id

select		@error = @@error
if @error <> 0
begin
	rollback transaction
	raiserror ('Error: Failed to insert new substitutions for this print package', 16, 1)
	return -1
end

insert		into film_campaign_print_sub_threed
select		three_d_type,
				substitution_print_id,
				@print_id,
				complex_id,
				@print_package_id
from		film_campaign_print_sub_threed
where		print_package_id = @source_id

select		@error = @@error
if @error <> 0
begin
	rollback transaction
	raiserror ('Error: Failed to insert new substitutions for this print package', 16, 1)
	return -1
end

return 0
GO
