/****** Object:  StoredProcedure [dbo].[p_cue_sheet_unavailable]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cue_sheet_unavailable]
GO
/****** Object:  StoredProcedure [dbo].[p_cue_sheet_unavailable]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_cue_sheet_unavailable]	@carousel_id		integer,
												@screening_date	datetime
as

/*
 * Declare Variables
 */

declare @error							integer,
	     @sqlstatus					integer,
        @errorode							integer,
        @cue_sheet_id				integer

/*
 * Begin Transaction
 */

begin transaction

/*
 * Update Screenings
 */

update slide_campaign_screening
   set screening_status = 'Z' --Unallocated
 where slide_campaign_screening.carousel_id = @carousel_id and
		 slide_campaign_screening.screening_date = @screening_date

select @error = @@error
if(@error !=0)
begin
	rollback transaction
	return -1
end

/*
 * Check for existance of Cue Sheet. Delete if Found.
 */

select @cue_sheet_id = isnull(cue_sheet_id,0)
  from cue_sheet
 where carousel_id = @carousel_id and
       screening_date = @screening_date

select @error = @@error
if(@error !=0)
begin
	rollback transaction
	return -1
end

if(@cue_sheet_id > 0)
begin

	/*
    * Delete Cue Spots
    */

	delete cue_spot
    where cue_sheet_id = @cue_sheet_id

	select @error = @@error
	if(@error !=0)
	begin
		rollback transaction
		return -1
	end

	/*
    * Delete Cue Sheet
    */

	delete cue_sheet
    where cue_sheet_id = @cue_sheet_id

	select @error = @@error
	if(@error !=0)
	begin
		rollback transaction
		return -1
	end

end

/*
 * Commit and Return
 */

commit transaction
return 0
GO
