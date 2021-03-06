/****** Object:  StoredProcedure [dbo].[p_orphan_artwork_report]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_orphan_artwork_report]
GO
/****** Object:  StoredProcedure [dbo].[p_orphan_artwork_report]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_orphan_artwork_report] 

as
set nocount on 

create table #orphan
(
	artwork_id								integer				null
)

insert into #orphan
	( artwork_id )
  select aw.artwork_id
    from artwork aw
   where ( aw.artwork_status = 'C' or aw.artwork_status = 'L' ) and
         ( not exists ( select sca.artwork_id
                          from slide_campaign_artwork sca,
                               slide_campaign sc,
                               artwork aw2
                         where sca.campaign_no = sc.campaign_no and
                               sca.artwork_id = aw2.artwork_id and
                               sca.artwork_id = aw.artwork_id and
                               ( aw2.artwork_status = 'C' or aw2.artwork_status = 'L' ) ) and

           not exists ( select sia.artwork_id
                          from series_item si,
                               series_item_artwork sia
                         where si.series_item_code = sia.series_item_code and
                               sia.artwork_id = aw.artwork_id ) and

           not exists ( select sa.artwork_id
                          from shell sh,
                               shell_artwork sa,
                               artwork aw2
                         where sh.shell_code = sa.shell_code and
                               sa.artwork_id = aw2.artwork_id and
                               sa.artwork_id = aw.artwork_id and
                               sh.shell_expired = 'N' and sh.shell_expiry_date > getdate() and
                               ( aw2.artwork_status = 'C' or aw2.artwork_status = 'L' ) ) and

           not exists ( select ra.artwork_id
                          from npu_request npur,
                               request_artwork ra,
                               artwork aw2
                         where npur.request_no = ra.request_no and 
                               ra.artwork_id = aw2.artwork_id and
                               ra.artwork_id = aw.artwork_id and
                               aw2.artwork_status = 'C' and
                               ( npur.request_status = 'N' or npur.request_status = 'S' ) ) and

           not exists ( select awgx.artwork_id
                          from artwork_group_xref awgx,
                               artwork_group awg,
                               artwork_pool awp
                         where awgx.artwork_id = aw.artwork_id and
                               awgx.artwork_group_id = awg.artwork_group_id and
                               awg.artwork_pool_id = awg.artwork_pool_id and
                               awg.active = 'Y' and awp.active = 'Y' ) )

select #orphan.artwork_id,
		 artwork.artwork_type,
		 artwork.artwork_key,
		 artwork.artwork_desc,
		 artwork.version_no,
		 artwork.artwork_status
  from #orphan,
       artwork
 where (#orphan.artwork_id = artwork.artwork_id)

return 0
GO
