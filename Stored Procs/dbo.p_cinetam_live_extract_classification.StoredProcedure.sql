/****** Object:  StoredProcedure [dbo].[p_cinetam_live_extract_classification]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cinetam_live_extract_classification]
GO
/****** Object:  StoredProcedure [dbo].[p_cinetam_live_extract_classification]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create proc [dbo].[p_cinetam_live_extract_classification]

as

declare			@error			int

set nocount on

select			classification_id,
				classification_code,
				classification_desc,
				country_code,
				sequence_no,
				ma_15_above
from			classification
where			classification_id not in (select classification_id from cinetam_live_classification where added = 'Y')
--for json path

select @error = @@error
if @error <> 0
begin
	raiserror ('Error: failed to produce film classification list for cinetam live bigquery datawarehouse', 16, 1)
	return -1
end

begin transaction

insert into		cinetam_live_classification
select			classification_id,
				'Y',
				'N'
from			classification
where			classification_id not in (select classification_id from cinetam_live_classification where added = 'Y')

select @error = @@error
if @error <> 0
begin
	raiserror ('Error: failed to produce classification list for cinetam live bigquery datawarehouse', 16, 1)
	rollback transaction
	return -1
end

commit transaction
return 0
GO
