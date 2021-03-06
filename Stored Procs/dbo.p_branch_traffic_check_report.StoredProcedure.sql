/****** Object:  StoredProcedure [dbo].[p_branch_traffic_check_report]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_branch_traffic_check_report]
GO
/****** Object:  StoredProcedure [dbo].[p_branch_traffic_check_report]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_branch_traffic_check_report]		@carousel_id		integer,
														@screening_date		datetime
as

/*
 * Declare Variables
 */
declare  @artwork_id					integer,
			@vo_id						integer,
			@line_artwork_id			integer,
			@voiceover_option			char(1),
			@done						tinyint,
			@exception					char(1),
			@comment					varchar(50),
			@campaign_no				char(8),
			@complex_id					integer,
			@artwork_version			integer,
			@line_series				char(7),
			@version_no					integer,
			@complex_name				varchar(50),
			@carousel_code				char(3)

/*
 * Create Temporary Table
 */

create table #artworks (
	line_artwork_id			integer		null,
	artwork_id				integer		null,
	voiceover_option		char(1)		null,
	voiceover_id			integer		null,
	sequence_no				smallint		null,
	exception_flag			char(1)		null,
	cue_comment				varchar(50) null,
	artwork_version			integer		null,
	campaign_no				char(8)		null,
)

/*
 *	Setup complex related to carousel_id passed in
 */

select	@complex_id = carousel.complex_id,
		@complex_name = complex.complex_name,
		@carousel_code = carousel.carousel_code
from	carousel,
		complex
where	carousel.carousel_id = @carousel_id and
		complex.complex_id = carousel.complex_id

/*
 * Add all artworks for all clients that have screenings for this screen date and carousel
 */

insert into #artworks (
       line_artwork_id,
       artwork_id,
       voiceover_option,
       voiceover_id,
       sequence_no,
       artwork_version,
       exception_flag,
       campaign_no )
select la.line_artwork_id,
       sca.artwork_id,
       la.voiceover_option,
       la.voiceover_id,
       la.sequence_no,
       artwork.version_no,
       'N',
       sca.campaign_no
  from line_artwork la,
       slide_campaign_artwork sca,
       slide_campaign_screening scs,
       artwork
 where scs.carousel_id = @carousel_id and
       scs.screening_date = @screening_date and
       scs.screening_status <> 'C' and --Cancelled
       scs.campaign_line_id = la.campaign_line_id and
       la.campaign_artwork_id = sca.campaign_artwork_id and
       sca.artwork_id = artwork.artwork_id

/*
 * Loop Artworks
 */
declare artwork_csr cursor static for
  select line_artwork_id, artwork_id, voiceover_id, voiceover_option, artwork_version
    from #artworks
   where voiceover_id is null
order by artwork_id
     for read only

open artwork_csr
fetch artwork_csr into @line_artwork_id, 
                       @artwork_id, 
                       @vo_id, 
                       @voiceover_option,
                       @artwork_version

while(@@fetch_status = 0) 
begin

	/*
	 *	 Check for an approved version no.
	 */
	select @version_no = null
	select @version_no = artwork_version.version_no
     from artwork_version 
    where artwork_version.artwork_id = @artwork_id and
			 (artwork_version.approval_status = 'O' or 
			 artwork_version.approval_status = 'A')

	if @version_no is null
	begin
		select @exception = 'Y'
		select @comment = 'No approved artwork version.'
	end

	/*
	 *	 Link to voiceover
    */

	if @vo_id is null
	begin
		exec p_cue_sheet_asign_voiceover	@artwork_id,
											@voiceover_option,
											@screening_date,
											@voiceover_id = @vo_id output,
											@exception_flag = @exception output,
											@exception = @comment output

		update #artworks
			set voiceover_id = @vo_id,
				 exception_flag = @exception,	
				 cue_comment = @comment
		 where #artworks.line_artwork_id = @line_artwork_id

	end

	/*
    * Fetch Next
    */
	fetch artwork_csr into @line_artwork_id, 
							@artwork_id, 
							@vo_id, 
							@voiceover_option,
							@artwork_version

end
deallocate artwork_csr

/*
 * Return Dataset
 */
select	#artworks.line_artwork_id,
		#artworks.artwork_id,
		#artworks.voiceover_option,
		#artworks.voiceover_id,
		#artworks.sequence_no,
		#artworks.exception_flag,
		#artworks.cue_comment,
		#artworks.artwork_version,
		#artworks.campaign_no,
		artwork.artwork_key,
		artwork.artwork_desc,
		voiceover.voiceover_key,
		voiceover.voiceover_desc,
		voiceover.version_no,
		@carousel_code,
		@complex_name
--from	#artworks,
--		artwork,
--		voiceover
--where	#artworks.exception_flag = 'Y' and
--		artwork.artwork_id = #artworks.artwork_id and
--		voiceover.voiceover_id =* #artworks.voiceover_id	
FROM	artwork INNER JOIN #artworks ON artwork.artwork_id = #artworks.artwork_id 
		LEFT OUTER JOIN voiceover ON #artworks.voiceover_id = voiceover.voiceover_id
		AND #artworks.exception_flag = 'Y'


/*
 * Return
 */

return 0
GO
