USE [production]
GO
/****** Object:  View [dbo].[v_campaign_package_attendance]    Script Date: 11/03/2021 2:30:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[v_campaign_package_attendance]
as
select package_id, movie_history.screening_date, SUM(attendance) as attendance from campaign_spot, v_certificate_item_distinct, movie_history
where campaign_spot.spot_id = v_certificate_item_distinct.spot_reference
and v_certificate_item_distinct.certificate_group = movie_history.certificate_group
group by package_id, movie_history.screening_date
GO
