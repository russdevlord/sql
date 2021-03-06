/****** Object:  View [dbo].[v_complex_util_heat_map]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_complex_util_heat_map]
GO
/****** Object:  View [dbo].[v_complex_util_heat_map]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[v_complex_util_heat_map]
as
select movie_type	,
exhibitor_name	,
exhibitor_id	,
film_market_no	,
film_market_desc	,
complex_id	,
complex_name	,
screening_date	,
premium_cinema	,
movie_name	,
group_name	,
occurence	,
time_avail	,
duration	,
complex_movie_rank	,
exhibitor_movie_rank	,
country_movie_rank	,
complex_top_1	,
complex_top_2	,
complex_not_top_1	,
complex_not_top_2	,
exhibitor_top_1	,
exhibitor_top_2	,
exhibitor_not_top_1	,
exhibitor_not_top_2	,
country_top_1	,
country_top_2	,
country_not_top_1	,
country_not_top_2	,
benchmark_end	,
cal_year	,
cal_qtr	,
fin_year	,
fin_qtr	,
cal_half	,
fin_half
 from complex_yield_charge where  screening_date >= '1-jan-2015'
GO
