/****** Object:  StoredProcedure [dbo].[p_cinelights_campaign_summary_main_rpt]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cinelights_campaign_summary_main_rpt]
GO
/****** Object:  StoredProcedure [dbo].[p_cinelights_campaign_summary_main_rpt]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
create PROC [dbo].[p_cinelights_campaign_summary_main_rpt]   @film_campaign_no int
as
/* Proc name:   p_cinelights_campaign_summary_main_rpt
 * Author:      Grant Carlson
 * Date:        23/2/2005
 * Description: Report data
 *              
 *
 * Changes:
*/                              

declare @error        				int,
        @err_msg                    varchar(150),
        --@error                         int,
        @total_charge_rate          money

select @total_charge_rate = isnull(sum(charge_rate),0)
from   v_cinelight_campaigns_detailed
where  film_campaign_no = @film_campaign_no

SELECT  distinct t.cinelight_campaign_no,
        t.film_campaign_no,
        t.film_campaign_name,
        t.cinelight_ref,
        t.cielight_campaign_name,
        t.cinelight_start_date,
        t.cinelight_end_date,
        t.production_cost,
        t.business_unit_id,
        t.media_product_id,
        t.agency_deal,
        t.branch_code,
        t.client_id,
        t.agency_id,
        t.rep_id,
        t.agency_commission,
        @total_charge_rate as total_charge_rate
FROM    v_cinelight_campaigns_detailed t 
WHERE   film_campaign_no = @film_campaign_no
GO
