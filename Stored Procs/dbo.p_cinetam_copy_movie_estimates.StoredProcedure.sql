USE [production]
GO
/****** Object:  StoredProcedure [dbo].[p_cinetam_copy_movie_estimates]    Script Date: 11/03/2021 2:30:33 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create	proc [dbo].[p_cinetam_copy_movie_estimates]	@movie_id			int,
											@source_movie		int,
											@country_code		char(1)

as 

declare			@error			int

set nocount on

begin transaction

insert into		cinetam_movie_complex_estimates 
select			@movie_id,
				cinetam_reporting_demographics_id,
				screening_date,
				complex_id,
				attendance,
				original_estimate
from			cinetam_movie_complex_estimates 
where			movie_id = @source_movie
and				complex_id in (	select			complex_id 
								from			complex 
								inner join		branch on complex.branch_code = branch.branch_code
								where			country_code = @country_code)

select @error = @@error
if @error <> 0
begin
	rollback transaction
	raiserror('Error moving movie estimates', 16, 1)
	return -1
end

commit transaction
return 0
GO
