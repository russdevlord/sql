/****** Object:  StoredProcedure [dbo].[p_delete_film_campaign_package]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_delete_film_campaign_package]
GO
/****** Object:  StoredProcedure [dbo].[p_delete_film_campaign_package]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE  PROC [dbo].[p_delete_film_campaign_package]		@package_id		integer

as

declare @error          int,
        @rowcount			int


--Check if the package has been used anywhere.
if exists (select 1
             from campaign_spot
            where package_id = @package_id)
begin
	raiserror ('Campaign Package is allocated to some spots and cannot be deleted.', 16, 1)
	return -1
end

/*
 * Begin Transaction
 */

begin transaction

/*
 * Delete Package from pattern
 */
delete film_campaign_pattern
 where package_id = @package_id
select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	return -1
end	

/*
 * Delete Package Instructions
 */
delete campaign_category
 where package_id = @package_id
select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	return -1
end	

delete campaign_classification
 where package_id = @package_id
select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	return -1
end	

delete campaign_audience
 where package_id = @package_id
select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	return -1
end	

delete movie_screening_instructions
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
delete print_package
 where package_id = @package_id

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	return -1
end	


/*
 * Delete Campaign Package Associate
 */
delete campaign_package_associates
 where parent_package_id = @package_id

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	return -1
end	


/*
 * Delete Package Revision week trans xref
 */
delete campaign_package_ins_xref
 where package_id = @package_id
select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	return -1
end	

/*
 * Delete Campaign Package Instructions
 */
delete campaign_package_ins_rev
 where package_id = @package_id

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	return -1
end	

/*
 * Delete Campaign Classification Rev
 */
 
delete campaign_classification_rev
 where package_id = @package_id

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	return -1
end	


/*
 * Delete Campaign Category Rev
 */
 
delete campaign_category_rev
 where package_id = @package_id

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	return -1
end	

/*
 * Delete Campaign Audience Rev
 */
 
delete campaign_audience_rev
 where package_id = @package_id

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	return -1
end	

/*
 * Delete Movie Screening Ins Rev
 */
 
delete movie_screening_ins_rev
 where package_id = @package_id

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	return -1
end	

/*
 * Delete Campaign Package Revision
 */
 
delete campaign_package_revision
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
delete campaign_package
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
