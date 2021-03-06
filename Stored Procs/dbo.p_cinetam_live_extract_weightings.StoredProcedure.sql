/****** Object:  StoredProcedure [dbo].[p_cinetam_live_extract_weightings]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cinetam_live_extract_weightings]
GO
/****** Object:  StoredProcedure [dbo].[p_cinetam_live_extract_weightings]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


create proc [dbo].[p_cinetam_live_extract_weightings]

as

declare			@error			int

set nocount on

select			cinetam_weightings.screening_date, 
				cinetam_weightings.cinetam_demographics_id,
				country_code,
				weighting,
				min_age,
				max_age,
				movio_gender
from			cinetam_weightings
inner join		cinetam_demographics on cinetam_weightings.cinetam_demographics_id = cinetam_demographics.cinetam_demographics_id
inner join		film_screening_dates on cinetam_weightings.screening_date = film_screening_dates.screening_date
where			film_screening_dates.screening_date >= '27-dec-2017'
and				film_screening_dates.screening_date not in (	select			screening_date
																from			cinetam_live_weightings
																where			added = 'Y')
and				weekend_attendance_status = 'X'
and				country_code = 'A'
union
select			screening_date, 
				0,
				'A',
				1.0,
				0,
				13,
				'None'
from			film_screening_dates
where			film_screening_dates.screening_date >= '27-dec-2017'
and				film_screening_dates.screening_date not in (	select			screening_date
																from			cinetam_live_weightings
																where			added = 'Y')
and				weekend_attendance_status = 'X'
--for json path

select @error = @@error
if @error <> 0
begin
	raiserror ('Error: failed to produce film demographics list for cinetam live bigquery datawarehouse', 16, 1)
	return -1
end

begin transaction

insert into		cinetam_live_weightings
select			distinct cinetam_weightings.screening_date, 
				'Y',
				'N'
from			cinetam_weightings
inner join		cinetam_demographics on cinetam_weightings.cinetam_demographics_id = cinetam_demographics.cinetam_demographics_id
inner join		film_screening_dates on cinetam_weightings.screening_date = film_screening_dates.screening_date
where			film_screening_dates.screening_date >= '27-dec-2017'
and				film_screening_dates.screening_date not in (	select			screening_date
																from			cinetam_live_weightings
																where			added = 'Y')
and				weekend_attendance_status = 'X'
and				country_code = 'A'
group by		cinetam_weightings.screening_date

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
