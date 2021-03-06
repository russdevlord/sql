/****** Object:  View [dbo].[v_movie_mix_wtd_att_avg]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_movie_mix_wtd_att_avg]
GO
/****** Object:  View [dbo].[v_movie_mix_wtd_att_avg]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




create view [dbo].[v_movie_mix_wtd_att_avg] 
as
select			temp_table.screening_date,
					convert(numeric(18,6), sum(temp_table.no_prints * temp_table.attendance)) as attendance_sum,
					convert(numeric(18,6), sum(temp_table.no_prints)) as no_prints, 
					temp_table.country_code,
					temp_table.film_market_no,
					temp_table.complex_region_class,
					temp_table.classification_id 
from			(select			count(mh.movie_id) as no_movies,
											mh.movie_id,
											mh.country as country_code,
											mh.complex_id,
											c.complex_name,
											fm.film_market_desc,
											fm.film_market_no,
											mh.screening_date,
											mh.attendance,
											c.complex_region_class,
											(select		max(classification_id) 
											from			movie_country 
											where			movie_country.movie_id = mh.movie_id 
											and				movie_country.country_code = mh.country) as classification_id,
											(select		count(spot_reference) 
											from			v_certificate_item_distinct, 
																certificate_group,
																movie_history,
																campaign_spot
											where			spot_reference = campaign_spot.spot_id
											and				package_id in (select package_id from campaign_package where follow_film = 'N') 
											and				certificate_group.certificate_group_id = v_certificate_item_distinct.certificate_group
											and				movie_history.screening_date = mh.screening_date
											and				movie_history.complex_id = mh.complex_id
											and				movie_history.movie_id = mh.movie_id
											and				movie_history.certificate_group = certificate_group.certificate_group_id
											and				movie_id <> 102) as no_prints 
						from			movie_history mh,
											complex c,
											film_market fm
						where			mh.movie_id = mh.movie_id
						and				mh.complex_id = mh.complex_id
						and				mh.screening_date = mh.screening_date
						and				mh.complex_id = c.complex_id
						and				c.film_market_no = fm.film_market_no
						group by    mh.movie_id,
											mh.country,
											mh.complex_id,
											c.complex_name,
											fm.film_market_desc,
											fm.film_market_no,
											mh.screening_date,
											mh.attendance,
											c.complex_region_class) as temp_table
group by		temp_table.screening_date, 
					temp_table.country_code,
					temp_table.film_market_no,
					temp_table.complex_region_class,
					temp_table.classification_id 


GO
