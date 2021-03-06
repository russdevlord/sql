/****** Object:  View [dbo].[v_exhibitor_campaign_weighted_rate]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_exhibitor_campaign_weighted_rate]
GO
/****** Object:  View [dbo].[v_exhibitor_campaign_weighted_rate]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




CREATE view [dbo].[v_exhibitor_campaign_weighted_rate] as
select exhibitor_name, exhibitor.state_code, complex_name, type, billing_date, bill_xref.benchmark_end as billing_period, v_all_cinema_spots.screening_date,  screen_xref.benchmark_end as screen_period, film_campaign.campaign_no, film_campaign.product_desc, sum(cinema_rate_sum) as weighted_rate
from exhibitor, v_all_cinema_spots, complex, film_campaign, film_screening_date_xref screen_xref, film_screening_date_xref bill_xref
where complex.complex_id = v_all_cinema_spots.complex_id 
and complex.exhibitor_id = exhibitor.exhibitor_id 
and v_all_cinema_spots.campaign_no = film_campaign.campaign_no
and screen_xref.screening_date = v_all_cinema_spots.screening_date
and bill_xref.screening_date = v_all_cinema_spots.billing_date
and screen_xref.screening_date >= '28-jun-2014' 
--'1-jan-2014'

--and screen_xref.screening_date >= '1-jan-2008' 

group by exhibitor_name, exhibitor.state_code, complex_name, type, billing_date, bill_xref.benchmark_end, v_all_cinema_spots.screening_date,  screen_xref.benchmark_end, film_campaign.campaign_no, film_campaign.product_desc



GO
