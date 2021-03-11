USE [production]
GO
/****** Object:  StoredProcedure [dbo].[p_cinetam_live_extract_movie_category_xref]    Script Date: 11/03/2021 2:30:33 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create proc [dbo].[p_cinetam_live_extract_movie_category_xref]

as

declare			@error			int

set nocount on

select			target_categories.movie_id,
				target_categories.movie_category_code
from			target_categories
left outer join cinetam_live_movie_category_xref on target_categories.movie_id = cinetam_live_movie_category_xref.movie_id
and				target_categories.movie_category_code = cinetam_live_movie_category_xref.movie_category_code
where			isnull(added, 'N') <> 'Y'
and				target_categories.movie_id in (select movie_id from movie_history where screening_date > '27-dec-2017' and country = 'A')


select @error = @@error
if @error <> 0
begin
	raiserror ('Error: failed to produce demographics xref list for cinetam live bigquery datawarehouse', 16, 1)
	return -1
end

begin transaction

insert into		cinetam_live_movie_category_xref
select			target_categories.movie_category_code,
				target_categories.movie_id,
				'Y',
				'N'
from			target_categories
left outer join cinetam_live_movie_category_xref on target_categories.movie_id = cinetam_live_movie_category_xref.movie_id
and				target_categories.movie_category_code = cinetam_live_movie_category_xref.movie_category_code
where			isnull(added, 'N') <> 'Y'
and				target_categories.movie_id in (select movie_id from movie_history where screening_date > '27-dec-2017' and country = 'A')

select @error = @@error
if @error <> 0
begin
	raiserror ('Error: failed to produce demographics xref list for cinetam live bigquery datawarehouse', 16, 1)
	rollback transaction
	return -1
end

commit transaction
return 0
GO
