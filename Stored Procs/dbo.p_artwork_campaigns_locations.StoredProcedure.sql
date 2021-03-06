/****** Object:  StoredProcedure [dbo].[p_artwork_campaigns_locations]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_artwork_campaigns_locations]
GO
/****** Object:  StoredProcedure [dbo].[p_artwork_campaigns_locations]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_artwork_campaigns_locations] @artwork_id	integer
as

/*
 * Declare Procedure Variables
 */

declare @error          		integer,
        @rowcount					integer

create table #info
(
   campaign_no			char(7)	null,
   complex_id			integer	null,
   screens				integer	null
)

insert into #info (
       campaign_no, 
       complex_id,
       screens )
--select slide_campaign_artwork.campaign_no,
--       slide_campaign_complex.complex_id,
--       slide_campaign_complex.screens
--  from slide_campaign_artwork,
--       slide_campaign_complex
-- where slide_campaign_artwork.campaign_no *= slide_campaign_complex.campaign_no and
--       slide_campaign_artwork.artwork_id = @artwork_id
SELECT	slide_campaign_artwork.campaign_no, 
		slide_campaign_complex.complex_id, 
		slide_campaign_complex.screens
FROM	slide_campaign_artwork LEFT OUTER JOIN
		slide_campaign_complex ON slide_campaign_artwork.campaign_no = slide_campaign_complex.campaign_no
WHERE   (slide_campaign_artwork.artwork_id = @artwork_id)

--select #info.campaign_no,
--       slide_campaign.name_on_slide,
--       slide_campaign_status.campaign_status_desc,   
--       complex.complex_name,
--       #info.screens
--  from #info,
--       slide_campaign,
--       slide_campaign_status,
--       complex
-- where #info.campaign_no = slide_campaign.campaign_no and
--       slide_campaign.campaign_status = slide_campaign_status.campaign_status_code and
--       #info.complex_id *= complex.complex_id
SELECT	#info.campaign_no, 
		slide_campaign.name_on_slide,
		slide_campaign_status.campaign_status_desc,
		complex.complex_name,
		#info.screens
FROM	slide_campaign_status 
		INNER JOIN slide_campaign ON slide_campaign_status.campaign_status_code = slide_campaign.campaign_status
		CROSS JOIN #info
		CROSS JOIN complex
WHERE	(#info.campaign_no = slide_campaign.campaign_no) AND (#info.complex_id = complex.complex_id)

return 0
GO
