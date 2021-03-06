/****** Object:  StoredProcedure [dbo].[p_cinetam_move_movie_estimates]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cinetam_move_movie_estimates]
GO
/****** Object:  StoredProcedure [dbo].[p_cinetam_move_movie_estimates]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create	proc [dbo].[p_cinetam_move_movie_estimates]	@movie_id			int,
											@country_code		char(1),
											@start_date			datetime

as 

declare			@error			int

set nocount on

begin transaction

update cinetam_movie_complex_estimates  
set screening_date = dateadd(wk, datediff(wk, (select min(asasa.screening_date) from cinetam_movie_complex_estimates asasa where asasa.movie_id = cinetam_movie_complex_estimates.movie_id ), @start_date), cinetam_movie_complex_estimates.screening_date)
where movie_id = @movie_id
and complex_id in (	select			complex_id 
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
