/****** Object:  StoredProcedure [dbo].[p_load_shell_artworks]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_load_shell_artworks]
GO
/****** Object:  StoredProcedure [dbo].[p_load_shell_artworks]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_load_shell_artworks] @carousel_id			integer,
                                  @screening_date		datetime
as

/*
 * Declare Variables
 */

declare  @artwork_id					integer,
		   @vo_id						integer,
			@shell_artwork_id			integer,
			@voiceover_option			char(1),
			@done							tinyint,
			@exception_flag			char(1),
			@exception_comment		varchar(50),
			@complex_id					integer,
			@prev_screening_date		datetime,
			@cue_sheet_id				integer,
			@count						integer,
			@art_status					char(1),
			@vo_status					char(1),
			@prev_complex				integer,
			@artwork_version			integer,
			@branch_code				char(3)

/*
 * Create Temporary Table
 */

create table #artworks
(
	shell_artwork_id		integer		null,
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
	art_status				char(1)		null,
	vo_status				char(1)		null,
	scope						char(10)		null,
	xref_id					integer		null
)



select @complex_id = carousel.complex_id,
		 @branch_code = complex.branch_code
  from carousel,complex 
 where carousel.carousel_id = @carousel_id and
		 complex.complex_id = carousel.complex_id

/*
 * Add all artworks for all shells related to this carousel
 */

insert into #artworks (
       shell_artwork_id,
       artwork_id,
       voiceover_option,
       voiceover_id,
       shell_section,
       shell_spacing,
       cue_cat,
       sequence_no,
       show_flag,
       source,
       artwork_version,
       exception_flag,
       scope )
select shell_artwork.shell_artwork_id,
       shell_artwork.artwork_id,
       shell_artwork.voiceover_option,
       shell_artwork.voiceover_id,
       shell_artwork.shell_section,
       shell_artwork.shell_spacing,
       shell_artwork.cue_cat,
       shell_artwork.sequence_no,
       shell_artwork.show_flag,
       convert(char(1),shell_type.cue_priority),
       artwork.version_no,
       'N',
       shell.shell_code
  from shell_artwork,
       shell_xref,
       shell,
       artwork,
       shell_type
 where shell_xref.carousel_id = @carousel_id and
       artwork.artwork_id = shell_artwork.artwork_id and
       shell_artwork.shell_code = shell.shell_code and
       shell.shell_code = shell_xref.shell_code and
       shell.shell_type = shell_type.shell_type_code and
       shell.shell_expired = 'N' and
       ( shell.shell_expiry_date >= @screening_date or
         shell.shell_expiry_date is null ) and
     ( shell.shell_permanent = 'N' and 
       exists ( select screening_date 
                  from shell_dates 
                 where shell_dates.shell_code = shell.shell_code and
                       shell_dates.screening_date = @screening_date and
                       shell_dates.branch_code = @branch_code ) or
       shell.shell_permanent = 'Y')

--Get details of previous cue sheet
select @cue_sheet_id = cue_sheet_id,
		 @prev_screening_date = screening_date
  from cue_sheet
 where cue_sheet.screening_date = ( select max(screening_date) 
												  from cue_sheet
												 where screening_date < @screening_date and
														 carousel_id = @carousel_id ) and
		 cue_sheet.carousel_id = @carousel_id
/*
 * Declare Cursors
 */

declare artwork_csr cursor static for
  select shell_artwork_id, artwork_id, voiceover_id, voiceover_option, artwork_version
    from #artworks
order by artwork_id
     for read only

/*
 * Loop Cursor
 */

open artwork_csr
fetch artwork_csr into @shell_artwork_id, @artwork_id, @vo_id, @voiceover_option, @artwork_version
while(@@fetch_status = 0) 
begin

	select @art_status = null,
          @vo_status = null

	/*
    *  Check for an override for this shell artwork
    */
	if exists ( select 1
					  from shell_override
					 where shell_artwork_id = @shell_artwork_id and
							 carousel_id = @carousel_id )
	begin
			select @voiceover_option = voiceover_option,
					 @vo_id            = voiceover_id
			  from shell_override
			 where shell_artwork_id = @shell_artwork_id and
					 carousel_id = @carousel_id 
	end

	/*
    * Assign Voiceover
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
	 where #artworks.shell_artwork_id = @shell_artwork_id

	/*
 	 *	Setup artwork status
	 */

	select @done = 0

	/*
 	 *	EXISTING ARTWORK
    * ----------------
    * Determine if Artwork was on Last Que Sheet for this Carousel
    *
	 */

	if @cue_sheet_id is not null
	begin

		if exists (	select 1
						  from cue_spot , cue_sheet
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

		if exists (	select 1
						  from cue_spot,
                         cue_sheet
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
							  from cue_spot,
                            cue_sheet
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
						  from cue_spot,
                         cue_sheet
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
						  from cue_spot,
                         cue_sheet
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
    * Setup Artwork & Voiceover Status to New
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
	 where #artworks.shell_artwork_id = @shell_artwork_id

	/*
    * Fetch Next
    */

	fetch artwork_csr into @shell_artwork_id, @artwork_id, @vo_id, @voiceover_option, @artwork_version

end

close artwork_csr
deallocate artwork_csr

/*
 * Return Artworks
 */

select * from #artworks

/*
 * Return
 */

return 0
GO
