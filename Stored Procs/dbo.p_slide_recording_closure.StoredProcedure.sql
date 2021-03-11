USE [production]
GO
/****** Object:  StoredProcedure [dbo].[p_slide_recording_closure]    Script Date: 11/03/2021 2:30:35 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_slide_recording_closure] @screening_date		datetime
with recompile as
set nocount on 
/*
 * Declare Variables
 */

declare @error        				integer,
        @rowcount     				integer,
        @errorode							integer

/*
 * Begin Transaction
 */

begin transaction

/*
 * Update Voiceover Recording Status
 */

 update voiceover
    set recording_status = 'R'
   from cue_sheet,   
        cue_spot
where ( voiceover.recording_status = 'N' or
        voiceover.recording_status = 'C' ) and
        voiceover.voiceover_id = cue_spot.voiceover_id and
        cue_spot.cue_sheet_id = cue_sheet.cue_sheet_id and
        cue_sheet.screening_date = @screening_date

select @error = @@error
if (@error !=0)
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
