USE [production]
GO
/****** Object:  StoredProcedure [dbo].[p_slide_screening_closure]    Script Date: 11/03/2021 2:30:35 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_slide_screening_closure] @screening_date		datetime
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
 * Update Slide Campaign Spot Status
 */

update slide_campaign_spot
	set spot_status = 'A'
 where spot_status = 'L' and
       screening_date = @screening_date

select @error = @@error
if (@error !=0)
begin
	rollback transaction
	return -1
end	

/*
 * Update Screenings with Cue Sheet for this Period
 */

update slide_campaign_screening
	set screening_status = 'Z'
  from cue_sheet
 where slide_campaign_screening.screening_status = 'A' and
       slide_campaign_screening.complex_id = cue_sheet.complex_id and
       slide_campaign_screening.carousel_id = cue_sheet.carousel_id and
       cue_sheet.screening_date = @screening_date and
       slide_campaign_screening.screening_date = @screening_date

select @error = @@error
if (@error !=0)
begin
	rollback transaction
	return -1
end	

/*
 * Update all other Active Screenings for other branches
 */

update slide_campaign_screening
	set screening_status = 'S'
 where slide_campaign_screening.screening_status = 'A' and
       slide_campaign_screening.screening_date = @screening_date

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
