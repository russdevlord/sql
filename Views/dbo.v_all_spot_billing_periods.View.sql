/****** Object:  View [dbo].[v_all_spot_billing_periods]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_all_spot_billing_periods]
GO
/****** Object:  View [dbo].[v_all_spot_billing_periods]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO




create view [dbo].[v_all_spot_billing_periods]

as

select		campaign_no,
            billing_period
from        campaign_spot
group by    campaign_no,
            billing_period
union all
select      campaign_no,
            billing_period
from        cinelight_spot,
            cinelight
where       cinelight_spot.cinelight_id = cinelight.cinelight_id
group by    campaign_no,
            billing_period
union all
select      campaign_no,
            billing_period
from        inclusion_spot
where       billing_date is not null
group by    campaign_no,
            billing_period
union all
select      campaign_no,
            revenue_period
from        inclusion_spot
where       takeout_rate <> 0
group by    campaign_no,
            revenue_period
union all            
select      campaign_no,
            billing_period
from        outpost_spot,
            outpost_panel,
            outpost_player,
            outpost_player_xref
where       outpost_spot.outpost_panel_id = outpost_panel.outpost_panel_id            
AND			outpost_player_xref.outpost_panel_id = outpost_panel.outpost_panel_id
AND			outpost_player_xref.player_name = outpost_player.player_name
group by    campaign_no,
            billing_period
union all select campaign_no, billing_period from inclusion where invoice_client = 'Y' and include_on_proposal = 'Y' group by    campaign_no,
            billing_period
				

GO
