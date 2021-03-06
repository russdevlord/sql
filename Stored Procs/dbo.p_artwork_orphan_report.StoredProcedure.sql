/****** Object:  StoredProcedure [dbo].[p_artwork_orphan_report]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_artwork_orphan_report]
GO
/****** Object:  StoredProcedure [dbo].[p_artwork_orphan_report]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_artwork_orphan_report] 

as

/*
 * Create Temporary Tables
 */

create table #orphans
(
	artwork_id								integer				null,
)

/*
 * Insert Series Orphans
 */

insert into #orphans
	( artwork_id )
  select artwork.artwork_id
    from artwork
   where artwork.artwork_type='S' AND
         not exists ( select series_item_artwork.artwork_id
                        from series_item_artwork
                       where artwork.artwork_id = series_item_artwork.artwork_id )
/*
 * Insert Client and Client Series Orphans
 */

insert into #orphans
	( artwork_id )
  select artwork.artwork_id
    from artwork
   where ( artwork.artwork_type='C' or artwork.artwork_type='E' ) AND
         not exists ( select slide_campaign_artwork.artwork_id
                        from slide_campaign_artwork
                       where artwork.artwork_id = slide_campaign_artwork.artwork_id )

/*
 * Insert House / Complex / General Orphans
 */

insert into #orphans
	( artwork_id )
  select artwork.artwork_id
    from artwork
   where ( artwork.artwork_type='X' or artwork.artwork_type='G' or artwork.artwork_type='H') AND
			 ( artwork.artwork_group is null ) 

/*
 * Return
 */

select #orphans.artwork_id,
		 artwork.artwork_type,
		 artwork.artwork_key,
		 artwork.artwork_desc,
		 artwork.version_no,
		 artwork.artwork_status
  from #orphans,
       artwork
 where (#orphans.artwork_id = artwork.artwork_id) 
 order by artwork.artwork_type, artwork.artwork_code

return 0
GO
