/****** Object:  View [dbo].[v_cinatt_estimate]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_cinatt_estimate]
GO
/****** Object:  View [dbo].[v_cinatt_estimate]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE VIEW [dbo].[v_cinatt_estimate] 
AS


select	attendance_campaign_complex_estimates.campaign_no,
        attendance_campaign_complex_estimates.screening_date,
		branch.country_code,
        attendance_campaign_complex_estimates.complex_id,
        attendance_campaign_complex_estimates.attendance
from	attendance_campaign_complex_estimates,
		film_campaign,
		branch
where 	attendance_campaign_complex_estimates.campaign_no = film_campaign.campaign_no
and		film_campaign.branch_code = branch.branch_code
GO
