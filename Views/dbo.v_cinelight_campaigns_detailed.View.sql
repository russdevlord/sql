/****** Object:  View [dbo].[v_cinelight_campaigns_detailed]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_cinelight_campaigns_detailed]
GO
/****** Object:  View [dbo].[v_cinelight_campaigns_detailed]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE VIEW [dbo].[v_cinelight_campaigns_detailed] 
AS

    SELECT  t.cinelight_campaign_no as cinelight_campaign_no,
	        t.campaign_no as film_campaign_no,
            fc.product_desc as film_campaign_name,
	        t.cinelight_ref as cinelight_ref,
	        t.campaign_name as cielight_campaign_name,
	        t.start_date as cinelight_start_date,
	        t.end_date as cinelight_end_date,
	        t.production_cost as production_cost,
	        t.business_unit_id as business_unit_id,
	        t.media_product_id as media_product_id,
	        t.agency_deal as agency_deal,
	        t.branch_code as branch_code,
	        t.client_id as client_id,
	        t.agency_id as agency_id,
	        t.rep_id as rep_id,
	        t.commission as agency_commission,
	        t.complex_id as complex_id,
            cpx.complex_name as complex_name,
	        t.cinelight_id as cinelight_id,
--            cl.descr as cinelight_description,
            am.medium_name as cinelight_description,
            am.medium_name as cinelight_type_desc,
	        t.screening_week as screening_week,
	        t.billing_status as billing_status,
	        t.billing_period as billing_period,
	        t.billing_date as billing_date,
	        t.rate as default_billing_rate,
	        t.charge_rate as charge_rate,
	        t.production_rate as production_rate,
	        t.benchmark_end as benchmark_end,
	        t.prorata_days as prorata_days
    FROM    v_cinemarketing_billing_data t,
            complex cpx,
            film_campaign fc,
            cinelights cl,
            advertising_medium am
    WHERE   t.campaign_no = fc.campaign_no
    and     t.complex_id = cpx.complex_id
    and     t.cinelight_id = cl.cinelight_id
    and     cl.cinelight_type_id = am.advertising_medium_type_id
GO
