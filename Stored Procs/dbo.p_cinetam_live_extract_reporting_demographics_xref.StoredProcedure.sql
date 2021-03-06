/****** Object:  StoredProcedure [dbo].[p_cinetam_live_extract_reporting_demographics_xref]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cinetam_live_extract_reporting_demographics_xref]
GO
/****** Object:  StoredProcedure [dbo].[p_cinetam_live_extract_reporting_demographics_xref]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create proc [dbo].[p_cinetam_live_extract_reporting_demographics_xref]

as

declare			@error			int

set nocount on

select			cinetam_reporting_demographics_xref.cinetam_reporting_demographics_id,
				cinetam_reporting_demographics_xref.cinetam_demographics_id
from			cinetam_reporting_demographics_xref
left outer join cinetam_live_reporting_demo_xref on cinetam_reporting_demographics_xref.cinetam_demographics_id = cinetam_live_reporting_demo_xref.cinetam_demographics_id
and				cinetam_reporting_demographics_xref.cinetam_reporting_demographics_id = cinetam_live_reporting_demo_xref.cinetam_reporting_demographics_id
where			isnull(added, 'N') <> 'Y'
union
select			temp_table.cinetam_reporting_demographics_id,
				temp_table.cinetam_demographics_id
from			(select			0 as cinetam_demographics_id,
								0 as cinetam_reporting_demographics_id) as temp_table
left outer join cinetam_live_reporting_demo_xref on temp_table.cinetam_demographics_id = cinetam_live_reporting_demo_xref.cinetam_demographics_id
and				temp_table.cinetam_reporting_demographics_id = cinetam_live_reporting_demo_xref.cinetam_reporting_demographics_id
where			isnull(added, 'N') <> 'Y'
--for json path

select @error = @@error
if @error <> 0
begin
	raiserror ('Error: failed to produce demographics xref list for cinetam live bigquery datawarehouse', 16, 1)
	return -1
end

begin transaction

insert into		cinetam_live_reporting_demo_xref
select			cinetam_reporting_demographics_xref.cinetam_reporting_demographics_id,
				cinetam_reporting_demographics_xref.cinetam_demographics_id,
				'Y',
				'N'
from			cinetam_reporting_demographics_xref
left outer join cinetam_live_reporting_demo_xref on cinetam_reporting_demographics_xref.cinetam_demographics_id = cinetam_live_reporting_demo_xref.cinetam_demographics_id
and				cinetam_reporting_demographics_xref.cinetam_reporting_demographics_id = cinetam_live_reporting_demo_xref.cinetam_reporting_demographics_id
where			isnull(added, 'N') <> 'Y'
union
select			temp_table.cinetam_reporting_demographics_id,
				temp_table.cinetam_demographics_id,
				'Y',
				'N'
from			(select			0 as cinetam_demographics_id,
								0 as cinetam_reporting_demographics_id) as temp_table
left outer join cinetam_live_reporting_demo_xref on temp_table.cinetam_demographics_id = cinetam_live_reporting_demo_xref.cinetam_demographics_id
and				temp_table.cinetam_reporting_demographics_id = cinetam_live_reporting_demo_xref.cinetam_reporting_demographics_id
where			isnull(added, 'N') <> 'Y'

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
