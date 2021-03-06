/****** Object:  View [dbo].[v_all_retail_spots]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_all_retail_spots]
GO
/****** Object:  View [dbo].[v_all_retail_spots]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

create view [dbo].[v_all_retail_spots]
as
select      CASE When outpost_player.media_product_id = 9 Then 'Retail Panels'
			When outpost_player.media_product_id = 11 Then 'Retail Superscreen'
			When outpost_player.media_product_id = 12 Then 'Petro Panel'
			When outpost_player.media_product_id = 13 Then 'Petro CStore'
			Else NULL
			End Type,
			outpost_panel.outpost_venue_id,
            screening_date,
            billing_date,
            sum(charge_rate) as charge_rate_sum,
            count(spot_id) as no_spots,
            spot_type,
            spot_status,
            campaign_no,
            billing_period,
            package_id
from        outpost_spot,
            outpost_panel,
            outpost_player,
            outpost_player_xref
where       outpost_spot.outpost_panel_id = outpost_panel.outpost_panel_id            
AND			outpost_player_xref.outpost_panel_id = outpost_panel.outpost_panel_id
AND			outpost_player_xref.player_name = outpost_player.player_name
group by    outpost_panel.outpost_venue_id,
            screening_date,
            billing_date,
            spot_type,
            spot_status,
            campaign_no,
            billing_period,
            package_id,
            media_product_id
union all
select      CASE When inclusion.inclusion_type = 18 Then 'Retail Wall'
			When inclusion.inclusion_type = 26 Then 'Sports'
			Else NULL
			End Type,
			outpost_venue_id,
            op_screening_date,
            op_billing_date,
            sum(charge_rate),
            count(spot_id) as no_spots,
            spot_type,
            spot_status,
            inclusion_spot.campaign_no,
            inclusion_spot.billing_period,
            NULL Package_ID
from        inclusion_spot,
			inclusion
where       op_billing_date is not null
		AND inclusion.inclusion_id = inclusion_spot.inclusion_id
group by    outpost_venue_id,
            op_screening_date,
            op_billing_date,
            spot_type,
            spot_status,
            inclusion_spot.campaign_no,
            inclusion_spot.billing_period,
            inclusion_type
union all
select      'Takeouts' Type, outpost_venue_id,
            dateadd(dd, -6, revenue_period),
            dateadd(dd, -6, revenue_period),
            sum(takeout_rate),
            count(spot_id) as no_spots,
            spot_type,
            spot_status,
            campaign_no,
            revenue_period,
            NULL Package_ID
from        inclusion_spot
where       takeout_rate <> 0
and         inclusion_id in (select inclusion_id from inclusion where inclusion_category in ('A','R','W'))
group by    outpost_venue_id,
            revenue_period,
            spot_type,
            spot_status,
            campaign_no


GO
