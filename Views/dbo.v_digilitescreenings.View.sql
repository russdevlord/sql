/****** Object:  View [dbo].[v_digilitescreenings]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_digilitescreenings]
GO
/****** Object:  View [dbo].[v_digilitescreenings]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO


create view [dbo].[v_digilitescreenings] as
select film_campaign.campaign_no, product_desc, film_campaign.start_date, sum(cinelight_spot.charge_rate) as rev, film_screening_date_xref.screening_date,
film_screening_date_xref.benchmark_end, complex.complex_name, cinelight.cinelight_desc, cinelight_dsn_players.player_name 
from film_campaign, cinelight_package, cinelight_spot, complex, cinelight_dsn_players, cinelight, cinelight_dsn_player_xref, film_screening_date_xref
where film_campaign.campaign_no = cinelight_package.campaign_no
and cinelight_package.package_id = cinelight_spot.package_id
and cinelight_spot.cinelight_id = cinelight.cinelight_id
and cinelight.cinelight_id = cinelight_dsn_player_xref.cinelight_id
and	 cinelight_dsn_player_xref.player_name = cinelight_dsn_players.player_name
and cinelight_dsn_players.complex_id = complex.complex_id
and cinelight_spot.screening_date = film_screening_date_xref.screening_date
and cinelight_spot.screening_date > '1-jan-2009'
group by film_campaign.campaign_no, product_desc,  film_campaign.start_date, film_screening_date_xref.screening_date, film_screening_date_xref.benchmark_end, complex.complex_name, cinelight.cinelight_desc, cinelight_dsn_players.player_name





GO
