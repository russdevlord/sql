/****** Object:  StoredProcedure [dbo].[p_slide_recording_closure]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_slide_recording_closure]
GO
/****** Object:  StoredProcedure [dbo].[p_slide_recording_closure]    Script Date: 12/03/2021 10:03:50 AM ******/
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
