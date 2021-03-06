/****** Object:  StoredProcedure [dbo].[p_cinetam_live_extract_loyalty]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cinetam_live_extract_loyalty]
GO
/****** Object:  StoredProcedure [dbo].[p_cinetam_live_extract_loyalty]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create proc [dbo].[p_cinetam_live_extract_loyalty]

as

declare			@error			int

set nocount on

select			movie_history.screening_date,
				movie_history.movie_id,
				complex.complex_id,
				complex_name,
				complex.film_market_no,
				film_market_desc,
				regional_indicator,
				complex.complex_region_class,
				complex_region_class.region_class_desc,
				complex.exhibitor_id,
				exhibitor_name,
				no_cinemas,
				case complex_type when 'M' then 'Mainstream' when 'A' then 'Arthouse' else 'Unknown' end as complex_type_desc,
				attendance_status,
				complex_type,
				long_name ,
				release_date,
				classification.classification_desc, 
				country
from			movie_history
inner join		film_screening_dates on movie_history.screening_date = film_screening_dates.screening_date
inner join		complex on movie_history.complex_id = complex.complex_id
inner join		film_market on complex.film_market_no = film_market.film_market_no
inner join		complex_region_class on complex.complex_region_class = complex_region_class.complex_region_class
inner join		exhibitor on complex.exhibitor_id = exhibitor.exhibitor_id
inner join		movie on movie_history.movie_id = movie.movie_id 
inner join		movie_country on movie.movie_id = movie_country.movie_id and movie_history.country = movie_country.country_code and movie_history.movie_id = movie_country.movie_id
inner join		classification on movie_country.classification_id = classification.classification_id
where			movie_history.country = 'A'
and				movie_history.screening_date > '27-dec-2017'
and				movie_history.screening_date not in (	select			screening_date
																from			cinetam_live_movie_history
																where			added = 'Y')
and				film_screening_dates.attendance_status = 'X'
group by		movie_history.screening_date,
				movie_history.movie_id,
				complex.complex_id,
				complex_name,
				complex.film_market_no,
				film_market_desc,
				regional_indicator,
				complex.complex_region_class,
				complex_region_class.region_class_desc,
				complex.exhibitor_id,
				exhibitor_name,
				no_cinemas,
				case complex_type when 'M' then 'Mainstream' when 'A' then 'Arthouse' else 'Unknown' end,
				attendance_status,
				complex_type,
				long_name ,
				release_date,
				classification.classification_desc, 
				country


select @error = @@error
if @error <> 0
begin
	raiserror 50050 'Error: failed to produce complex list for cinetam live bigquery datawarehouse'
	return -1
end

begin transaction

insert into		cinetam_live_movie_history
select			distinct movie_history.screening_date,
				'Y',
				'N'
from			movie_history
inner join		film_screening_dates on movie_history.screening_date = film_screening_dates.screening_date
inner join		complex on movie_history.complex_id = complex.complex_id
inner join		film_market on complex.film_market_no = film_market.film_market_no
inner join		complex_region_class on complex.complex_region_class = complex_region_class.complex_region_class
inner join		exhibitor on complex.exhibitor_id = exhibitor.exhibitor_id
inner join		movie on movie_history.movie_id = movie.movie_id 
inner join		movie_country on movie.movie_id = movie_country.movie_id and movie_history.country = movie_country.country_code and movie_history.movie_id = movie_country.movie_id
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
	raiserror 50050 'Error: failed to produce complex list for cinetam live bigquery datawarehouse'
	rollback transaction
	return -1
end

commit transaction
return 0
GO
