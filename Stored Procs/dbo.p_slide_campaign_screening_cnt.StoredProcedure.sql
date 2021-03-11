USE [production]
GO
/****** Object:  StoredProcedure [dbo].[p_slide_campaign_screening_cnt]    Script Date: 11/03/2021 2:30:35 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_slide_campaign_screening_cnt] @as_campaign_no char(7)
as
set nocount on 
/*
 * Return Success
 */

select @as_campaign_no as campaign_no,
       count(*) as screenging_count
  from slide_campaign_screening,   
       slide_campaign_spot  
 where slide_campaign_screening.spot_id = slide_campaign_spot.spot_id and  
       slide_campaign_spot.campaign_no = @as_campaign_no

return 0
GO
