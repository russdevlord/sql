/****** Object:  View [dbo].[v_movie_mix_averages_nz]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_movie_mix_averages_nz]
GO
/****** Object:  View [dbo].[v_movie_mix_averages_nz]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO






CREATE view [dbo].[v_movie_mix_averages_nz]
as
select 'Metro' as type, v_cinetam_movie_mix_wtd_att_avg_nz.screening_date, v_cinetam_movie_mix_wtd_att_avg_nz.country_code, cinetam_reporting_demographics_desc, film_screening_dates.attendance_period_no, attendance_year_end,  sum(attendance_sum) / sum(no_prints) as avg_attendance
from v_cinetam_movie_mix_wtd_att_avg_nz, cinetam_reporting_demographics, film_screening_dates
where	complex_region_class = 'M'
and v_cinetam_movie_mix_wtd_att_avg_nz.cinetam_reporting_demographics_id = cinetam_reporting_demographics.cinetam_reporting_demographics_id
and film_screening_dates.screening_date = v_cinetam_movie_mix_wtd_att_avg_nz.screening_date
and film_screening_dates.screening_date > '26-dec-2010'
and film_screening_dates.attendance_period_no <> 53
group by v_cinetam_movie_mix_wtd_att_avg_nz.screening_date, country_code, cinetam_reporting_demographics_desc, film_screening_dates.attendance_period_no, attendance_year_end
having sum(no_prints) <> 0
union
select 'Regional', v_cinetam_movie_mix_wtd_att_avg_nz.screening_date, v_cinetam_movie_mix_wtd_att_avg_nz.country_code, cinetam_reporting_demographics_desc, film_screening_dates.attendance_period_no, attendance_year_end, sum(attendance_sum) / sum(no_prints) as avg_attendance
from v_cinetam_movie_mix_wtd_att_avg_nz, cinetam_reporting_demographics, film_screening_dates
where	complex_region_class != 'M'
and v_cinetam_movie_mix_wtd_att_avg_nz.cinetam_reporting_demographics_id = cinetam_reporting_demographics.cinetam_reporting_demographics_id
and film_screening_dates.screening_date = v_cinetam_movie_mix_wtd_att_avg_nz.screening_date
and film_screening_dates.attendance_period_no <> 53
and film_screening_dates.screening_date > '26-dec-2010'
group by v_cinetam_movie_mix_wtd_att_avg_nz.screening_date, v_cinetam_movie_mix_wtd_att_avg_nz.country_code, cinetam_reporting_demographics_desc, film_screening_dates.attendance_period_no, attendance_year_end
having sum(no_prints) <> 0
union
select 'All', v_cinetam_movie_mix_wtd_att_avg_nz.screening_date, v_cinetam_movie_mix_wtd_att_avg_nz.country_code, cinetam_reporting_demographics_desc, film_screening_dates.attendance_period_no, attendance_year_end, sum(attendance_sum) / sum(no_prints) as avg_attendance
from v_cinetam_movie_mix_wtd_att_avg_nz, cinetam_reporting_demographics, film_screening_dates
where	v_cinetam_movie_mix_wtd_att_avg_nz.cinetam_reporting_demographics_id = cinetam_reporting_demographics.cinetam_reporting_demographics_id
and film_screening_dates.screening_date = v_cinetam_movie_mix_wtd_att_avg_nz.screening_date
and film_screening_dates.attendance_period_no <> 53
and film_screening_dates.screening_date > '26-dec-2010'
group by v_cinetam_movie_mix_wtd_att_avg_nz.screening_date, v_cinetam_movie_mix_wtd_att_avg_nz.country_code, cinetam_reporting_demographics_desc, film_screening_dates.attendance_period_no, attendance_year_end
having sum(no_prints) <> 0
union
select film_market.film_market_desc, v_cinetam_movie_mix_wtd_att_avg_nz.screening_date, v_cinetam_movie_mix_wtd_att_avg_nz.country_code, cinetam_reporting_demographics_desc, film_screening_dates.attendance_period_no, attendance_year_end, sum(attendance_sum) / sum(no_prints) as avg_attendance
from v_cinetam_movie_mix_wtd_att_avg_nz, cinetam_reporting_demographics, film_screening_dates, film_market
where	v_cinetam_movie_mix_wtd_att_avg_nz.cinetam_reporting_demographics_id = cinetam_reporting_demographics.cinetam_reporting_demographics_id
and film_screening_dates.screening_date = v_cinetam_movie_mix_wtd_att_avg_nz.screening_date
and film_screening_dates.attendance_period_no <> 53
and v_cinetam_movie_mix_wtd_att_avg_nz.film_market_no = film_market.film_market_no
and film_screening_dates.screening_date > '26-dec-2010'
group by film_market.film_market_desc, v_cinetam_movie_mix_wtd_att_avg_nz.screening_date, v_cinetam_movie_mix_wtd_att_avg_nz.country_code, cinetam_reporting_demographics_desc, film_screening_dates.attendance_period_no, attendance_year_end
having sum(no_prints) <> 0







GO
