/****** Object:  View [dbo].[v_cinetam_campaign_package_reporting_demographics]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_cinetam_campaign_package_reporting_demographics]
GO
/****** Object:  View [dbo].[v_cinetam_campaign_package_reporting_demographics]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
create view [dbo].[v_cinetam_campaign_package_reporting_demographics]
as
Select c.package_id, convert(char(6), c.package_id) + ' - ' + a.Long_name  as package_desc,
sum(a.attendance) as attendance, a.cinetam_reporting_demographics_ID
FROM v_cinetam_movie_history_Details a
JOIN V_certificate_item_distinct b
ON a.certificate_group = b.certificate_group
JOIN campaign_spot c
ON b.spot_reference = c.spot_id
Group by c.package_id, a.Long_name , a.cinetam_reporting_demographics_ID
GO
