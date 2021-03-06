/****** Object:  StoredProcedure [dbo].[p_cinetam_live_extract_movie]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cinetam_live_extract_movie]
GO
/****** Object:  StoredProcedure [dbo].[p_cinetam_live_extract_movie]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create proc [dbo].[p_cinetam_live_extract_movie]

as

declare			@error			int

set nocount on

select			movie.movie_id,
				long_name ,
				release_date,
				movie_country.classification_id
from			movie
inner join		movie_country on movie.movie_id = movie_country.movie_id
where			movie_country.country_code = 'A'
and				movie.movie_id in (select movie_id from movie_history where screening_date > '27-dec-2017' and country = 'A')
and				movie.movie_id not in (select movie_id from cinetam_live_movie where added = 'Y')
group by		movie.movie_id,
				long_name ,
				release_date,
				movie_country.classification_id
--for json path

select @error = @@error
if @error <> 0
begin
	raiserror ('Error: failed to produce film screening_date list for cinetam live bigquery datawarehouse', 16, 1)
	return -1
end

begin transaction

insert into		cinetam_live_movie
select			movie.movie_id,
				'Y',
				'N'
from			movie
inner join		movie_country on movie.movie_id = movie_country.movie_id
where			movie_country.country_code = 'A'
and				movie.movie_id in (select movie_id from movie_history where screening_date > '27-dec-2017' and country = 'A')
and				movie.movie_id not in (select movie_id from cinetam_live_movie where added = 'Y')
group by		movie.movie_id,
				long_name ,
				release_date,
				movie_country.classification_id

select @error = @@error
if @error <> 0
begin
	raiserror ('Error: failed to produce movie list for cinetam live bigquery datawarehouse', 16, 1)
	rollback transaction
	return -1
end

commit transaction
return 0
GO
