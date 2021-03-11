/****** Object:  View [dbo].[v_slide_billings_by_campaign]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_slide_billings_by_campaign]
GO
/****** Object:  View [dbo].[v_slide_billings_by_campaign]    Script Date: 12/03/2021 10:03:48 AM ******/
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
