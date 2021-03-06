/****** Object:  StoredProcedure [dbo].[p_slide_campaign_artvo_idc]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_slide_campaign_artvo_idc]
GO
/****** Object:  StoredProcedure [dbo].[p_slide_campaign_artvo_idc]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_slide_campaign_artvo_idc]	@campaign_no	char(7),
                                       @artwork_vo		char(1),
                                       @artvo_id		integer
as

declare @artwork_id		integer,
        @voiceover_id	integer,
        @return_code		tinyint,
        @count				integer

/*
 * Initialise Return Code
 */

select @return_code = 0

/*
 * Process Artwork
 */

if(@artwork_vo = 'A')
begin

	select @artwork_id = @artvo_id

	select @count = isnull(count(voiceover_id),0)
	  from artwork_voiceover
	 where artwork_id = @artwork_id

	if(@count > 0)
	begin

		select @return_code = 1

		select @count = isnull(count(voiceover_id),0)
		  from artwork_voiceover
		 where artwork_id = @artwork_id and
				 voiceover_id in 
				(select voiceover_id 
					from slide_campaign_voiceover 
				  where campaign_no = @campaign_no)

		if(@count > 0)
			select @return_code = 2

	end

end

if(@artwork_vo = 'V')
begin

	select @voiceover_id = @artvo_id

	select @count = isnull(count(artwork_id),0)
	  from artwork_voiceover
	 where voiceover_id = @voiceover_id

	if(@count > 0)
	begin
	
		select @return_code = 1

		select @count = isnull(count(artwork_id),0)
		  from artwork_voiceover
		 where voiceover_id = @voiceover_id and
				 artwork_id in 
				(select artwork_id 
					from slide_campaign_artwork 
				  where campaign_no = @campaign_no)

		if(@count > 0)
			select @return_code = 2

	end

end

/*
 * Return Dataset
 */

select @return_code
return 0
GO
