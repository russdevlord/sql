/****** Object:  StoredProcedure [dbo].[p_cinetam_live_extract_movie_category]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cinetam_live_extract_movie_category]
GO
/****** Object:  StoredProcedure [dbo].[p_cinetam_live_extract_movie_category]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create proc [dbo].[p_cinetam_live_extract_movie_category]

as

declare			@error			int

set nocount on

select			movie_category_code,
				movie_category_desc
from			movie_category
where			movie_category_code not in (select movie_category_code from cinetam_live_category where added = 'Y')
--for json path

select @error = @@error
if @error <> 0
begin
	raiserror ('Error: failed to produce complex list for cinetam live bigquery datawarehouse', 16, 1)
	return -1
end

begin transaction

insert into		cinetam_live_category
select			movie_category_code,
				'Y',
				'N'
from			movie_category
where			movie_category_code not in (select movie_category_code from cinetam_live_category where added = 'Y')

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
