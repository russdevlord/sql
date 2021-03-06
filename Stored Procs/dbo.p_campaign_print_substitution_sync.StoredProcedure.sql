/****** Object:  StoredProcedure [dbo].[p_campaign_print_substitution_sync]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_campaign_print_substitution_sync]
GO
/****** Object:  StoredProcedure [dbo].[p_campaign_print_substitution_sync]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_campaign_print_substitution_sync]		@print_package_id			int

as

declare		@error			int

begin transaction

delete		film_campaign_print_sub_threed
where		print_package_id = @print_package_id

select @error = @@error
if @error <> 0
begin
	rollback transaction
	raiserror ('Error deleting  substitution three d records', 16, 1)
	return -1
end

delete		film_campaign_print_sub_medium
where		print_package_id = @print_package_id

select @error = @@error
if @error <> 0
begin
	rollback transaction
	raiserror ('Error deleting  substitution medium records', 16, 1)
	return -1
end

insert		into film_campaign_print_sub_threed
select		three_d_type ,
				substitution_print_id,
				original_print_id,
				complex_id,
				film_campaign_print_substitution.print_package_id
from		film_campaign_print_substitution,
				print_package_three_d
where		film_campaign_print_substitution.print_package_id = print_package_three_d.print_package_id
and			film_campaign_print_substitution.print_package_id = @print_package_id	

select @error = @@error
if @error <> 0
begin
	rollback transaction
	raiserror ('Error inserting substitution dimension records', 16, 1)
	return -1
end

insert		into film_campaign_print_sub_medium
select		print_medium ,
				substitution_print_id,
				original_print_id,
				complex_id,
				film_campaign_print_substitution.print_package_id
from		film_campaign_print_substitution,
				print_package_medium
where		film_campaign_print_substitution.print_package_id = print_package_medium.print_package_id
and			film_campaign_print_substitution.print_package_id = @print_package_id	

select @error = @@error
if @error <> 0
begin
	rollback transaction
	raiserror ('Error inserting substitution medium records', 16, 1)
	return -1
end

commit transaction
return 0
GO
