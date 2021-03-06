/****** Object:  StoredProcedure [dbo].[p_cinetam_live_extract_demographics]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cinetam_live_extract_demographics]
GO
/****** Object:  StoredProcedure [dbo].[p_cinetam_live_extract_demographics]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create proc [dbo].[p_cinetam_live_extract_demographics]

as

declare			@error			int

set nocount on

select			cinetam_demographics_id,
				cinetam_demographics_desc,
				gender,
				min_age,
				max_age,
				movio_gender
from			cinetam_demographics
where			cinetam_demographics_id not in (select cinetam_demographics_id from cinetam_live_demographics where added = 'Y')
union
select			0,
				'Under 13',
				'N',
				0,
				13,
				'None'
where			0 not in (select cinetam_demographics_id from cinetam_live_demographics where added = 'Y')
--for json path

select @error = @@error
if @error <> 0
begin
	raiserror ('Error: failed to produce film demographics list for cinetam live bigquery datawarehouse', 16, 1)
	return -1
end

begin transaction

insert into		cinetam_live_demographics
select			cinetam_demographics_id,
				'Y',
				'N'
from			cinetam_demographics
where			cinetam_demographics_id not in (select cinetam_demographics_id from cinetam_live_demographics where added = 'Y')
union
select			0,
				'Y',
				'N'
where			0 not in (select cinetam_demographics_id from cinetam_live_demographics where added = 'Y')

select @error = @@error
if @error <> 0
begin
	raiserror ('Error: failed to produce demographics list for cinetam live bigquery datawarehouse', 16, 1)
	rollback transaction
	return -1
end

commit transaction
return 0
GO
