/****** Object:  View [dbo].[v_cinetam_film_campaign]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_cinetam_film_campaign]
GO
/****** Object:  View [dbo].[v_cinetam_film_campaign]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
create view [dbo].[v_cinetam_film_campaign]
as
select			film_campaign.campaign_no, 
					convert(char(6), film_campaign.campaign_no) + ' - ' + film_campaign.product_desc as campaign_desc,
					cinetam_campaign_actuals.screening_date,
					sum(cinetam_campaign_actuals.attendance) as attendance,
					cinetam_demographics.cinetam_demographics_desc
from			cinetam_campaign_actuals, 
					film_campaign,
					cinetam_demographics
where			cinetam_campaign_actuals.campaign_no = film_campaign.campaign_no
and				cinetam_campaign_actuals.cinetam_demographics_id = cinetam_demographics.cinetam_demographics_id
and				screening_date > '1-jan-2011'
group by		film_campaign.campaign_no, 
					film_campaign.product_desc,
					cinetam_campaign_actuals.screening_date,
					cinetam_demographics.cinetam_demographics_desc
GO
