/****** Object:  StoredProcedure [dbo].[p_outpost_playist_category_warning_report]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_outpost_playist_category_warning_report]
GO
/****** Object:  StoredProcedure [dbo].[p_outpost_playist_category_warning_report]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc		[dbo].[p_outpost_playist_category_warning_report]				@screening_date			datetime
as

declare			@player_name_1							varchar(100), 
						@internal_desc_1						varchar(100),
						@screening_date_1					datetime,  
						@start_date_1								datetime,
						@end_date_1								datetime,
						@playlist_no_1								integer,
						@sequence_no_1						integer,
						@product_category_1				integer,
						@product_subcategory_1			integer,
						@package_desc_1						varchar(100),
						@player_name_2							varchar(100), 
						@internal_desc_2						varchar(100),
						@screening_date_2					datetime,  
						@start_date_2								datetime,
						@end_date_2								datetime,
						@playlist_no_2								integer,
						@sequence_no_2						integer,
						@product_category_2				integer,
						@product_subcategory_2			integer,
						@package_desc_2						varchar(100)
			
declare		playlist_csr cursor for
select		outpost_player.player_name, 
					outpost_player.internal_desc,
					outpost_playlist.screening_date,  
					outpost_playlist.start_date,
					outpost_playlist.end_date,
					outpost_playlist.playlist_no,
					sequence_no,
					product_category,
					product_subcategory,
					package_desc
from			outpost_player,
					outpost_playlist, 
					outpost_playlist_item, 
					outpost_playlist_item_spot_xref, 
					outpost_spot, 
					outpost_package
where		outpost_playlist.playlist_id = outpost_playlist_item.playlist_id
and				outpost_playlist_item.outpost_playlist_item_id = outpost_playlist_item_spot_xref.outpost_playlist_item_id
and				outpost_playlist_item_spot_xref.spot_id = outpost_spot.spot_id
and				outpost_spot.package_id = outpost_package.package_id
and				outpost_player.player_name = outpost_playlist.player_name
and				outpost_playlist.screening_date = @screening_date
group by  outpost_player.player_name, 
					outpost_player.internal_desc,
					outpost_playlist.screening_date,  
					outpost_playlist.start_date,
					outpost_playlist.end_date,
					outpost_playlist.playlist_no,
					sequence_no,
					product_category,
					product_subcategory,
					package_desc
order by	outpost_player.internal_desc,
					outpost_playlist.screening_date,  
					outpost_playlist.start_date,
					outpost_playlist.playlist_no,
					sequence_no
for				read only					
					
select		@player_name_2							 = '',
					@internal_desc_2						= '',
					@screening_date_2					= '1-jan-1950',  
					@start_date_2								= '1-jan-1950', 
					@end_date_2								= '1-jan-1950', 
					@playlist_no_2								= 0,
					@sequence_no_2						= 0,
					@product_category_2				= 0,
					@product_subcategory_2			= 0,
					@package_desc_2						= ''
									
open 	playlist_csr
fetch playlist_csr into 	@player_name_1,@internal_desc_1,@screening_date_1,  @start_date_1, @end_date_1, @playlist_no_1,@sequence_no_1,@product_category_1,@product_subcategory_1,@package_desc_1
while(@@fetch_status = 0)
begin

	

	fetch playlist_csr into 	@player_name_1,@internal_desc_1,@screening_date_1,  @start_date_1, @end_date_1, @playlist_no_1,@sequence_no_1,@product_category_1,@product_subcategory_1,@package_desc_1
end
GO
