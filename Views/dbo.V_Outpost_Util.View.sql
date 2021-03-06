/****** Object:  View [dbo].[V_Outpost_Util]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP VIEW [dbo].[V_Outpost_Util]
GO
/****** Object:  View [dbo].[V_Outpost_Util]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create View [dbo].[V_Outpost_Util] AS
select  outpost_venue_name, business_unit_desc,
			media_product_desc, 
            benchmark_end,
            sum(avail_camp8) 'avail_camp8',
            sum(avail_camp6) 'avail_camp6',
            sum(used_camp) 'used_camp',
            sum(used_camp) / sum(avail_camp8) 'util8',
            sum(used_camp) / sum(avail_camp6) 'util6'
from        (select    outpost_venue_name, media_product_desc, business_unit_desc,
                    outpost_panel_id,
                    outpost_screening_date_xref.screening_date,
                    outpost_screening_date_xref.no_days,
                    outpost_screening_date_xref.benchmark_end,
                    sum(avail_camps_8) * no_days / 7  as avail_camp8,
                    sum(avail_camps_6) * no_days / 7 as avail_camp6,
                    sum(used_camps) * no_days / 7 as used_camp
        from        (select	    venue.outpost_venue_name, business_unit.business_unit_desc,
								media_product_desc, 
                                opx.outpost_panel_id,
                                os.screening_date,
                                8 as avail_camps_8,
                                6 as avail_camps_6,
                                count(distinct os.campaign_no) as used_camps
                    from 	    outpost_spot os,
                                outpost_package op,
                                outpost_player_xref opx,
                                outpost_player play,
                                media_product,
                                outpost_venue venue, 
                                film_campaign,
								business_unit
                    where 	    os.spot_status <> 'P'
                    and         os.package_id = op.package_id
                    and         os.outpost_panel_id = opx.outpost_panel_id
                    and         opx.player_name = play.player_name
                    and         media_product.media_product_id = play.media_product_id
                    and			play.outpost_venue_id = venue.outpost_venue_id
                    and			film_campaign.campaign_no = os.campaign_no
                    and			business_unit.business_unit_id = film_campaign.business_unit_id
                    and         spot_status <> 'C'
                    and         screening_trailers <> 'D'
                    group by    media_product_desc, 
                                opx.outpost_panel_id,
                                os.screening_date,
                                venue.outpost_venue_name,
                                business_unit.business_unit_desc) temp_table,
                    outpost_screening_date_xref                         
        where       outpost_screening_date_xref.screening_date = temp_table.screening_date
        group by    media_product_desc, 
                    outpost_screening_date_xref.screening_date,
                    outpost_screening_date_xref.no_days,
                    outpost_panel_id,
                    outpost_venue_name,
                    business_unit_desc,
                    outpost_screening_date_xref.benchmark_end) as temp_table_2
group by    media_product_desc, 
            benchmark_end,
            outpost_venue_name,
            business_unit_desc

GO
