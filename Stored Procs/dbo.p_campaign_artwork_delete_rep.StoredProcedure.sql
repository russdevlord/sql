/****** Object:  StoredProcedure [dbo].[p_campaign_artwork_delete_rep]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_campaign_artwork_delete_rep]
GO
/****** Object:  StoredProcedure [dbo].[p_campaign_artwork_delete_rep]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_campaign_artwork_delete_rep] 

as

create table #artworks
(
	artwork_id								integer				null
)

insert into #artworks
	( artwork_id )
  select aw.artwork_id
    from artwork aw
   where ( aw.artwork_type = 'C' or aw.artwork_type = 'E' ) and
         ( aw.artwork_status = 'C' or aw.artwork_status = 'L' ) and
         not exists ( select sca.artwork_id
                        from slide_campaign_artwork sca,
                             slide_campaign sc
                       where sca.campaign_no = sc.campaign_no and
                             sca.artwork_id = aw.artwork_id and
                             ( sc.campaign_status = 'L' or sc.campaign_status = 'U' ) ) and

             exists ( select sca.artwork_id
                        from slide_campaign_artwork sca,
                             slide_campaign sc
                       where sca.campaign_no = sc.campaign_no and
                             sca.artwork_id = aw.artwork_id and
                             ( sc.campaign_status = 'C' or sc.campaign_status = 'X' or sc.campaign_status = 'Z' ) and
                             ( ( sc.start_date is not null and
                                 dateadd(dd, ((sc.min_campaign_period + sc.bonus_period)*7)-1, sc.start_date) < dateadd(month, -3, getdate()) ) or
                               ( sc.start_date is null ) ) ) and

          not exists ( select sca.artwork_id
                        from slide_campaign_artwork sca,
                             slide_campaign sc
                       where sca.campaign_no = sc.campaign_no and
                             sca.artwork_id = aw.artwork_id and
                             ( sc.campaign_status = 'C' or sc.campaign_status = 'X' or sc.campaign_status = 'Z' ) and
                             ( ( sc.start_date is not null and
                                 dateadd(dd, ((sc.min_campaign_period + sc.bonus_period)*7)-1, sc.start_date) >= dateadd(month, -3, getdate()) ) ))

select #artworks.artwork_id,
		 aw.artwork_type,
		 aw.artwork_key,
		 aw.artwork_desc,
		 aw.version_no,
		 aw.artwork_status,
       aw.disk_ref,
       sc.branch_code,
       sc.campaign_no,
       sc.name_on_slide,
       sc.campaign_status,
       sc.start_date,
       dateadd(dd, ((sc.min_campaign_period+sc.bonus_period)*7)-1, sc.start_date) as end_date
  from #artworks,
       artwork aw,
       slide_campaign_artwork sca,
       slide_campaign sc
 where #artworks.artwork_id = aw.artwork_id and
       #artworks.artwork_id = sca.artwork_id and
       sca.campaign_no = sc.campaign_no
return 0
GO
