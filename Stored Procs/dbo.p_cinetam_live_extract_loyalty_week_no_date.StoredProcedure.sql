/****** Object:  StoredProcedure [dbo].[p_cinetam_live_extract_loyalty_week_no_date]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cinetam_live_extract_loyalty_week_no_date]
GO
/****** Object:  StoredProcedure [dbo].[p_cinetam_live_extract_loyalty_week_no_date]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



create proc [dbo].[p_cinetam_live_extract_loyalty_week_no_date]

as

declare			@error			int

set nocount on

select			HASHBYTES('SHA2_256', convert(nvarchar(100), movio_data.membership_id)) as memberid, 
				movie_id,
				complex_id,
				session_time,
				film_screening_dates.screening_date,
				cinetam_demographics_id
from			movio_data
inner join		film_screening_dates on movio_data.session_time between film_screening_dates.screening_date and dateadd(ss, -1, dateadd(wk, 1, film_screening_dates.screening_date))
inner join		data_translate_movie on movio_data.movie_code = data_translate_movie.movie_code
inner join		(select			distinct complex_id, 
								loyalty_complex_name as complex_name 
				from			cinetam_live_complex_loyalty_translation 
				where			country_code = 'A') as translate_complex on movio_data.complex_name = translate_complex.complex_name
inner join		cinetam_demographics on UPPER(LEFT(movio_data.gender, 1)) = UPPER(cinetam_demographics.gender)
and				real_age between cinetam_demographics.min_age and cinetam_demographics.max_age
where			data_translate_movie.data_provider_id = 1
and				movio_data.country_code = 'A'
and				film_screening_dates.screening_date >= '27-dec-2017'
and				film_screening_dates.screening_date not in (	select			screening_date
																from			cinetam_live_loyalty
																where			added = 'Y')
and				film_screening_dates.attendance_status = 'X'
--for json path

select @error = @@error
if @error <> 0
begin
	raiserror ('Error: failed to produce complex list for cinetam live bigquery datawarehouse', 16, 1)
	return -1
end

begin transaction

insert into		cinetam_live_loyalty
select			distinct film_screening_dates.screening_date,
				'Y',
				'N'
from			movio_data
inner join		film_screening_dates on movio_data.session_time between film_screening_dates.screening_date and dateadd(ss, -1, dateadd(wk, 1, film_screening_dates.screening_date))
inner join		data_translate_movie on movio_data.movie_code = data_translate_movie.movie_code
inner join		(select			distinct complex_id, 
								loyalty_complex_name as complex_name 
				from			cinetam_live_complex_loyalty_translation 
				where			country_code = 'A') as translate_complex on movio_data.complex_name = translate_complex.complex_name
inner join		cinetam_demographics on UPPER(LEFT(movio_data.gender, 1)) = UPPER(cinetam_demographics.gender)
and				real_age between cinetam_demographics.min_age and cinetam_demographics.max_age
where			data_translate_movie.data_provider_id = 1
and				movio_data.country_code = 'A'
and				film_screening_dates.screening_date >= '27-dec-2017'
and				film_screening_dates.screening_date not in (	select			screening_date
																from			cinetam_live_loyalty
																where			added = 'Y')
and				film_screening_dates.attendance_status = 'X'

select @error = @@error
if @error <> 0
begin
	raiserror ('Error: failed to produce complex list for cinetam live bigquery datawarehouse', 16, 1)
	rollback transaction
	return -1
end

commit transaction
return 0
GO
