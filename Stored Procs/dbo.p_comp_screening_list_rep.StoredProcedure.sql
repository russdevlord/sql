/****** Object:  StoredProcedure [dbo].[p_comp_screening_list_rep]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_comp_screening_list_rep]
GO
/****** Object:  StoredProcedure [dbo].[p_comp_screening_list_rep]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_comp_screening_list_rep]	@slide_competition_id	integer
as

/*
 * Declare Procedure Variables
 */

declare @error          		integer,
        @rowcount					integer

/*
 * Select Result Set
 */

  select competition.competition_desc,
         branch.country_code,
         branch.branch_code,
         branch.branch_name,
         slide_campaign.campaign_no,
         slide_campaign.name_on_slide,
         client.client_id,
         client.client_name,
         sales_rep.first_name,
         sales_rep.last_name,
         competition_entry.competition_entry_id,
         competition_entry.entry_name,
         competition_entry.address_1,
         competition_entry.address_2,
         competition_entry.address_3,
         competition_entry.phone,
         competition_entry.interim_winner_no,
         competition_entry.winner_no
    from competition,
         competition_entry,
         slide_campaign,
         sales_rep,
         client,
         branch
   where competition.slide_competition_id = competition_entry.slide_competition_id and
         competition_entry.campaign_no = slide_campaign.campaign_no and
         slide_campaign.service_rep = sales_rep.rep_id and
         slide_campaign.client_id = client.client_id and
         slide_campaign.branch_code = branch.branch_code and
         competition.slide_competition_id = @slide_competition_id
order by branch.country_code,
         branch.branch_code,
         slide_campaign.campaign_no

/*
 * Return Success
 */

return 0
GO
