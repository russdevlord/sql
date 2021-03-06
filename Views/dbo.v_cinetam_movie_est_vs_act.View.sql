/****** Object:  View [dbo].[v_cinetam_movie_est_vs_act]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_cinetam_movie_est_vs_act]
GO
/****** Object:  View [dbo].[v_cinetam_movie_est_vs_act]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO




CREATE view [dbo].[v_cinetam_movie_est_vs_act]
as

select  'Estimates' as type,screening_date, cinetam_reporting_demographics_desc,long_name, sum(attendance) / count(*) as avg_att_per_print
 , count(*) as no_prints, country_code , movie.movie_id
from cinetam_movie_complex_estimates, movie, cinetam_reporting_demographics, complex, branch
where movie.movie_id  = cinetam_movie_complex_estimates.movie_id 
and cinetam_movie_complex_estimates.cinetam_reporting_demographics_id = cinetam_reporting_demographics.cinetam_reporting_demographics_id
and cinetam_movie_complex_estimates.complex_id = complex.complex_id
and complex.branch_code = branch.branch_code
group by  country_code,screening_date, cinetam_reporting_demographics_desc,long_name, movie.movie_id
having sum(attendance) <> 0
union
select 'Actuals',screening_date, cinetam_reporting_demographics_desc,long_name, sum(attendance) / count(*) as avg_att_per_print
, count(*) as no_prints , country as country_code, v_cinetam_movie_history_reporting_demos.movie_id
from v_cinetam_movie_history_reporting_demos 
group by country,screening_date, cinetam_reporting_demographics_desc,long_name, v_cinetam_movie_history_reporting_demos.movie_id
having sum(attendance) <> 0



GO
