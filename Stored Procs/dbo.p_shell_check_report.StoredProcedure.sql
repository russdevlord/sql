/****** Object:  StoredProcedure [dbo].[p_shell_check_report]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_shell_check_report]
GO
/****** Object:  StoredProcedure [dbo].[p_shell_check_report]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_shell_check_report]			@screening_date	datetime,
												@branch_code		char(3)
as

set nocount on

declare		@artwork_id					integer,
		   @vo_id						integer,
			@shell_artwork_id			integer,
			@voiceover_option			char(1),
			@exception					char(1),
			@comment					varchar(50),
			@complex_id					integer,
			@artwork_version			integer,
			@version_no					integer,
			@branch_name				varchar(50)


create table #artworks (
	shell_artwork_id		integer		null,
	artwork_id				integer		null,
	voiceover_option		char(1)		null,
	voiceover_id			integer		null,
	exception_flag			char(1)		null,
	cue_comment				varchar(50) null,
	artwork_version			integer		null,
	source					char(8)		null,
	vo_option				char(1)		null,
	seqno					integer		null
)

select @branch_name = branch_name
  from branch
 where branch_code = @branch_code

/*
 *  Add all artworks for all shells related to this carousel
 */

insert into #artworks (
	shell_artwork_id,
	artwork_id,
	voiceover_option,
	voiceover_id,
	artwork_version,
	exception_flag,
	source,
	vo_option,
	seqno
)
select distinct	shell_artwork.shell_artwork_id,
		shell_artwork.artwork_id,
		shell_artwork.voiceover_option,
		shell_artwork.voiceover_id,
		artwork.version_no,
		'N',
		shell_artwork.shell_code,
		shell_artwork.voiceover_option,
		shell_Artwork.sequence_no
  from 	shell_artwork,
		shell_xref,
		shell,
		artwork,
		shell_type,
		carousel,
		complex
where   shell_xref.carousel_id = carousel.carousel_id and
		carousel.complex_id = complex.complex_id and
		complex.branch_code = @branch_code and
		artwork.artwork_id = shell_artwork.artwork_id and
		shell_artwork.shell_code = shell.shell_code and
		shell.shell_code = shell_xref.shell_code and
		shell.shell_type = shell_type.shell_type_code and
		shell.shell_expired = 'N' and 
		(shell.shell_permanent = 'N' and 
		exists (select screening_date 
				from	shell_dates 
				where	shell_dates.shell_code = shell.shell_code 
				and		shell_dates.screening_date = @screening_date 
				and		shell_dates.branch_code = @branch_code) 
				or		shell.shell_permanent = 'Y')

declare artwork_csr cursor static for
  select shell_artwork_id, artwork_id, voiceover_id, voiceover_option, artwork_version
    from #artworks
   where voiceover_id is null
order by artwork_id
     for read only

open artwork_csr
fetch artwork_csr into @shell_artwork_id, @artwork_id, @vo_id, @voiceover_option, @artwork_version
while(@@fetch_status = 0) 
begin
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

	if @vo_id is null
	begin
		exec p_cue_sheet_asign_voiceover  @artwork_id,
													 @voiceover_option,
													 @screening_date,
													 @voiceover_id = @vo_id output,
													 @exception_flag = @exception output,
													 @exception = @comment output

		update #artworks
			set voiceover_id = @vo_id,
				 exception_flag = @exception,	
				 cue_comment = @comment
		 where #artworks.shell_artwork_id = @shell_artwork_id
	end

	fetch artwork_csr into @shell_artwork_id, @artwork_id, @vo_id, @voiceover_option, @artwork_version
end
close artwork_csr
deallocate artwork_csr

--Return
SELECT	#artworks.*,
		artwork.artwork_key,
		artwork.artwork_desc,
		voiceover.voiceover_key,		 
		voiceover.voiceover_desc,		 
		voiceover.version_no,
		shell.shell_desc,
		shell.shell_type,
		@branch_name,
		@screening_date
FROM	#artworks CROSS JOIN
			artwork CROSS JOIN
			voiceover CROSS JOIN
			shell
WHERE	(artwork.artwork_id = #artworks.artwork_id) 
AND		(voiceover.voiceover_id = #artworks.voiceover_id) 
AND		(shell.shell_code = #artworks.source)
and		#artworks.exception_flag = 'Y'

return 0
GO
