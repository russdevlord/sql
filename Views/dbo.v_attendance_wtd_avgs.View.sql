/****** Object:  View [dbo].[v_attendance_wtd_avgs]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_attendance_wtd_avgs]
GO
/****** Object:  View [dbo].[v_attendance_wtd_avgs]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
create view [dbo].[v_attendance_wtd_avgs]
as
/* Metro */
select screening_date,
       (convert(numeric(18,6), sum(no_prints * attendance))) / convert(numeric(18,6), sum(no_prints)) as 'avg_attendance', "National With Kids" as attendance_type,
       sum(no_movies) as no_movies,
       country_code
from (select      count(mh.movie_id) as no_movies,
            mh.movie_id,mh.country as country_code,
            mh.complex_id,
			c.complex_name,
			fm.film_market_desc,
			fm.film_market_no,
            mh.screening_date,
            mh.attendance,
            c.complex_region_class,
            (select     count(certificate_item_id) 
             from       certificate_item, 
                        certificate_group,
                        movie_history
             where      spot_reference is not null 
             and        certificate_group.certificate_group_id = certificate_item.certificate_group
             and        movie_history.screening_date = mh.screening_date
             and        movie_history.complex_id = mh.complex_id
             and        movie_history.movie_id = mh.movie_id
             and        movie_history.certificate_group = certificate_group.certificate_group_id) as no_prints 
from        movie_history mh,
			complex c,
			film_market fm
where       mh.movie_id = mh.movie_id
and         mh.complex_id = mh.complex_id
and         mh.screening_date = mh.screening_date
--and         mh.screening_date between '20-dec-2006' and '2-aug-2012'
--and         country_code = 'A'
and         mh.certificate_group in (select distinct certificate_group from certificate_item where spot_reference is not null)
and			mh.complex_id = c.complex_id
and			c.film_market_no = fm.film_market_no
--and         c.complex_region_class = 'M'
group by    mh.movie_id,mh.country,
            mh.complex_id,
			c.complex_name,
			fm.film_market_desc,
			fm.film_market_no,
            mh.screening_date,
            mh.attendance,
            c.complex_region_class) as temp_table
            group by screening_Date, country_code
union all
/* Metro */
select screening_date,
       (convert(numeric(18,6), sum(no_prints * attendance))) / convert(numeric(18,6), sum(no_prints)) as 'avg_attendance', "Metro With Kids" as attendance_type,
       sum(no_movies) as no_movies,
       country_code
from (select      count(mh.movie_id) as no_movies,
            mh.movie_id,mh.country as country_code,
            mh.complex_id,
			c.complex_name,
			fm.film_market_desc,
			fm.film_market_no,
            mh.screening_date,
            mh.attendance,
            c.complex_region_class,
            (select     count(certificate_item_id) 
             from       certificate_item, 
                        certificate_group,
                        movie_history
             where      spot_reference is not null 
             and        certificate_group.certificate_group_id = certificate_item.certificate_group
             and        movie_history.screening_date = mh.screening_date
             and        movie_history.complex_id = mh.complex_id
             and        movie_history.movie_id = mh.movie_id
             and        movie_history.certificate_group = certificate_group.certificate_group_id) as no_prints 
from        movie_history mh,
			complex c,
			film_market fm
where       mh.movie_id = mh.movie_id
and         mh.complex_id = mh.complex_id
and         mh.screening_date = mh.screening_date
--and         mh.screening_date between '20-dec-2006' and '2-aug-2012'
--and         country_code = 'A'
and         mh.certificate_group in (select distinct certificate_group from certificate_item where spot_reference is not null)
and			mh.complex_id = c.complex_id
and			c.film_market_no = fm.film_market_no
and         c.complex_region_class = 'M'
group by    mh.movie_id,mh.country,
            mh.complex_id,
			c.complex_name,
			fm.film_market_desc,
			fm.film_market_no,
            mh.screening_date,
            mh.attendance,
            c.complex_region_class) as temp_table
            group by screening_Date, country_code
union all
/* Regional */
select screening_date,
       (convert(numeric(18,6), sum(no_prints * attendance))) / convert(numeric(18,6), sum(no_prints)) as 'avg_attendance', "Regional With Kids",
       sum(no_movies) as no_movies, country_code
from (select      count(mh.movie_id) as no_movies,
            mh.movie_id,mh.country as country_code,
            mh.complex_id,
			c.complex_name,
			fm.film_market_desc,
			fm.film_market_no,
            mh.screening_date,
            mh.attendance,
            c.complex_region_class,
            (select     count(certificate_item_id) 
             from       certificate_item, 
                        certificate_group,
                        movie_history
             where      spot_reference is not null 
             and        certificate_group.certificate_group_id = certificate_item.certificate_group
             and        movie_history.screening_date = mh.screening_date
             and        movie_history.complex_id = mh.complex_id
             and        movie_history.movie_id = mh.movie_id
             and        movie_history.certificate_group = certificate_group.certificate_group_id) as no_prints 
from        movie_history mh,
			complex c,
			film_market fm
where       mh.movie_id = mh.movie_id
and         mh.complex_id = mh.complex_id
and         mh.screening_date = mh.screening_date
--and         mh.screening_date between '20-dec-2006' and '2-aug-2012'
--and         country_code = 'A'
and         mh.certificate_group in (select distinct certificate_group from certificate_item where spot_reference is not null)
and			mh.complex_id = c.complex_id
and			c.film_market_no = fm.film_market_no
and         c.complex_region_class <> 'M'
group by    mh.movie_id,mh.country,
            mh.complex_id,
			c.complex_name,
			fm.film_market_desc,
			fm.film_market_no,
            mh.screening_date,
            mh.attendance,
            c.complex_region_class) as temp_table
            group by screening_Date,country_code
union all

/* Metro - No Kids*/
select screening_date,
       (convert(numeric(18,6), sum(no_prints * attendance))) / convert(numeric(18,6), sum(no_prints))as 'avg_attendance',  "National Without Kids",
       sum(no_movies) as no_movies,country_code
from (select      count(mh.movie_id) as no_movies,
            mh.movie_id,mh.country as country_code,
            mh.complex_id,
			c.complex_name,
			fm.film_market_desc,
			fm.film_market_no,
            mh.screening_date,
            mh.attendance,
            c.complex_region_class,
            (select     count(certificate_item_id) 
             from       certificate_item, 
                        certificate_group,
                        movie_history
             where      spot_reference is not null 
             and        certificate_group.certificate_group_id = certificate_item.certificate_group
             and        movie_history.screening_date = mh.screening_date
             and        movie_history.complex_id = mh.complex_id
             and        movie_history.movie_id = mh.movie_id
             and        movie_history.certificate_group = certificate_group.certificate_group_id) as no_prints 
from        movie_history mh,
			complex c,
			film_market fm
where       mh.movie_id = mh.movie_id
and         mh.complex_id = mh.complex_id
and         mh.screening_date = mh.screening_date
--and         mh.screening_date between '20-dec-2006' and '2-aug-2012'
--and         country_code = 'A'
and         mh.certificate_group in (select distinct certificate_group from certificate_item where spot_reference is not null)
and			mh.complex_id = c.complex_id
and			c.film_market_no = fm.film_market_no
--and         c.complex_region_class = 'M'
and         mh.movie_id in (select movie_id from movie_country where country_code = 'A' and classification_id not in (1,2))
group by    mh.movie_id,mh.country,
            mh.complex_id,
			c.complex_name,
			fm.film_market_desc,
			fm.film_market_no,
            mh.screening_date,
            mh.attendance,
            c.complex_region_class) as temp_table
            group by screening_Date,country_code
            union all
/* Metro - No Kids*/
select screening_date,
       (convert(numeric(18,6), sum(no_prints * attendance))) / convert(numeric(18,6), sum(no_prints))as 'avg_attendance',  "Metro Without Kids",
       sum(no_movies) as no_movies,country_code
from (select      count(mh.movie_id) as no_movies,
            mh.movie_id,mh.country as country_code,
            mh.complex_id,
			c.complex_name,
			fm.film_market_desc,
			fm.film_market_no,
            mh.screening_date,
            mh.attendance,
            c.complex_region_class,
            (select     count(certificate_item_id) 
             from       certificate_item, 
                        certificate_group,
                        movie_history
             where      spot_reference is not null 
             and        certificate_group.certificate_group_id = certificate_item.certificate_group
             and        movie_history.screening_date = mh.screening_date
             and        movie_history.complex_id = mh.complex_id
             and        movie_history.movie_id = mh.movie_id
             and        movie_history.certificate_group = certificate_group.certificate_group_id) as no_prints 
from        movie_history mh,
			complex c,
			film_market fm
where       mh.movie_id = mh.movie_id
and         mh.complex_id = mh.complex_id
and         mh.screening_date = mh.screening_date
--and         mh.screening_date between '20-dec-2006' and '2-aug-2012'
--and         country_code = 'A'
and         mh.certificate_group in (select distinct certificate_group from certificate_item where spot_reference is not null)
and			mh.complex_id = c.complex_id
and			c.film_market_no = fm.film_market_no
and         c.complex_region_class = 'M'
and         mh.movie_id in (select movie_id from movie_country where country_code = 'A' and classification_id not in (1,2))
group by    mh.movie_id,mh.country,
            mh.complex_id,
			c.complex_name,
			fm.film_market_desc,
			fm.film_market_no,
            mh.screening_date,
            mh.attendance,
            c.complex_region_class) as temp_table
            group by screening_Date,country_code
            union all
/* Regional - No Kids*/
select screening_date,
       (convert(numeric(18,6), sum(no_prints * attendance))) / convert(numeric(18,6), sum(no_prints)) as 'avg_attendance',  "Regional Without Kids",
       sum(no_movies) as no_movies, country_code
from (select      count(mh.movie_id) as no_movies,
            mh.movie_id,mh.country as country_code,
            mh.complex_id,
			c.complex_name,
			fm.film_market_desc,
			fm.film_market_no,
            mh.screening_date,
            mh.attendance,
            c.complex_region_class,
            (select     count(certificate_item_id) 
             from       certificate_item, 
                        certificate_group,
                        movie_history
             where      spot_reference is not null 
             and        certificate_group.certificate_group_id = certificate_item.certificate_group
             and        movie_history.screening_date = mh.screening_date
             and        movie_history.complex_id = mh.complex_id
             and        movie_history.movie_id = mh.movie_id
             and        movie_history.certificate_group = certificate_group.certificate_group_id) as no_prints 
from        movie_history mh,
			complex c,
			film_market fm
where       mh.movie_id = mh.movie_id
and         mh.complex_id = mh.complex_id
and         mh.screening_date = mh.screening_date
--and         mh.screening_date between '20-dec-2006' and '2-aug-2012'
--and         country_code = 'A'
and         mh.certificate_group in (select distinct certificate_group from certificate_item where spot_reference is not null)
and			mh.complex_id = c.complex_id
and			c.film_market_no = fm.film_market_no
and         c.complex_region_class <> 'M'
and         mh.movie_id in (select movie_id from movie_country where country_code = 'A' and classification_id not in (1,2))
group by    mh.movie_id,mh.country,
            mh.complex_id,
			c.complex_name,
			fm.film_market_desc,
			fm.film_market_no,
            mh.screening_date,
            mh.attendance,
            c.complex_region_class) as temp_table
            group by screening_Date,country_code
           union all

/* Metro - Kids*/
select screening_date,
       (convert(numeric(18,6), sum(no_prints * attendance))) / convert(numeric(18,6), sum(no_prints)) as 'avg_attendance',  "Metro Only Kids",
       sum(no_movies) as no_movies, country_code
from (select      count(mh.movie_id) as no_movies,
            mh.movie_id,mh.country as country_code,
            mh.complex_id,
			c.complex_name,
			fm.film_market_desc,
			fm.film_market_no,
            mh.screening_date,
            mh.attendance,
            c.complex_region_class,
            (select     count(certificate_item_id) 
             from       certificate_item, 
                        certificate_group,
                        movie_history
             where      spot_reference is not null 
             and        certificate_group.certificate_group_id = certificate_item.certificate_group
             and        movie_history.screening_date = mh.screening_date
             and        movie_history.complex_id = mh.complex_id
             and        movie_history.movie_id = mh.movie_id
             and        movie_history.certificate_group = certificate_group.certificate_group_id) as no_prints 
from        movie_history mh,
			complex c,
			film_market fm
where       mh.movie_id = mh.movie_id
and         mh.complex_id = mh.complex_id
and         mh.screening_date = mh.screening_date
--and         mh.screening_date between '20-dec-2006' and '2-aug-2012'
--and         country_code = 'A'
and         mh.certificate_group in (select distinct certificate_group from certificate_item where spot_reference is not null)
and			mh.complex_id = c.complex_id
and			c.film_market_no = fm.film_market_no
and         c.complex_region_class = 'M'
and         mh.movie_id in (select movie_id from movie_country where country_code = 'A' and classification_id in (1,2))
group by    mh.movie_id,mh.country,
            mh.complex_id,
			c.complex_name,
			fm.film_market_desc,
			fm.film_market_no,
            mh.screening_date,
            mh.attendance,
            c.complex_region_class) as temp_table
            group by screening_Date, country_code
           union all

/* Regional - Kids*/
select screening_date,
       (convert(numeric(18,6), sum(no_prints * attendance))) / convert(numeric(18,6), sum(no_prints)) as 'avg_attendance',  "Regional Only Kids",
       sum(no_movies) as no_movies,country_code
from (select      count(mh.movie_id) as no_movies,
            mh.movie_id,mh.country as country_code,
            mh.complex_id,
			c.complex_name,
			fm.film_market_desc,
			fm.film_market_no,
            mh.screening_date,
            mh.attendance,
            c.complex_region_class,
            (select     count(certificate_item_id) 
             from       certificate_item, 
                        certificate_group,
                        movie_history
             where      spot_reference is not null 
             and        certificate_group.certificate_group_id = certificate_item.certificate_group
             and        movie_history.screening_date = mh.screening_date
             and        movie_history.complex_id = mh.complex_id
             and        movie_history.movie_id = mh.movie_id
             and        movie_history.certificate_group = certificate_group.certificate_group_id) as no_prints 
from        movie_history mh,
			complex c,
			film_market fm
where       mh.movie_id = mh.movie_id
and         mh.complex_id = mh.complex_id
and         mh.screening_date = mh.screening_date
--and         mh.screening_date between '20-dec-2006' and '2-aug-2012'
--and         country_code = 'A'
and         mh.certificate_group in (select distinct certificate_group from certificate_item where spot_reference is not null)
and			mh.complex_id = c.complex_id
and			c.film_market_no = fm.film_market_no
and         c.complex_region_class <> 'M'
and         mh.movie_id in (select movie_id from movie_country where country_code = 'A' and classification_id in (1,2))
group by    mh.movie_id,mh.country,
            mh.complex_id,
			c.complex_name,
			fm.film_market_desc,
			fm.film_market_no,
            mh.screening_date,
            mh.attendance,
            c.complex_region_class) as temp_table
            group by screening_Date, country_code
                         
GO
