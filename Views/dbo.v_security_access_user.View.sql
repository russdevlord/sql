USE [production]
GO
/****** Object:  View [dbo].[v_security_access_user]    Script Date: 11/03/2021 2:30:32 PM ******/
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
