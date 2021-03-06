/****** Object:  StoredProcedure [dbo].[p_load_client_artworks]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_load_client_artworks]
GO
/****** Object:  StoredProcedure [dbo].[p_load_client_artworks]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_load_client_artworks] @carousel_id			integer,
                                   @screening_date		datetime
as

/*
 * Declare Variables
 */

declare  @artwork_id					integer,
		   @vo_id						integer,
			@line_artwork_id			integer,
			@voiceover_option			char(1),
			@done							tinyint,
			@exception_flag			char(1),
			@exception_comment		varchar(50),
			@campaign_type				char(1),
			@industry_cat				integer,
			@campaign_no				char(8),
			@complex_id					integer,
			@prev_screening_date		datetime,
			@cue_sheet_id				integer,
			@count						integer,
			@art_status					char(1),
			@vo_status					char(1),
			@prev_complex				integer,
			@artwork_version			integer,
			@campaign_start_date		datetime,
         @line_series				char(7),
			@rec_type					char(1),
         @error						integer,
         @primary_series			char(7),
         @line_id						integer,
         @artwork_desc				varchar(50)

/*
 * Create Temporary Table
 */

create table #artworks
(
	line_id					integer		null,
	line_artwork_id		integer		null,
	artwork_id				integer		null,
	voiceover_option		char(1)		null,
	voiceover_id			integer		null,
	shell_section			smallint		null,
	shell_spacing			char(1)		null,
	cue_cat					char(1)		null,
	sequence_no				smallint		null,
	show_flag				char(1)		null,
	exception_flag			char(1)		null,
	cue_comment				varchar(50) null,
	source					char(1)		null,
	artwork_version		integer		null,
	industry_category		integer		null,
	campaign_no				char(8)		null,
	campaign_start_date	datetime		null,
	art_status				char(1)		null,
	vo_status				char(1)		null,
	scope						varchar(10) null,
	series_item_id			char(7)		null,
	xref_id					integer		null,
	rec_type					char(1)		null,
   screening_id			integer		null
)

/*
 * Declare Cursor
 */






/*
 *	Setup complex related to carousel_id passed in
 */

select @complex_id = complex_id
  from carousel 
 where carousel_id = @carousel_id

/*
 * Add all artworks for all clients that have screenings for this screen date and carousel
 */

insert into #artworks (
       line_id,
       line_artwork_id,
       artwork_id,
       voiceover_option,
       voiceover_id,
       shell_section,
       shell_spacing,
       cue_cat,
       sequence_no,
       show_flag,
       artwork_version,
       exception_flag,
       scope,
       screening_id )
select scs.campaign_line_id,
       la.line_artwork_id,
       sca.artwork_id,
       la.voiceover_option,
       la.voiceover_id,
       la.shell_section,
       la.shell_spacing,
       la.cue_cat,
       la.sequence_no,
       'Y',
       artwork.version_no,
       'N',
       convert(varchar(10),scs.campaign_line_id),
       scs.campaign_screening_id
  from line_artwork la,
       slide_campaign_artwork sca,
       slide_campaign_screening scs,
       artwork
 where scs.carousel_id = @carousel_id and
       scs.screening_date = @screening_date and
       scs.campaign_line_id = la.campaign_line_id and
       la.campaign_artwork_id = sca.campaign_artwork_id and
       sca.artwork_id = artwork.artwork_id

/*
 * Get the details of the previous cue sheet
 */

select @cue_sheet_id = cue_sheet_id,
		 @prev_screening_date = screening_date
  from cue_sheet
 where cue_sheet.screening_date = (select max(screening_date) 
												 from cue_sheet
												where screening_date < @screening_date and
														carousel_id = @carousel_id	 ) and
		 cue_sheet.carousel_id = @carousel_id

/*
 * Loop Cursor
 */
 declare artwork_csr cursor static for
  select line_artwork_id, 
         artwork_id, 
         voiceover_id, 
         voiceover_option, 
         artwork_version
    from #artworks
order by artwork_id
     for read only

open artwork_csr
fetch artwork_csr into @line_artwork_id, @artwork_id, @vo_id, @voiceover_option, @artwork_version
while(@@fetch_status = 0) 
begin

	select @art_status = null,
          @vo_status = null


	select @artwork_desc = artwork_desc
     from artwork 
    where artwork_id = @artwork_id

	/*
	 *	Set Source
	 */

	select @campaign_type = campaign_category,			
			 @industry_cat = industry_category,
			 @campaign_no = slide_campaign.campaign_no,
			 @campaign_start_date = slide_campaign.start_date
	  from slide_campaign,
			 slide_campaign_artwork,
			 line_artwork
    where line_artwork.line_artwork_id = @line_artwork_id and
			 slide_campaign_artwork.campaign_artwork_id = line_artwork.campaign_artwork_id and
			 slide_campaign.campaign_no = slide_campaign_artwork.campaign_no
	
	select @error = @@error
	if (@error !=0)
	begin
		raiserror ('Error Setting Source for campaign no %1!',11,1, @campaign_no)
		return -1
	end

	if @campaign_type <> 'S' 
	begin
		select @campaign_type = 'H'
	end

	update #artworks
      set #artworks.source = @campaign_type,
			 #artworks.industry_category = @industry_cat,
			 #artworks.campaign_no =  @campaign_no,
			 #artworks.campaign_start_date = @campaign_start_date
	 where #artworks.line_artwork_id = @line_artwork_id		

	/*
	 *	Set Series Item Codes if Necessary
    */

	select @line_series = null

	select @line_series = line_series.series_item_code
	  from line_artwork,
			 campaign_line,
			 line_series,
			 series_item,
			 series
	 where line_artwork.line_artwork_id = @line_artwork_id and
          campaign_line.campaign_line_id = line_artwork.campaign_line_id and
			 line_series.campaign_line_id = campaign_line.campaign_line_id and
			 series_item.series_item_code = line_series.series_item_code and
			 series.series_id = series_item.series_id and
			 series.series_type = 'A'

	select @error = @@error
	if (@error !=0)
	begin
		raiserror ('Error Setting line series for %1!',11,1 , @campaign_no)
		return -1
	end

	if @line_series is not null
	begin 

		select @rec_type = 'C'

		select @rec_type = series_artwork_type 
        from series_item_artwork
		 where @artwork_id = artwork_id

		update #artworks
			set #artworks.series_item_id = @line_series,
				 #artworks.scope = 'SER' + @line_series,
             #artworks.shell_spacing = 'B',
             #artworks.rec_type = @rec_type
		 where #artworks.line_artwork_id = @line_artwork_id

	end

	/*
    * Check for a Primary Series Line
    */

	select @primary_series = null

	select @primary_series = line_series.series_item_code
	  from line_artwork,
			 campaign_line,
			 line_series,
			 series_item,
			 series
	 where line_artwork.line_artwork_id = @line_artwork_id and
          campaign_line.campaign_line_id = line_artwork.campaign_line_id and
			 line_series.campaign_line_id = campaign_line.campaign_line_id and
			 series_item.series_item_code = line_series.series_item_code and
			 series.series_id = series_item.series_id and
			 series.series_type = 'P'

	select @error = @@error
	if (@error !=0)
	begin
		raiserror ('Error Setting line series for %1!',11,1, @campaign_no)
		return -1
	end

 	/*
    * Set line_id to null, so we dont reprocess it at the end.
    */

	if @primary_series is null
	begin 
		update #artworks
			set #artworks.line_id = null
		 where #artworks.line_artwork_id = @line_artwork_id
	end

	/*
	 *	Link to voiceover
    */

	exec p_cue_sheet_asign_voiceover @artwork_id,
												@voiceover_option,
												@screening_date,
												@vo_id output,
												@exception_flag output,
												@exception_comment output

	update #artworks
		set voiceover_id = @vo_id,
			 exception_flag = @exception_flag,	
			 cue_comment = @exception_comment
	 where #artworks.line_artwork_id = @line_artwork_id

	/*
 	 *	Setup Artwork Status
	 */

	select @done = 0

	/*
    * EXISTING ARTWORK
    * ----------------
 	 *	Determine if Artwork was on Last Que Sheet for this Carousel
    *
	 */

	if @cue_sheet_id is not null
	begin

		if exists (	select 1
						  from cue_spot,
                         cue_sheet
						 where cue_spot.cue_sheet_id = cue_sheet.cue_sheet_id and 
								 cue_sheet.cue_sheet_id = @cue_sheet_id and
								 cue_spot.artwork_id = @artwork_id and
								 cue_spot.artwork_version = @artwork_version )
		begin
			select @art_status = 'E'
			select @done = 1
		end

	end

	/*
 	 *	NEW TO CAROUSEL (SHIFT) - Setup Artwork Status
	 */

	if @done = 0
	begin

		--We know it wasnt on the last cue sheet for this carousel as the status is not existing
		--Check for it on any carousel at the last screening date at this complex to see if it shifted
		if exists (	select 1
						  from cue_spot,
                         cue_sheet
						 where cue_spot.cue_sheet_id = cue_sheet.cue_sheet_id and 
								 cue_spot.artwork_id = @artwork_id and
								 cue_spot.artwork_version = @artwork_version and
								 cue_sheet.complex_id = @complex_id and
								 cue_sheet.carousel_id <> @carousel_id and
								 cue_sheet.screening_date = @prev_screening_date )
		begin
			select @art_status = 'S'
			select @done = 1
		end

	end
			
	/*
 	 *	RETURN - Setup Artwork Status
	 */

	if @done = 0
	begin

		--We know it didnt screen at this complex last screening date as its status isnt shift or exists
		--So check to see if it ever screened at this complex before
		if exists (	select 1
						  from cue_spot , cue_sheet
						 where cue_spot.cue_sheet_id = cue_sheet.cue_sheet_id and 
								 cue_spot.artwork_id = @artwork_id and
								 cue_spot.artwork_version = @artwork_version and
								 cue_sheet.complex_id = @complex_id and
								 cue_sheet.screening_date < @prev_screening_date ) 
		begin
			select @art_status = 'R'
			select @done = 1
		end
	end
	
	/*
 	 *	Setup Voiceover Status
	 */

	if @vo_id is null 
		select @done = 1,
             @vo_status = 'E'
	else
		select @done = 0

	/*
 	 *	EXISTING - Setup Voiceover Status
	 */

	if @done = 0
	begin
		if @cue_sheet_id is not null
		begin
			if exists ( select 1
							  from cue_spot , cue_sheet
							 where cue_spot.cue_sheet_id = cue_sheet.cue_sheet_id and 
									 cue_sheet.cue_sheet_id = @cue_sheet_id and
									 cue_spot.voiceover_id = @vo_id  )
			begin
				select @vo_status = 'E'
				select @done = 1
			end
		end
	end

	/*
 	 *	NEW TO CAROUSEL (SHIFT) - Setup Voiceover Status
	 */

	if @done = 0
	begin
		if exists (	select 1
						  from cue_spot , cue_sheet
						 where cue_spot.cue_sheet_id = cue_sheet.cue_sheet_id and 
								 cue_spot.voiceover_id = @vo_id and
								 cue_sheet.complex_id = @complex_id and
								 cue_sheet.carousel_id <> @carousel_id and
								 cue_sheet.screening_date = @prev_screening_date )
		begin
			select @vo_status = 'S'
			select @done = 1
		end
	end
			
	/*
 	 *	RETURN - Setup Voiceover Status
	 */

	if @done = 0
	begin
		if exists (	select 1
						  from cue_spot , cue_sheet
						 where cue_spot.cue_sheet_id = cue_sheet.cue_sheet_id and 
								 cue_spot.voiceover_id = @vo_id and
								 cue_sheet.complex_id = @complex_id and
								 cue_sheet.screening_date < @prev_screening_date )
		begin
			select @vo_status = 'R'
			select @done = 1
		end
	end

	/*
    * Set Artwork & Voiceover Status to New
    */

	if @art_status is null
		select @art_status = 'N'

	if @vo_status is null
		select @vo_status = 'N'

	/*
    * Update Artwork & Voiceover Status
    */

	update #artworks
		set art_status = @art_status,
			 vo_status = @vo_status
	 where #artworks.line_artwork_id = @line_artwork_id

	/*
    * Fetch Next
    */

	fetch artwork_csr into @line_artwork_id, @artwork_id, @vo_id, @voiceover_option, @artwork_version

end

close artwork_csr
deallocate artwork_csr

/*
 * Fix artwork status for Primary series
 */
 declare check_csr cursor static for
  select line_id,
         line_artwork_id, 
         art_status
    from #artworks
   where line_id is not null
order by line_id ASC, line_artwork_id DESC
     for read only

open check_csr
fetch check_csr into @line_id, @line_artwork_id, @art_status
while(@@fetch_status = 0) 
begin

   /*
    * If the current artowrk is not the header, 
    * update all others with this line id, 
    * that isnt this artwork to the current artwork status
    */

	if not exists (select 1
						  from slide_campaign_artwork,
								 series_item_artwork,
								 line_artwork
						 where line_artwork.line_artwork_id = @line_artwork_id and
								 slide_campaign_artwork.campaign_artwork_id = line_artwork.campaign_artwork_id and
								 series_item_artwork.artwork_id = slide_campaign_artwork.artwork_id )
	begin
		update #artworks
			set art_status = @art_status
		 where #artworks.line_id = @line_id and
             #artworks.line_artwork_id <> @line_artwork_id
	end

	/*
    * Fetch Next
    */

	fetch check_csr into @line_id, @line_artwork_id, @art_status

end
close check_csr
deallocate check_csr

/*
 * Return Artworks
 */

select line_artwork_id,
       artwork_id,
       voiceover_option,
       voiceover_id,
       shell_section,
       shell_spacing,
       cue_cat,
       sequence_no,
       show_flag,
       exception_flag,
       cue_comment,
       source,
       artwork_version,
       industry_category,
       campaign_no,
       campaign_start_date,
       art_status,
       vo_status,
       scope,
       series_item_id,
       xref_id,
       rec_type,
       screening_id
  from #artworks

/*
 * Return
 */

return 0
GO
