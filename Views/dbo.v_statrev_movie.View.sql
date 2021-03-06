/****** Object:  View [dbo].[v_statrev_movie]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_statrev_movie]
GO
/****** Object:  View [dbo].[v_statrev_movie]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
create view [dbo].[v_statrev_movie]
as
select 		long_name, benchmark_end,country,sum(revenue) as revenue
from 			(select 		long_name, 
										benchmark_end,
										movie_history.country,
										sum(avg_rate) as revenue 
					from 			v_certificate_item_distinct,  
										campaign_spot_redirect_xref, 
										movie_history, 
										movie, 
										statrev_spot_rates,
										film_screening_date_xref
					where 		v_certificate_item_distinct.spot_reference = campaign_spot_redirect_xref.redirect_spot_id
					and				campaign_spot_redirect_xref.original_spot_id =  statrev_spot_rates.spot_id
					and				v_certificate_item_distinct.certificate_group= movie_history.certificate_group
					and				movie_history.movie_id  = movie.movie_id
					and				film_screening_date_xref.screening_date = movie_history.screening_date
					group by 	long_name,
										benchmark_end,
										movie_history.country
					union all
					select 		long_name, 
										benchmark_end,
										movie_history.country,
										sum(avg_rate) as revenue 
					from 			v_certificate_item_distinct,  
										movie_history,
										movie, 
										statrev_spot_rates,
										film_screening_date_xref
					where 		v_certificate_item_distinct.spot_reference =  statrev_spot_rates.spot_id
					and 			v_certificate_item_distinct.spot_reference  not in (select redirect_spot_id from campaign_spot_redirect_xref)
					and				v_certificate_item_distinct.certificate_group= movie_history.certificate_group
					and				movie_history.movie_id  = movie.movie_id
					and				film_screening_date_xref.screening_date = movie_history.screening_date
					group by 	long_name,
										benchmark_end,
										movie_history.country
					union all
					select 		long_name, 
										release_period,
										movie_history.country,
										sum(spot_amount) as revenue 
					from 			v_certificate_item_distinct,  
										campaign_spot_redirect_xref, 
										movie_history, 
										movie, 
										spot_liability
					where 		v_certificate_item_distinct.spot_reference = campaign_spot_redirect_xref.redirect_spot_id
					and				campaign_spot_redirect_xref.original_spot_id =  spot_liability.spot_id
					and				v_certificate_item_distinct.certificate_group= movie_history.certificate_group
					and				movie_history.movie_id  = movie.movie_id
					and				spot_liability.liability_type in (7,8,17,18)
					group by 	long_name,
										release_period,
										movie_history.country
					union all
					select 		long_name, 
										release_period,
										movie_history.country,
										sum(spot_amount) as revenue 
					from 			v_certificate_item_distinct,  
										movie_history,
										movie, 
										spot_liability
					where 		v_certificate_item_distinct.spot_reference =  spot_liability.spot_id
					and 			v_certificate_item_distinct.spot_reference  not in (select redirect_spot_id from campaign_spot_redirect_xref)
					and				v_certificate_item_distinct.certificate_group= movie_history.certificate_group
					and				movie_history.movie_id  = movie.movie_id
					and				spot_liability.liability_type in (7,8,17,18)
					group by 	long_name,
										release_period,
										movie_history.country
					) as movie_revenue
group by 	long_name,
					country,
					benchmark_end
GO
