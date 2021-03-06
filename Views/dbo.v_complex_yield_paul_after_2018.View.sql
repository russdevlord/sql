/****** Object:  View [dbo].[v_complex_yield_paul_after_2018]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_complex_yield_paul_after_2018]
GO
/****** Object:  View [dbo].[v_complex_yield_paul_after_2018]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[v_complex_yield_paul_after_2018]
AS
SELECT        movie_type, exhibitor_name, 
exhibitor_id, 
film_market_no, 
film_market_desc, 
complex_id, state_code, complex_region_class, complex_name, screening_date, premium_cinema, movie_id, movie_name, group_name, 
                         occurence, time_avail, time_avail_main_block_only, duration, 
						 
                         
                          attendance, release_date, benchmark_end, cal_year, cal_qtr, 
                         fin_year, fin_qtr, cal_half, fin_half, country_code, attendance * (duration / time_avail) as weekly_admit_util, attendance * time_avail as attendance_x_time_avail, attendance * duration as attendance_x_duration
FROM            dbo.complex_yield_paul
WHERE        (screening_date > '26-dec-2018')
GO
