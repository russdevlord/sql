/****** Object:  StoredProcedure [dbo].[p_cinetam_fill_holes_cplx_date_sett]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cinetam_fill_holes_cplx_date_sett]
GO
/****** Object:  StoredProcedure [dbo].[p_cinetam_fill_holes_cplx_date_sett]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




create proc [dbo].[p_cinetam_fill_holes_cplx_date_sett]

as

declare			@error									int,
				@complex_id								int,
				@previous_date							datetime,
				@missing_date							datetime,
				@current_date							datetime,
				@cinetam_reporting_demographics_id		int

set nocount on

select			@current_date = screening_date
from			film_screening_dates
where			screening_date_status = 'C'

begin transaction

declare			complex_date_csr cursor for
select			complex_id, 
				screening_date,
				cinetam_reporting_demographics_id
from			(select			complex.complex_id,
								film_screening_dates.screening_date,
								cinetam_reporting_demographics.cinetam_reporting_demographics_id,
								(select			count(*)
								from			cinetam_complex_date_settings
								where			complex_id = complex.complex_id
								and				screening_date = film_screening_dates.screening_date
								and				cinetam_reporting_demographics_id = cinetam_reporting_demographics.cinetam_reporting_demographics_id) as no_records
				from			complex
				cross join		film_screening_dates
				cross join		cinetam_reporting_demographics
				where			film_screening_dates.screening_date between dateadd(wk, -105, @current_date) and dateadd(wk, 51, @current_date)
				and				film_complex_status <> 'C'
				group by		complex.complex_id,
								film_screening_dates.screening_date,
								cinetam_reporting_demographics.cinetam_reporting_demographics_id) as temp_table
where			no_records = 0
order by		complex_id,
				screening_date,
				cinetam_reporting_demographics_id
for				read only

open complex_date_csr
fetch complex_date_csr into @complex_id, @missing_date, @cinetam_reporting_demographics_id
while (@@fetch_status = 0)
begin

	select			@previous_date = max(screening_date)
	from			cinetam_complex_date_settings
	where			complex_id = @complex_id
	and				screening_date < @missing_date
	and				cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id

	select @error = @@error
	if @error <> 0 
	begin
		raiserror ('Error finding week to copy', 16, 1)
		rollback transaction
		return -1
	end

	insert into cinetam_complex_date_settings
	select			complex_id, 
					@missing_date,
					cinetam_reporting_demographics_id,
					percent_market,
					priority_level, 
					spot_min_no,
					spot_max_no
	from			cinetam_complex_date_settings
	where			complex_id = @complex_id
	and				screening_date = @previous_date
	and				cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id

	select @error = @@error
	if @error <> 0 
	begin
		raiserror ('Error inserting new data', 16, 1)
		rollback transaction
		return -1
	end

	fetch complex_date_csr into @complex_id, @missing_date, @cinetam_reporting_demographics_id
end


commit transaction
return 0
GO
