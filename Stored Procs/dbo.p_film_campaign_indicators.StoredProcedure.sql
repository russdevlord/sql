/****** Object:  StoredProcedure [dbo].[p_film_campaign_indicators]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_film_campaign_indicators]
GO
/****** Object:  StoredProcedure [dbo].[p_film_campaign_indicators]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
create proc [dbo].[p_film_campaign_indicators] 

as

declare @error						int,
		@campaign_no				int,
		@includes_media				char(1),
		@includes_cinelights		char(1),
		@includes_infoyer			char(1),
		@includes_miscellaneous		char(1),
		@includes_follow_film		char(1),
		@includes_premium_position	char(1),
		@includes_gold_class		char(1),
		@includes_retail			char(1),
		@count						int

set nocount on


declare		campaign_csr cursor static forward_only for 
select 		campaign_no
from		film_campaign
where 		campaign_status != 'Z'
and 		campaign_status != 'X'
order by	campaign_no
for			read only

begin transaction

open campaign_csr
fetch campaign_csr into @campaign_no
while(@@fetch_status=0)
begin

	/*
  	 * Initialise Variables
	 */

	select 	@includes_media = 'N',
			@includes_cinelights = 'N',
			@includes_infoyer = 'N',
			@includes_miscellaneous = 'N',
			@includes_follow_film = 'N',
			@includes_premium_position = 'N',
			@includes_gold_class = 'N',
			@includes_retail = 'N',
			@count = 0

	/*
  	 * Determine Includes Media
	 */

	select 	@count = count(spot_id)
	from	campaign_spot
	where 	campaign_no = @campaign_no

	select @error = @@error
	if @error != 0
	begin
		raiserror ('Error Updating Includes Media Flag'		, 16, 1)
		rollback transaction
		return -1
	end

	select	@count = @count + count(inclusion_id)
	from	inclusion
	where	campaign_no = @campaign_no
	and		inclusion_type = 11 or inclusion_type = 12

	if @count > 0
		select @includes_media = 'Y'

	
	/*
  	 * Determine Includes Cinelights
	 */

	select 	@count = 0

	select 	@count = count(spot_id)
	from	cinelight_spot
	where 	campaign_no = @campaign_no

	select @error = @@error
	if @error != 0
	begin
		raiserror ('Error Updating Includes Cinelights Flag'		, 16, 1)
		rollback transaction
		return -1
	end

	select	@count = @count + count(inclusion_id)
	from	inclusion
	where	campaign_no = @campaign_no
	and		inclusion_type = 13


	if @count > 0
		select @includes_cinelights = 'Y'

	/*
  	 * Determine Includes Retail
	 */

	select 	@count = 0

	select 	@count = count(spot_id)
	from	outpost_spot
	where 	campaign_no = @campaign_no

	select @error = @@error
	if @error != 0
	begin
		raiserror ('Error Updating Includes Retail Flag'		, 16, 1)
		rollback transaction
		return -1
	end

	if @count > 0
		select @includes_retail = 'Y'
	/*
  	 * Determine Includes In Foyer
	 */

	select 	@count = 0

	select 	@count = count(inclusion_id)
	from	inclusion
	where 	campaign_no = @campaign_no
	and		inclusion_type = 5

	select @error = @@error
	if @error != 0
	begin
		raiserror ('Error Updating Includes In Foyer Flag'		, 16, 1)
		rollback transaction
		return -1
	end

	select	@count = @count + count(inclusion_id)
	from	inclusion
	where	campaign_no = @campaign_no
	and		inclusion_type = 14

	if @count > 0
		select @includes_infoyer = 'Y'

	/*
  	 * Determine Includes Miscellaneous
	 */

	select 	@count = 0

	select 	@count = count(inclusion_id)
	from	inclusion
	where 	campaign_no = @campaign_no
	and		inclusion_type not in (5,11,12,13,14)

	select @error = @@error
	if @error != 0
	begin
		raiserror ('Error Updating Includes Miscellaneous Flag'		, 16, 1)
		rollback transaction
		return -1
	end

	if @count > 0 and @includes_media = 'N' and @includes_cinelights = 'N' and @includes_infoyer = 'N'
		select @includes_miscellaneous = 'Y'

	/*
  	 * Determine Includes Follow Film
	 */

	select 	@count = 0

	select 	@count = count(package_id)
	from	campaign_package
	where 	campaign_no = @campaign_no
	and		follow_film = 'Y'

	select @error = @@error
	if @error != 0
	begin
		raiserror ('Error Updating Includes Follow Film Flag'		, 16, 1)
		rollback transaction
		return -1
	end

	if @count > 0
		select @includes_follow_film = 'Y'


	/*
  	 * Determine Includes Premuim Position
	 */

	select 	@count = 0

	select 	@count = count(package_id)
	from	campaign_package
	where 	campaign_no = @campaign_no
	and		(screening_trailers = 'F'
	or		screening_trailers = 'B')

	select @error = @@error
	if @error != 0
	begin
		raiserror ('Error Updating Includes Follow Film Flag'		, 16, 1)
		rollback transaction
		return -1
	end

	if @count > 0
		select @includes_premium_position = 'Y'


	/*
  	 * Determine Includes Gold Class
	 */

	select 	@count = 0

	select 	@count = count(package_id)
	from	campaign_package
	where 	campaign_no = @campaign_no
	and		premium_screen_type = 'P'

	select @error = @@error
	if @error != 0
	begin
		raiserror ('Error Updating Includes Follow Film Flag'		, 16, 1)
		rollback transaction
		return -1
	end

	if @count > 0
		select @includes_gold_class = 'Y'

	/*
  	 * Determine Includes Gold Class
	 */

	update	film_campaign
	set		includes_media = @includes_media,
			includes_cinelights = @includes_cinelights,
			includes_infoyer = @includes_infoyer,
			includes_miscellaneous = @includes_miscellaneous,
			includes_follow_film = @includes_follow_film,
			includes_premium_position = @includes_premium_position,
			includes_gold_class = @includes_gold_class,
			includes_retail	= @includes_retail
	where	campaign_no = @campaign_no

	select @error = @@error
	if @error != 0
	begin
		raiserror ('Error Updating Campaign Indicators'		, 16, 1)
		rollback transaction
		return -1
	end	

	fetch campaign_csr into @campaign_no
end

deallocate campaign_csr

commit transaction
return 0
GO
