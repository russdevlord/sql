/****** Object:  View [dbo].[v_commbank]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_commbank]
GO
/****** Object:  View [dbo].[v_commbank]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
create view [dbo].[v_commbank]
as
select complex.complex_name, product_desc, release_period, liability_type.liability_type_desc, sum(cinema_amount) as cinema_liability from spot_liability, complex, campaign_spot, film_campaign, liability_type 
where client_id in (50226,50573)
and campaign_spot.spot_id = spot_liability.spot_id
and spot_liability.complex_id = complex.complex_id 
and spot_liability.liability_type = liability_type.liability_type_id
and campaign_spot.campaign_no = film_campaign.campaign_no
group by  complex.complex_name, release_period, liability_type.liability_type_desc, product_desc



GO
