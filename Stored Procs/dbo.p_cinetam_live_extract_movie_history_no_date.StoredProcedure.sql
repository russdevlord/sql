/****** Object:  StoredProcedure [dbo].[p_cinetam_live_extract_movie_history_no_date]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cinetam_live_extract_movie_history_no_date]
GO
/****** Object:  StoredProcedure [dbo].[p_cinetam_live_extract_movie_history_no_date]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create proc [dbo].[p_cinetam_live_extract_movie_history_no_date]
 
as

declare			@error			int

set nocount on

select			movie_history.screening_date,
				movie_history.movie_id,
				movie_history.complex_id,
				country as country_code,
				0 as cinetam_demographics_id,
				sum(attendance) as attendance
from			movie_history
inner join		film_screening_dates on movie_history.screening_date = film_screening_dates.screening_date
inner join		movie_country on movie_history.movie_id = movie_country.movie_id and movie_history.country = movie_country.country_code 
inner join		classification on movie_country.classification_id = classification.classification_id
where			movie_history.country = 'A'
and				movie_history.screening_date > '27-dec-2017'
and				movie_history.screening_date not in (	select			screening_date
																from			cinetam_live_movie_history
																where			added = 'Y')
and				film_screening_dates.attendance_status = 'X'
group by		movie_history.screening_date,
				movie_history.movie_id,
				movie_history.complex_id,
				country
union all
select			cinetam_movie_history.screening_date,
				cinetam_movie_history.movie_id,
				cinetam_movie_history.complex_id,
				cinetam_movie_history.country_code as country_code,
				cinetam_demographics_id,
				sum(attendance) as attendance
from			cinetam_movie_history
inner join		film_screening_dates on cinetam_movie_history.screening_date = film_screening_dates.screening_date
inner join		movie_country on cinetam_movie_history.movie_id = movie_country.movie_id and cinetam_movie_history.country_code = movie_country.country_code
inner join		classification on movie_country.classification_id = classification.classification_id
where			cinetam_movie_history.country_code = 'A'
and				cinetam_movie_history.screening_date > '27-dec-2017'
and				cinetam_movie_history.screening_date not in (	select			screening_date
																from			cinetam_live_movie_history
																where			added = 'Y')
and				film_screening_dates.attendance_status = 'X'
group by		cinetam_movie_history.screening_date,
				cinetam_movie_history.movie_id,
				cinetam_movie_history.complex_id,
				cinetam_movie_history.country_code,
				cinetam_demographics_id
--for json path

select @error = @@error
if @error <> 0
begin
	raiserror ('Error: failed to produce complex list for cinetam live bigquery datawarehouse', 16, 1)
	return -1
end

begin transaction

insert into		cinetam_live_movie_history
select			movie_history.screening_date,
				'Y',
				'N'
from			movie_history
inner join		film_screening_dates on movie_history.screening_date = film_screening_dates.screening_date
inner join		movie_country on movie_history.movie_id = movie_country.movie_id and movie_history.country = movie_country.country_code 
inner join		classification on movie_country.classification_id = classification.classification_id
where			movie_history.country = 'A'
and				movie_history.screening_date > '27-dec-2017'
and				movie_history.screening_date not in (	select			screening_date
																from			cinetam_live_movie_history
																where			added = 'Y')
and				film_screening_dates.attendance_status = 'X'
group by		movie_history.screening_date

select @error = @@error
if @error <> 0
begin
	raiserror ('Error: failed to produce complex list for cinetam live bigquery datawarehouse', 16, 1)
	rollback transaction
	return -1
end

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
