/****** Object:  StoredProcedure [dbo].[p_orphan_voiceover_report]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_orphan_voiceover_report]
GO
/****** Object:  StoredProcedure [dbo].[p_orphan_voiceover_report]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_orphan_voiceover_report] 

as
set nocount on 
create table #orphan
(
	voiceover_id								integer				null
)

insert into #orphan
	( voiceover_id )
  select vo.voiceover_id
    from voiceover vo
   where ( vo.voiceover_status = 'N' or vo.voiceover_status = 'R' ) and
         ( not exists ( select scv.voiceover_id
                          from slide_campaign_voiceover scv,
                               slide_campaign sc,
                               voiceover vo2
                         where scv.campaign_no = sc.campaign_no and
                               scv.voiceover_id = vo2.voiceover_id and
                               scv.voiceover_id = vo.voiceover_id and
                               /*( sc.campaign_status = 'L' or sc.campaign_status = 'U' ) and*/
                               ( vo2.voiceover_status = 'N' or vo2.voiceover_status = 'R' ) ) and

           not exists ( select siv.voiceover_id
                          from series_item si,
                               series_item_voiceover siv,
                               voiceover vo2
                         where si.series_item_code = siv.series_item_code and
                               siv.voiceover_id = vo2.voiceover_id and
                               siv.voiceover_id = vo.voiceover_id ) and

           not exists ( select rv.voiceover_id
                          from npu_request npur,
                               request_voiceover rv,
                               voiceover vo2
                         where npur.request_no = rv.request_no and 
                               rv.voiceover_id = vo2.voiceover_id and
                               rv.voiceover_id = vo.voiceover_id and
                               vo2.voiceover_status = 'N' and
                               ( npur.request_status = 'N' or npur.request_status = 'S' ) ) )

select #orphan.voiceover_id,
		 voiceover.voiceover_type,
		 voiceover.voiceover_key,
		 voiceover.voiceover_desc,
		 voiceover.version_no,
		 voiceover.voiceover_status
  from #orphan,
       voiceover
 where (#orphan.voiceover_id = voiceover.voiceover_id)

return 0
GO
