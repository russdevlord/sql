/****** Object:  View [dbo].[v_campaign_package_attendance]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_campaign_package_attendance]
GO
/****** Object:  View [dbo].[v_campaign_package_attendance]    Script Date: 12/03/2021 10:03:48 AM ******/
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
