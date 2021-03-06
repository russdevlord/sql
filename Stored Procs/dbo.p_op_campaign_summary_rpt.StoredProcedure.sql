/****** Object:  StoredProcedure [dbo].[p_op_campaign_summary_rpt]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_op_campaign_summary_rpt]
GO
/****** Object:  StoredProcedure [dbo].[p_op_campaign_summary_rpt]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
create PROC [dbo].[p_op_campaign_summary_rpt]   @film_campaign_no int
as
/* Proc name:   p_op_campaign_summary_rpt
 * Author:      Grant Carlson
 * Date:        23/2/2005
 * Description: Report data
 *              
 *
 * Changes:
*/                              

declare @error        				int,
        @err_msg                    varchar(150)

SELECT  t.outpost_panel_campaign_no,
        t.film_campaign_no,
        t.film_campaign_name,
        t.outpost_panel_ref,
        t.cielight_campaign_name,
        t.outpost_panel_start_date,
        t.outpost_panel_end_date,
        t.production_cost,
        t.business_unit_id,
        t.media_product_id,
        t.agency_deal,
        t.branch_code,
        t.client_id,
        t.agency_id,
        t.rep_id,
        t.agency_commission,
        t.outpost_venue_id,
        t.outpost_venue_name,
        t.outpost_panel_id,
        t.outpost_panel_description,
        t.screening_week,
        t.billing_status,
        t.billing_period,
        t.billing_date,
        t.default_billing_rate,
        t.charge_rate,
        t.production_rate,
        t.benchmark_end,
        t.prorata_days
FROM    v_outpost_panel_campaigns_detailed t 
WHERE   film_campaign_no = @film_campaign_no
GO
