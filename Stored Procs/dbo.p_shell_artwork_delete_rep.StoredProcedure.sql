/****** Object:  StoredProcedure [dbo].[p_shell_artwork_delete_rep]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_shell_artwork_delete_rep]
GO
/****** Object:  StoredProcedure [dbo].[p_shell_artwork_delete_rep]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_shell_artwork_delete_rep]

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
               exists ( select sa.artwork_id
                          from shell sh,
                               shell_artwork sa,
                               artwork aw2
                         where sh.shell_code = sa.shell_code and
                               sa.artwork_id = aw2.artwork_id and
                               sa.artwork_id = aw.artwork_id and
                               ( aw2.artwork_status = 'C' or aw2.artwork_status = 'L' ) and
                               sh.shell_expired = 'Y' and
                               ( ( sh.shell_permanent = 'Y' and sh.shell_expiry_date is not null and sh.shell_expiry_date < dateadd(month, -3, getdate()) ) or
                                 ( sh.shell_permanent = 'N' and ( select isnull(max(sd.screening_date), getdate() )
                                                                    from shell_dates sd
                                                                   where sd.shell_code = sh.shell_code ) < dateadd(month, -3, getdate()) ) ) ) and

           not exists ( select sa.artwork_id
                          from shell sh,
                               shell_artwork sa,
                               artwork aw2
                         where sh.shell_code = sa.shell_code and
                               sa.artwork_id = aw2.artwork_id and
                               sa.artwork_id = aw.artwork_id and
                               ( aw2.artwork_status = 'C' or aw2.artwork_status = 'L' ) and
                               ( sh.shell_expired = 'N' or
                                 ( sh.shell_expired = 'Y' and
                                   ( ( sh.shell_permanent = 'Y' and sh.shell_expiry_date is not null and sh.shell_expiry_date > dateadd(month, -3, getdate()) ) or
                                     ( sh.shell_permanent = 'N' and ( select isnull(max(sd.screening_date), getdate() )
                                                                        from shell_dates sd
                                                                       where sd.shell_code = sh.shell_code ) > dateadd(month, -3, getdate()) ) ) ) ) )

select #artworks.artwork_id,
		 aw.artwork_type,
		 aw.artwork_key,
		 aw.artwork_desc,
		 aw.version_no,
		 aw.artwork_status,
       aw.disk_ref,
       sh.shell_code,
       sh.shell_desc,
       sh.shell_type,
       sh.shell_expired,
       sh.shell_expiry_date,
       sh.shell_permanent
  from #artworks,
       artwork aw,
       shell_artwork sa,
       shell sh
 where #artworks.artwork_id = aw.artwork_id and
       #artworks.artwork_id = sa.artwork_id and
       sa.shell_code = sh.shell_code
return 0
GO
