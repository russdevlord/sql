USE [production]
GO
/****** Object:  View [dbo].[v_cinelights_useraccess]    Script Date: 11/03/2021 2:30:32 PM ******/
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
