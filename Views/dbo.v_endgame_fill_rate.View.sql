/****** Object:  View [dbo].[v_endgame_fill_rate]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_endgame_fill_rate]
GO
/****** Object:  View [dbo].[v_endgame_fill_rate]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[v_endgame_fill_rate]
as
select			branch_code,
				long_name,
				occurence,
				premium_cinema,
				screening_date,
				three_d_type,
				complex_name,
				film_market_no,
				(select			max_time + mg_max_time 
				from			complex_date 
				where			complex_id = movie_history.complex_id 
				and				screening_date= '25-apr-2019') as time_avail, 
				(select			SUM(campaign_package.duration)
				from			campaign_package
				inner join		campaign_spot on campaign_package.package_id = campaign_spot.package_id
				inner join		v_certificate_item_distinct on campaign_spot.spot_id = v_certificate_item_distinct.spot_reference
				where			v_certificate_item_distinct.certificate_group = movie_history.certificate_group
				) as time_used 
from			movie_history 
inner join		movie on movie_history.movie_id = movie.movie_id
inner join		complex on movie_history.complex_id = complex.complex_id
where			movie_history.movie_id in (12076,12501) 
GO
