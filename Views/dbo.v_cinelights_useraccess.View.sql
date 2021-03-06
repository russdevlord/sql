/****** Object:  View [dbo].[v_cinelights_useraccess]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_cinelights_useraccess]
GO
/****** Object:  View [dbo].[v_cinelights_useraccess]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE VIEW [dbo].[v_cinelights_useraccess]
AS

select case when suser_sname() = 'VMCONTROL\gcarlson' then 'SUPER'
            when suser_sname() = 'VMCONTROL\gmarsh' then 'SUPER'
            when suser_sname() = 'VMCONTROL\devtestmgr' then 'SUPER'
            when suser_sname() = 'VMCONTROL\awrightson' then 'SUPER'
            when suser_sname() = 'VMCONTROL\mrussell' then 'SUPER'
            when suser_sname() = 'VMCONTROL\akhodabandehloo' then 'SUPER'
            else 'REP' end as user_role
GO
