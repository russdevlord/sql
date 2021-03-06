/****** Object:  StoredProcedure [dbo].[p_delete_cinetam_movie_complex_estimates]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_delete_cinetam_movie_complex_estimates]
GO
/****** Object:  StoredProcedure [dbo].[p_delete_cinetam_movie_complex_estimates]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create proc [dbo].[p_delete_cinetam_movie_complex_estimates]

as

declare		@error				int,
			@screening_date		datetime

set nocount on

begin transaction

select			@screening_date = max(screening_date)
from			film_screening_dates
where			attendance_status = 'X'

select			@error = @@error
if @error <> 0
begin
	raiserror('Error determining most recent closed screening_date', 16, 1)
	rollback transaction
	return -1
end

delete			cinetam_movie_complex_estimates
where			screening_date <= dateadd(wk, -26, @screening_date)

select			@error = @@error
if @error <> 0
begin
	raiserror('Error deleting old estimates', 16, 1)
	rollback transaction
	return -1
end

commit transaction
return 0
GO
