/****** Object:  StoredProcedure [dbo].[p_series_artwork_delete_rep]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_series_artwork_delete_rep]
GO
/****** Object:  StoredProcedure [dbo].[p_series_artwork_delete_rep]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_series_artwork_delete_rep]

as
set nocount on 
create table #artworks
(
	artwork_id								integer				null
)

insert into #artworks
	( artwork_id )
  select aw.artwork_id
    from artwork aw
   where ( aw.artwork_status = 'C' or aw.artwork_status = 'L' ) and
               exists ( select sia.artwork_id
                          from series_item si,
                               series_item_artwork sia,
                               artwork aw2
                         where si.series_item_code = sia.series_item_code and
                               sia.artwork_id = aw2.artwork_id and
                               sia.artwork_id = aw.artwork_id and
                               si.active = 'N' ) and

           not exists ( select sia.artwork_id
                          from series_item si,
                               series_item_artwork sia,
                               artwork aw2
                         where si.series_item_code = sia.series_item_code and
                               sia.artwork_id = aw2.artwork_id and
                               sia.artwork_id = aw.artwork_id and
                               si.active = 'Y' )

select #artworks.artwork_id,
		 aw.artwork_type,
		 aw.artwork_key,
		 aw.artwork_desc,
		 aw.version_no,
		 aw.artwork_status,
       aw.disk_ref,
       si.series_item_code,
       si.series_item_desc,
       si.active
  from #artworks,
       artwork aw,
       series_item si,
       series_item_artwork sia
 where #artworks.artwork_id = aw.artwork_id and
       #artworks.artwork_id = sia.artwork_id and
       sia.series_item_code = si.series_item_code

return 0
GO
