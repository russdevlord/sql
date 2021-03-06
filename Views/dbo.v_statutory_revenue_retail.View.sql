/****** Object:  View [dbo].[v_statutory_revenue_retail]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_statutory_revenue_retail]
GO
/****** Object:  View [dbo].[v_statutory_revenue_retail]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
create view [dbo].[v_statutory_revenue_retail]
as
select      fc.campaign_no 'campaign_no',
            fc.branch_code  'branch_code',
            fc.business_unit_id 'business_unit_id',
            play.media_product_id 'media_product_id',
            count(spot_id) 'no_spots',
            spot_type 'Spot Type',
            'Standard' as 'Revenue Type',
            cs.screening_date 'Screening Date',
            ((select sum(charge_rate) from outpost_spot where campaign_no = fc.campaign_no and cs.spot_status <> 'P' ) + (select sum(makegood_rate) from outpost_spot where campaign_no = fc.campaign_no and cs.spot_status <> 'P')) / (select count(spot_id) from outpost_spot where campaign_no = fc.campaign_no and cs.spot_status <> 'P' and spot_type not in ('V','M')) as 'Average Rate'
from        outpost_spot cs,
            outpost_package cp,
            film_campaign fc,
            outpost_player_xref opx,
			outpost_player play
where       cs.package_id = cp.package_id
and         cp.campaign_no = fc.campaign_no
and         cs.spot_status <> 'P'
and         cs.spot_type not in ('V','M')
and         cs.outpost_panel_id = opx.outpost_panel_id
and         opx.player_name = play.player_name
group by    fc.campaign_no,
            fc.branch_code,
            fc.business_unit_id,
            play.media_product_id,
             cs.screening_date,
             fc.start_date,
             cs.spot_type,
             cs.spot_status
union all
select      fc.campaign_no 'campaign_no',
            fc.branch_code  'branch_code',
            fc.business_unit_id 'business_unit_id',
            10 'media_product_id',
            count(spot_id) 'no_spots',
            spot_type 'Spot Type',
            'Standard' as 'Revenue Type',
            cs.op_screening_date 'Screening Date',
            ((select sum(charge_rate) from v_retail_wall_spots_non_proposed where campaign_no = fc.campaign_no) + (select sum(makegood_rate) from v_retail_wall_spots_non_proposed where campaign_no = fc.campaign_no)) / (select count(spot_id) from v_retail_wall_spots_non_proposed where campaign_no = fc.campaign_no and spot_type not in ('V','M')) as 'Average Rate'
from        v_retail_wall_spots_non_proposed cs,
            inclusion inc,
            film_campaign fc
where       cs.inclusion_id = inc.inclusion_id
and         inc.campaign_no = fc.campaign_no
and         cs.spot_type not in ('V','M')
group by    fc.campaign_no,
            fc.branch_code,
            fc.business_unit_id,
             cs.op_screening_date,
             fc.start_date,
             cs.spot_type,
             cs.spot_status
GO
