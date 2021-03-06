/****** Object:  StoredProcedure [dbo].[p_cinetam_live_extract_movie_translation]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cinetam_live_extract_movie_translation]
GO
/****** Object:  StoredProcedure [dbo].[p_cinetam_live_extract_movie_translation]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create proc [dbo].[p_cinetam_live_extract_movie_translation]

as

declare			@error			int

set nocount on

select			data_translate_movie.movie_id,
				data_translate_movie.movie_code,
				data_translate_movie.data_provider_id
from			data_translate_movie
inner join		movie_country on data_translate_movie.movie_id = movie_country.movie_id
left outer join	cinetam_live_data_translate_movie on data_translate_movie.movie_id =  cinetam_live_data_translate_movie.movie_id
and				data_translate_movie.movie_code =  cinetam_live_data_translate_movie.movie_code
and				data_translate_movie.data_provider_id =  cinetam_live_data_translate_movie.data_provider_id
where			movie_country.country_code = 'A'
and				data_translate_movie.movie_id in (select movie_id from movie_history where screening_date > '27-dec-2017' and country = 'A')
and				isnull(added, 'N') <> 'Y'
and				data_translate_movie.data_provider_id = 1
group by		data_translate_movie.movie_id,
				data_translate_movie.movie_code,
				data_translate_movie.data_provider_id

select @error = @@error
if @error <> 0
begin
	raiserror ('Error: failed to produce film movie data translate list for cinetam live bigquery datawarehouse', 16, 1)
	return -1
end

begin transaction

insert into		cinetam_live_data_translate_movie
select			data_translate_movie.movie_id,
				data_translate_movie.data_provider_id,
				data_translate_movie.movie_code,
				'Y',
				'N'
from			data_translate_movie
inner join		movie_country on data_translate_movie.movie_id = movie_country.movie_id
left outer join	cinetam_live_data_translate_movie on data_translate_movie.movie_id =  cinetam_live_data_translate_movie.movie_id
and				data_translate_movie.movie_code =  cinetam_live_data_translate_movie.movie_code
and				data_translate_movie.data_provider_id =  cinetam_live_data_translate_movie.data_provider_id
where			movie_country.country_code = 'A'
and				data_translate_movie.movie_id in (select movie_id from movie_history where screening_date > '27-dec-2017' and country = 'A')
and				isnull(added, 'N') <> 'Y'
and				data_translate_movie.data_provider_id = 1
group by		data_translate_movie.movie_id,
				data_translate_movie.movie_code,
				data_translate_movie.data_provider_id

select @error = @@error
if @error <> 0
begin
	raiserror ('Error: failed to produce movie data translate list for cinetam live bigquery datawarehouse', 16, 1)
	rollback transaction
	return -1
end

commit transaction
return 0
GO
