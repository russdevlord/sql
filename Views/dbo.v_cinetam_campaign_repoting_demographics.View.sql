/****** Object:  View [dbo].[v_cinetam_campaign_repoting_demographics]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_cinetam_campaign_repoting_demographics]
GO
/****** Object:  View [dbo].[v_cinetam_campaign_repoting_demographics]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

create view [dbo].[v_cinetam_campaign_repoting_demographics]
as
select			film_campaign.campaign_no, 
					convert(char(6), film_campaign.campaign_no) + ' - ' + film_campaign.product_desc as campaign_desc,
					sum(cinetam_campaign_actuals.attendance) as attendance,
					cinetam_reporting_demographics_xref.cinetam_reporting_demographics_id,
					cinetam_reporting_demographics.cinetam_reporting_demographics_desc
from			cinetam_campaign_actuals, 
					film_campaign,
					cinetam_reporting_demographics_xref,
					cinetam_reporting_demographics					
where			cinetam_campaign_actuals.campaign_no = film_campaign.campaign_no
and				cinetam_campaign_actuals.cinetam_demographics_id = cinetam_reporting_demographics_xref.cinetam_demographics_id
and				Cinetam_reporting_demographics_xref.cinetam_reporting_demographics_id = cinetam_reporting_demographics.cinetam_reporting_demographics_id
group by		film_campaign.campaign_no, 
					film_campaign.product_desc,
					cinetam_reporting_demographics_xref.cinetam_reporting_demographics_id,cinetam_reporting_demographics.cinetam_reporting_demographics_desc
GO
