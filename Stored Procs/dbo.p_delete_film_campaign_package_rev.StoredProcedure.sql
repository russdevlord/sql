/****** Object:  StoredProcedure [dbo].[p_delete_film_campaign_package_rev]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_delete_film_campaign_package_rev]
GO
/****** Object:  StoredProcedure [dbo].[p_delete_film_campaign_package_rev]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  PROC [dbo].[p_delete_film_campaign_package_rev]		@package_id		integer,
							@revision_no		integer

as

declare @error          int,
        @rowcount			int


/*
 * Begin Transaction
 */

begin transaction

/*
 * Delete Package revision instructions
 */

delete campaign_package_ins_rev
 where package_id = @package_id and revision_no = @revision_no
select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	return -1
end	


delete campaign_category_rev
 where package_id = @package_id and revision_no = @revision_no
select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	return -1
end	

delete campaign_classification_rev
 where package_id = @package_id and revision_no = @revision_no
select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	return -1
end	

delete campaign_audience_rev
 where package_id = @package_id and revision_no = @revision_no
select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	return -1
end	

delete movie_screening_ins_rev
 where package_id = @package_id and revision_no = @revision_no
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
 where package_id = @package_id and revision_no = @revision_no

/*
 * Delete Package Revision
 */
delete campaign_package_revision
 where package_id = @package_id and revision_no = @revision_no

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
