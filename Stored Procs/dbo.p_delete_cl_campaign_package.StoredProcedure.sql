/****** Object:  StoredProcedure [dbo].[p_delete_cl_campaign_package]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_delete_cl_campaign_package]
GO
/****** Object:  StoredProcedure [dbo].[p_delete_cl_campaign_package]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_delete_cl_campaign_package]		@package_id		integer

as

declare @error          int,
        @rowcount			int


--Check if the package has been used anywhere.
if exists (select 1
             from cinelight_spot
            where package_id = @package_id)
begin
	raiserror ('Cinelight Campaign Package is allocated to some spots and cannot be deleted.', 16, 1)
	return -1
end

/*
 * Begin Transaction
 */

begin transaction

/*
 * Delete Package from pattern
 */
delete cinelight_pattern
 where package_id = @package_id
select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	return -1
end	


/*
 * Delete Package Prints
 */
delete cinelight_print_package
 where package_id = @package_id

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	return -1
end	

/*
 * Delete Package Burst detail
 */
delete cinelight_package_burst
 where package_id = @package_id
select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	return -1
end	

/*
 * Delete Package Intra Pattern
 */
delete cinelight_package_intra_pattern
 where package_id = @package_id
select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	return -1
end	


/*
 * Delete Package
 */
delete cinelight_package
 where package_id = @package_id

select @error = @@error
if ( @error !=0 )
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
