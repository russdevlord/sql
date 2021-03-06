/****** Object:  StoredProcedure [dbo].[p_voiceover_delete]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_voiceover_delete]
GO
/****** Object:  StoredProcedure [dbo].[p_voiceover_delete]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_voiceover_delete] @voiceover_id	integer
as
set nocount on 
/*
 * Declare Procedure Variables
 */

declare @error          		integer,
        @rowcount					integer,
        @count						integer

/*
 * Check Line Artwork
 */

select @count = count(voiceover_id)
  from line_artwork
 where voiceover_id = @voiceover_id

select @error = @@error,
       @rowcount = @@rowcount

if(@error != 0 or @rowcount != 1)
begin
	raiserror ('Delete Voiceover: Error Reading Line Artworks.', 16, 1)
	return -1
end

if(@count > 0)
begin
	raiserror ('This voiceover is currently linked to one or more Line Artworks. Delete Request Denied.', 16, 1)
	return -1
end

/*
 * Check Shell Voiceovers
 */

select @count = count(voiceover_id)
  from shell_artwork
 where voiceover_id = @voiceover_id

select @error = @@error,
       @rowcount = @@rowcount

if(@error != 0 or @rowcount != 1)
begin
	raiserror ('Delete Voiceover: Error Reading Shell Artworks.', 16, 1)
	return -1
end

if(@count > 0)
begin
	raiserror ('This voiceover is currently linked to one or more Shell Artworks. Delete Request Denied.', 16, 1)
	return -1
end

/*
 * Check Voiceover Rehash
 */

select @count = count(voiceover_id)
  from voiceover_rehash
 where voiceover_id = @voiceover_id

select @error = @@error,
       @rowcount = @@rowcount

if(@error != 0 or @rowcount != 1)
begin
	raiserror ('Delete Voiceover: Error Reading Voiceover Rehashes.', 16, 1)
	return -1
end

if(@count > 0)
begin
	raiserror ('This voiceover is currently linked to one or more Voiceover Rehashes. Delete Request Denied.', 16, 1)
	return -1
end

/*
 * Check Cue Spots
 */

select @count = count(voiceover_id)
  from cue_spot
 where voiceover_id = @voiceover_id

select @error = @@error,
       @rowcount = @@rowcount

if(@error != 0 or @rowcount != 1)
begin
	raiserror ('Delete Voiceover: Error Reading Cue Spots.', 16, 1)
	return -1
end

if(@count > 0)
begin
	raiserror ('This voiceover is currently linked to one or more Cue Spots. Delete Request Denied.', 16, 1)
	return -1
end

/*
 * Check Request Voiceovers
 */

select @count = count(voiceover_id)
  from request_voiceover
 where voiceover_id = @voiceover_id

select @error = @@error,
       @rowcount = @@rowcount

if(@error != 0 or @rowcount != 1)
begin
	raiserror ('Delete Voiceover: Error Reading Request Voiceovers.', 16, 1)
	return -1
end

if(@count > 0)
begin
	raiserror ('This voiceover is currently linked to one or more Request Voiceovers. Delete Request Denied.', 16, 1)
	return -1
end

/*
 * Check NPU Jobs
 */

select @count = count(voiceover_id)
  from npu_job
 where voiceover_id = @voiceover_id

select @error = @@error,
       @rowcount = @@rowcount

if(@error != 0 or @rowcount != 1)
begin
	raiserror ('Delete Voiceover: Error Reading NPU Jobs.', 16, 1)
	return -1
end

if(@count > 0)
begin
	raiserror ('This voiceover is currently linked to one or more NPU Jobs. Delete Request Denied.', 16, 1)
	return -1
end

/*
 * Begin Transaction
 */

begin transaction

/*
 * Delete Voiceover Keywords
 */

delete from voiceover_keyword
 where voiceover_id = @voiceover_id

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Delete Voiceover: Error Deleting Voiceover Keywords. Delete Request Denied.', 16, 1)
   return @error
end

/*
 * Delete Voiceover Instruction XRefs
 */

delete from voiceover_instruction_xref
 where voiceover_id = @voiceover_id

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Delete Voiceover: Error Deleting Voiceover Instruction References. Delete Request Denied.', 16, 1)
   return @error
end

/*
 * Delete Voiceover Group XRefs
 */

delete from voiceover_group_xref
 where voiceover_id = @voiceover_id

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Delete Voiceover: Error Deleting Voiceover Group References. Delete Request Denied.', 16, 1)
   return @error
end

/*
 * Delete Series Item Voiceovers
 */

delete from series_item_voiceover
 where voiceover_id = @voiceover_id

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Delete Voiceover: Error Deleting Series Item Voiceovers. Delete Request Denied.', 16, 1)
   return @error
end

/*
 * Delete Slide Campaign Voiceovers
 */

delete from slide_campaign_voiceover
 where voiceover_id = @voiceover_id

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Delete Voiceover: Error Deleting Slide Campaign Voiceovers. Delete Request Denied.', 16, 1)
   return @error
end

/*
 * Delete Artwork Voiceovers
 */

delete from artwork_voiceover
 where voiceover_id = @voiceover_id

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Delete Voiceover: Error Deleting Artwork Voiceovers. Delete Request Denied.', 16, 1)
   return @error
end

/*
 * Delete Voiceover
 */

delete from voiceover
 where voiceover_id = @voiceover_id

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Delete Voiceover: Error Deleting Voiceover. Delete Request Denied.', 16, 1)
   return @error
end

/*
 * Commit and Return
 */

commit transaction
return 0
GO
