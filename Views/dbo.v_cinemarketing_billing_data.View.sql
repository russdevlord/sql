/****** Object:  View [dbo].[v_cinemarketing_billing_data]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_cinemarketing_billing_data]
GO
/****** Object:  View [dbo].[v_cinemarketing_billing_data]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE VIEW [dbo].[v_cinemarketing_billing_data]
AS

SELECT	cc.cinelight_campaign_no,
	    cc.campaign_no,
	    cc.cinelight_ref,
	    cc.campaign_name,
	    cc.start_date,
	    cc.end_date,
	    cc.production_cost,
        fc.business_unit_id,
        3 as media_product_id,
        fc.agency_deal,
        fc.branch_code,
        fc.client_id,
        fc.billing_agency as agency_id,
        fc.rep_id,
        fc.commission,
        cl.complex_id,
        cb.cinelight_id,
	    cb.screening_week,
	    cb.billing_status,
	    cb.billing_period,
	    cb.billing_date,
	    cb.rate,
	    cb.charge_rate,
	    cb.production_rate,
        xr.benchmark_end,
        xr.no_days as prorata_days
FROM    dbo.cinelight_campaigns cc,
        dbo.cinelight_billings cb,
        dbo.film_campaign fc,
        dbo.film_screening_date_xref xr,
        dbo.cinelights cl
WHERE   cc.cinelight_campaign_no = cb.cinelight_campaign_no
and     cc.campaign_no = fc.campaign_no
and     cb.screening_week = xr.screening_date
and     cb.cinelight_id = cl.cinelight_id
GO
