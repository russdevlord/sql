/****** Object:  StoredProcedure [dbo].[p_update_screenings_rotation]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_update_screenings_rotation]
GO
/****** Object:  StoredProcedure [dbo].[p_update_screenings_rotation]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_update_screenings_rotation] @carousel_id_new integer,
													  @carousel_id_old integer
as
set nocount on 
update slide_campaign_screening
   set carousel_id = @carousel_id_old
  from slide_screening_dates sds
 where slide_campaign_screening.carousel_id = @carousel_id_new and
		 slide_campaign_screening.carousel_rotation = 'N' and
       slide_campaign_screening.screening_status = 'L' and
		 slide_campaign_screening.screening_date = sds.screening_date and
		 sds.recording_status = 'O'

return 0
GO
