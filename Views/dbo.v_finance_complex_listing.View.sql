/****** Object:  View [dbo].[v_finance_complex_listing]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP VIEW [dbo].[v_finance_complex_listing]
GO
/****** Object:  View [dbo].[v_finance_complex_listing]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



create view [dbo].[v_finance_complex_listing]
as
select			complex.complex_id,
					complex.complex_name,
					complex.exhibitor_id,
					complex.state_code,
					complex.address_1,
					complex.address_2
					town_suburb,
					complex.postcode,
					complex.phone,
					phone_proj,
					complex.fax,
					email,
					manager
					max_ads,
					max_time,
					mg_max_ads,
					mg_max_time,
					rent_group_desc,
					weighting,
					film_market_desc,
					region_class_desc,
					branch.country_code,
					(select		sum(attendance) 
					from			movie_history 
					where			complex_id = complex.complex_id 
					and				screening_date between dateadd(wk, -51,(select max(screening_date) from film_screening_dates where attendance_status ='X')) and (select max(screening_date) from film_screening_dates where attendance_status ='X')) as attendance,
					(select count(*) from cinema where complex_id = complex.complex_id and cinema_category in ('N', 'A') and active_flag = 'Y') as normal_screens,
					(select count(*) from cinema where complex_id = complex.complex_id and cinema_category in ('G', 'L','C') and active_flag = 'Y') as premium_screens,
					(select count(*) from cinelight where complex_id = complex.complex_id and cinelight_status = 'O') as digilites,
					complex.cinatt_weighting
from			complex,
					complex_region_class,
					complex_rent_groups,
					film_market,
					branch
where			film_complex_status <> 'C'
and				complex.complex_region_class = complex_region_class.complex_region_class
and				complex.complex_rent_group = complex_rent_groups.rent_group_no
and				complex.film_market_no = film_market.film_market_no
and				complex.branch_code =branch.branch_code
and				complex_id > 3

GO
