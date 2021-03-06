/****** Object:  StoredProcedure [dbo].[p_create_voiceover_key]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_create_voiceover_key]
GO
/****** Object:  StoredProcedure [dbo].[p_create_voiceover_key]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_create_voiceover_key]	@voiceover_type	char(1),
                                    @item_key			char(7)

as

/*
 * Declare Procedure Variables
 */

declare  @key			char(10),
			@version		integer


if @voiceover_type = 'A'
begin
	/* 
    * get max version number from voiceovers used with artwork.
    */
	/*select @version = max(voiceover.version_no) 
	from 	voiceover,
			artwork_voiceover av,
			artwork
	where av.voiceover_id = voiceover.voiceover_id and
			av.artwork_id = artwork.artwork_id and
         artwork.artwork_key = @item_key*/

	select @version = max(voiceover.version_no) 
	from 	voiceover
	where voiceover.voiceover_key like @item_key + '%'

	if @version = null 
	begin
		select @version = 1
	end else begin
      select @version = @version + 1
	end
end 
else if @voiceover_type = 'C'
begin
	/* 
    * get max version number from voiceovers in this campaign.
    */
	/*select @version = max(voiceover.version_no) 
	from 	voiceover,
			slide_campaign_voiceover slcv
	where slcv.voiceover_id = voiceover.voiceover_id and
			slcv.campaign_no = @item_key*/

	select @version = max(voiceover.version_no) 
	from 	voiceover
	where voiceover.voiceover_key like @item_key + '%'

	if @version = null
	begin
		select @version = 1
	end else begin
      select @version = @version + 1
	end
end else if @voiceover_type = 'S'
begin
	/* 
    * get max version number from voiceovers in this series.
    */
	/*select @version = max(voiceover.version_no) 
	from 	voiceover,
			series_item_voiceover siv
	where siv.voiceover_id = voiceover.voiceover_id and
			siv.series_item_code = @item_key*/

	select @version = max(voiceover.version_no) 
	from 	voiceover
	where voiceover.voiceover_key like @item_key + '%'

	if @version = null 
	begin
		select @version = 1
	end else begin
      select @version = @version + 1
	end
end

/*
 * Set up the key
 */

if @version < 10 
begin
	select @key = substring(@item_key,1,7) + '-0' + convert(char(1), @version)
end else begin
	select @key = substring(@item_key,1,7) + '-' + convert(char(2), @version)
end

while exists(select voiceover_key from voiceover where voiceover_key = @key)
begin
	select @version = @version + 1

	if @version < 10 
	begin
		select @key = substring(@item_key,1,7) + '-0' + convert(char(1), @version)
	end else begin
		select @key = substring(@item_key,1,7) + '-' + convert(char(2), @version)
	end
end

/*
 * Return
 */

select @key as voiceover_key,
       @version as version

return 0
GO
