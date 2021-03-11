USE [production]
GO
/****** Object:  View [dbo].[v_follow_film_campaigns]    Script Date: 11/03/2021 2:30:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE VIEW [dbo].[v_follow_film_campaigns]
AS

select  br.country_code,
        fc.campaign_no,
        fc.product_desc 'campaign_name'
from    film_campaign fc,
        campaign_package cp,
        branch br
where   fc.campaign_no = cp.campaign_no
and     cp.follow_film = 'Y'
and     fc.branch_code = br.branch_code
GO
