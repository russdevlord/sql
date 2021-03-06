/****** Object:  StoredProcedure [dbo].[p_artwork_delete]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_artwork_delete]
GO
/****** Object:  StoredProcedure [dbo].[p_artwork_delete]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_artwork_delete] @artwork_id	integer
as

/*
 * Declare Procedure Variables
 */

declare @error          		integer,
        @rowcount					integer,
        @count						integer

/*
 * Check Campaign
 */

select @count = count(artwork_id)
  from slide_campaign_artwork
 where artwork_id = @artwork_id

select @error = @@error,
       @rowcount = @@rowcount

if(@error != 0 or @rowcount != 1)
begin
	raiserror ('Delete Artwork: Error Reading Campaign Artworks.', 16, 1) 
	return -1
end

if(@count > 0)
begin
	raiserror ('This artwork is currently linked to one or more campaigns. Delete Request Denied.', 16, 1) 
	return -1
end

/*
 * Check Series Items
 */

select @count = count(artwork_id)
  from series_item_artwork
 where artwork_id = @artwork_id

select @error = @@error,
       @rowcount = @@rowcount

if(@error != 0 or @rowcount != 1)
begin
	raiserror ('Delete Artwork: Error Reading Series Items.', 16, 1) 
	return -1
end

if(@count > 0)
begin
	raiserror ('This artwork is currently linked to one or more Slide Series. Delete Request Denied.', 16, 1) 
	return -1
end

/*
 * Check Shell Artworks
 */

select @count = count(artwork_id)
  from shell_artwork
 where artwork_id = @artwork_id

select @error = @@error,
       @rowcount = @@rowcount

if(@error != 0 or @rowcount != 1)
begin
	raiserror ('Delete Artwork: Error Reading Shell Artworks.', 16, 1)
	return -1
end

if(@count > 0)
begin
	raiserror ('This artwork is currently linked to one or more Shell Artworks. Delete Request Denied.' , 16, 1)
	return -1
end

/*
 * Check Artwork Rehash
 */

select @count = count(artwork_id)
  from artwork_rehash
 where artwork_id = @artwork_id

select @error = @@error,
       @rowcount = @@rowcount

if(@error != 0 or @rowcount != 1)
begin
	raiserror ('Delete Artwork: Error Reading Artwork Rehashes.', 16, 1)
	return -1
end

if(@count > 0)
begin
	raiserror ('This artwork is currently linked to one or more Artwork Rehashes. Delete Request Denied.', 16, 1)
	return -1
end

/*
 * Check Cue Spots
 */

select @count = count(artwork_id)
  from cue_spot
 where artwork_id = @artwork_id

select @error = @@error,
       @rowcount = @@rowcount

if(@error != 0 or @rowcount != 1)
begin
	raiserror ('Delete Artwork: Error Reading Cue Spots.', 16, 1)
	return -1
end

if(@count > 0)
begin
	raiserror ('This artwork is currently linked to one or more Cue Spots. Delete Request Denied.', 16, 1)
	return -1
end

/*
 * Check Request Voiceovers
 */

select @count = count(artwork_id)
  from request_voiceover
 where artwork_id = @artwork_id

select @error = @@error,
       @rowcount = @@rowcount

if(@error != 0 or @rowcount != 1)
begin
	raiserror ('Delete Artwork: Error Reading Request Voiceovers.', 16, 1)
	return -1
end

if(@count > 0)
begin
	raiserror ('This artwork is currently linked to one or more Request Voiceovers. Delete Request Denied.', 16, 1)
	return -1
end

/*
 * Check Request Artworks
 */

select @count = count(artwork_id)
  from request_artwork
 where artwork_id = @artwork_id

select @error = @@error,
       @rowcount = @@rowcount

if(@error != 0 or @rowcount != 1)
begin
	raiserror ('Delete Artwork: Error Reading Request Artworks.', 16, 1)
	return -1
end

if(@count > 0)
begin
	raiserror ('This artwork is currently linked to one or more Request Artworks. Delete Request Denied.', 16, 1)
	return -1
end

/*
 * Check NPU Job
 */

select @count = count(artwork_id)
  from npu_job
 where artwork_id = @artwork_id

select @error = @@error,
       @rowcount = @@rowcount

if(@error != 0 or @rowcount != 1)
begin
	raiserror ('Delete Artwork: Error Reading NPU Jobs.', 16, 1)
	return -1
end

if(@count > 0)
begin
	raiserror ('This artwork is currently linked to one or more NPU Jobs. Delete Request Denied.', 16, 1)
	return -1
end

/*
 * Check Production Outputs
 */

select @count = count(artwork_id)
  from production_output
 where artwork_id = @artwork_id

select @error = @@error,
       @rowcount = @@rowcount

if(@error != 0 or @rowcount != 1)
begin
	raiserror ('Delete Artwork: Error Reading Production Outputs.', 16, 1)
	return -1
end

if(@count > 0)
begin
	raiserror ('This artwork is currently linked to one or more Production Outputs. Delete Request Denied.', 16, 1)
	return -1
end

/*
 * Begin Transaction
 */

begin transaction

/*
 * Delete Artwork References
 */

delete from artwork_reference
 where artwork_id = @artwork_id

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Delete Artwork: Error Deleting Artwork References. Delete Request Denied.', 16, 1)
   return @error
end

/*
 * Delete Artwork Keywords
 */

delete from artwork_keyword
 where artwork_id = @artwork_id

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Delete Artwork: Error Deleting Artwork Keywords. Delete Request Denied.', 16, 1)
   return @error
end

/*
 * Delete Artwork Group XRefs
 */

delete from artwork_group_xref
 where artwork_id = @artwork_id

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Delete Artwork: Error Deleting Artwork Group References. Delete Request Denied.', 16, 1)
   return @error
end

/*
 * Delete Artwork Voiceovers
 */

delete from artwork_voiceover
 where artwork_id = @artwork_id

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Delete Artwork: Error Deleting Artwork Voiceovers References. Delete Request Denied.', 16, 1)
   return @error
end

/*
 * Delete Artwork Versions
 */

delete from artwork_key_audit
 where artwork_id = @artwork_id

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Delete Artwork: Error Deleting Artwork Key Audit. Delete Request Denied.', 16, 1)
   return @error
end


delete from artwork_version
 where artwork_id = @artwork_id

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Delete Artwork: Error Deleting Artwork Versions. Delete Request Denied.', 16, 1)
   return @error
end

/*
 * Delete Artwork
 */

delete from artwork
 where artwork_id = @artwork_id

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Delete Artwork: Error Deleting Artwork. Delete Request Denied.', 16, 1)
   return @error
end

/*
 * Commit and Return
 */

commit transaction
return 0
GO
