/****** Object:  StoredProcedure [dbo].[p_resolve_artwork_voiceover]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_resolve_artwork_voiceover]
GO
/****** Object:  StoredProcedure [dbo].[p_resolve_artwork_voiceover]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_resolve_artwork_voiceover] @artwork_id			integer,
                                        @voiceover_option	char(1),
                                        @voiceover_id			integer
as
set nocount on 
/*
 * Declare Variables
 */

declare @error							integer,
	     @sqlstatus					integer,
        @errorode							integer,
        @vo_csr_open					tinyint,
        @done							tinyint,
        @artwork_status				char(1),
        @vcount						integer,
        @exception_flag				char(1),
        @exception_comment			varchar(50),
        @assign_vo					integer,
        @csr_voiceover_id			integer,
        @csr_voiceover_option		char(1),
        @csr_order_no				integer,
        @csr_vo_status				char(1),
        @csr_approval_status		char(1),
        @csr_expiry_date			datetime,
        @loop							integer,
        @vopt							tinyint,
        @vapp							tinyint,
        @vrel							tinyint,
        @vexp							tinyint,
        @art_version_no				integer,
        @screening_date				datetime

/*
 * Initialise Variables
 */

select @done = 0,
	    @exception_flag = 'N',
       @exception_comment = '',
       @vopt = 0,
       @vapp = 0,
       @vexp = 0,
       @vrel = 0,
       @loop = 0,
       @vo_csr_open = 0

select @screening_date = min(screening_date)
  from slide_screening_dates
 where screening_status = 'O'

/*
 *  Check for conceptual artworks
 */

/*select @artwork_status = artwork_status,
       @art_version_no = version_no
  from artwork
 where artwork_id = @artwork_id

if(@artwork_status = 'C' or @artwork_status = 'A')
begin
	 select @exception_flag = 'Y'
	 select @exception_comment = 'Artwork Conceptual/Aborted'
    select @done = 1
end*/

/*if(@art_version_no <= 0 and @done <> 1)
begin
	 select @exception_flag = 'Y'
	 select @exception_comment = 'No Artwork Version has been Released'
    select @done = 1
end*/

/*
 *  Link up to Voiceovers
 */

if(@done = 0 and @voiceover_id is null)
begin

	/*
	 * Declare Voiceover Cursor
	 */
	 declare vo_csr cursor static for
	  select av.voiceover_id, 
	         av.voiceover_option,
	         av.order_no,
	         v.voiceover_status,
	         v.approval_status, 
	         v.expiry_date
	    from artwork_voiceover av,
	         voiceover v
		where v.voiceover_id = av.voiceover_id and
	         av.artwork_id = @artwork_id
	order by av.voiceover_option ASC,
	         av.order_no DESC,
	         v.voiceover_id DESC
	     for read only

	open vo_csr
	select @vo_csr_open = 1
	fetch vo_csr into @csr_voiceover_id, 
                     @csr_voiceover_option,
                     @csr_order_no,
                     @csr_vo_status,
                     @csr_approval_status,
                     @csr_expiry_date

	while(@@fetch_status = 0 and @done = 0)
	begin
	
		select @loop = @loop + 1

		/*
       * Check Voiceovers with Corresponding Option Only
       */

		if(@csr_voiceover_option = @voiceover_option)
		begin
		
			select @vopt = 1

			if(@csr_approval_status = 'O' or @csr_approval_status = 'A')
			begin

				select @vapp = 1

				if(@csr_vo_status = 'R' or @csr_vo_status = 'E')
				begin

					select @vrel = 1

					if(@csr_expiry_date < @screening_date or @csr_vo_status = 'E')
						select @vexp = 1
					else
						select @voiceover_id = @csr_voiceover_id,
                         @done = 1

				end

			end

		end

		/*
       * Fetch Next
       */

		fetch vo_csr into @csr_voiceover_id, 
								@csr_voiceover_option,
								@csr_order_no,
								@csr_vo_status,
								@csr_approval_status,
								@csr_expiry_date

	end
	close vo_csr
	deallocate vo_csr

	/*
    * If No Voiceovers then Error
    */

	if(@loop = 0)
	begin
		select @exception_flag = 'Y'
		select @exception_comment = 'Voiceovers Not Found'
		select @done = 1
	end

	if(@done = 0)
	begin

		if(@vopt = 0 and @done = 0)
		begin
			select @exception_flag = 'Y'
			select @exception_comment = 'No Voiceovers for Specified Option'
			select @done = 1
		end
		if(@vapp = 0 and @done = 0)
		begin
			select @exception_flag = 'Y'
			select @exception_comment = 'Voiceovers not Approved'
			select @done = 1
		end
		if(@vrel = 0 and @done = 0)
		begin
			select @exception_flag = 'Y'
			select @exception_comment = 'Voiceovers not Released'
			select @done = 1
		end
		if(@vexp = 1 and @done = 0)
		begin
			select @exception_flag = 'Y'
			select @exception_comment = 'Voiceovers Expired'
			select @done = 1
		end

	end

end

/*
 * Set Exception Information
 */

select @artwork_id as artwork_id,
       @voiceover_option as voiceover_option,
       @screening_date as screening_date,
       @voiceover_id as voiceover_id,
       @exception_flag as exception_flag,
       @exception_comment as exception

/*
 * Return
 */

return 0
GO
