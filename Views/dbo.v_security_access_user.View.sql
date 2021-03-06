/****** Object:  View [dbo].[v_security_access_user]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP VIEW [dbo].[v_security_access_user]
GO
/****** Object:  View [dbo].[v_security_access_user]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE VIEW [dbo].[v_security_access_user]
AS

select sa.user_id,
       sa.security_access_group_id,     
       sag.security_access_group_code
  from security_access sa,
       security_access_group sag      
 where sa.user_id = suser_name() and
-- where sa.user_id = 'gcarlson' and
       sa.security_access_group_id = sag.security_access_group_id
GO
