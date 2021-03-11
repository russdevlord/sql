USE [production]
GO
/****** Object:  View [dbo].[v_slide_billings_by_campaign]    Script Date: 11/03/2021 2:30:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE VIEW [dbo].[v_slide_billings_by_campaign]
AS
select      spot.campaign_no as campaign_no,
            spot.accounting_period as accounting_period,
            sum(spot.billing_total) as billing_total
	 from  slide_spot_summary spot
group by   spot.campaign_no,
           spot.accounting_period
having     sum(spot.billing_total) > 0
GO
