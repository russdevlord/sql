/****** Object:  View [dbo].[v_movie_programming_digital]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP VIEW [dbo].[v_movie_programming_digital]
GO
/****** Object:  View [dbo].[v_movie_programming_digital]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

create view [dbo].[v_movie_programming_digital]
as 
select screening_date, complex_id, film, jpeg, total, case total when jpeg then 'Y' else 'N' end as fully_digital
from (select screening_date, complex_id, sum(film_count) as film, sum(digital_count) as jpeg, sum(film_count) + sum(digital_count) as total
from (select complex_id, screening_date,  case print_medium  when 'F' then 1 else 0 end as film_count, case print_medium  when 'D' then 1 else 0 end as digital_count from movie_history 
where country = 'A'
and screening_date > '1-dec-2008') as temp_table
group by complex_id, screening_date) as temp_table_two
GO
