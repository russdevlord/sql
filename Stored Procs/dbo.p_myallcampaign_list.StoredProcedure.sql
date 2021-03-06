/****** Object:  StoredProcedure [dbo].[p_myallcampaign_list]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_myallcampaign_list]
GO
/****** Object:  StoredProcedure [dbo].[p_myallcampaign_list]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE      proc [dbo].[p_myallcampaign_list]	@arg_login_id		varchar(30),
                                        @arg_campaign_no	int
AS

SET NOCOUNT ON


SELECT		film_campaign.campaign_status,
			film_campaign.campaign_no,
			film_campaign.product_desc,
			film_campaign.start_date,
			film_campaign.end_date
FROM		employee,
			film_campaign_reps,
			film_campaign
WHERE		employee.login_id = @arg_login_id
and			employee.rep_id = film_campaign_reps.rep_id
and			film_campaign_reps.control_idc <> 'A'
and			film_campaign_reps.campaign_no = film_campaign.campaign_no
and			((@arg_campaign_no is not null 
and			film_campaign.campaign_no = @arg_campaign_no)
or			@arg_campaign_no is null)
GROUP BY	film_campaign.campaign_status,
			film_campaign.campaign_no,
			film_campaign.product_desc,
			film_campaign.start_date,
			film_campaign.end_date
union
SELECT		distinct fc.campaign_status,
			fc.campaign_no,
			fc.product_desc,
			fc.start_date,
			fc.end_date
FROM		employee e,
			sales_team_coordinators stc,
			campaign_rep_teams crt, 
			film_campaign_reps fcr, 
			film_campaign fc
WHERE		e.login_id = @arg_login_id
and			((@arg_campaign_no is not null 
and			fc.campaign_no = @arg_campaign_no)
or			@arg_campaign_no is null)
and			fc.campaign_no = fcr.campaign_no
and 		fcr.campaign_reps_id = crt.campaign_reps_id
and			crt.team_id = stc.team_id
and			e.employee_id = stc.employee_id	
GROUP BY	fc.campaign_status,
			fc.campaign_no,
			fc.product_desc,
			fc.start_date,
			fc.end_date
ORDER BY	film_campaign.campaign_no

return 0
GO
