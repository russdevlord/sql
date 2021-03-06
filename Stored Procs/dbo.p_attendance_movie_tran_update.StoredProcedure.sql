/****** Object:  StoredProcedure [dbo].[p_attendance_movie_tran_update]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_attendance_movie_tran_update]
GO
/****** Object:  StoredProcedure [dbo].[p_attendance_movie_tran_update]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create proc [dbo].[p_attendance_movie_tran_update]	@data_provider_id		int,
											@movie_code				varchar(30),
											@movie_name				varchar(255),
											@employee_id			int,
											@process_date			datetime,
											@exclusion_reason		varchar(255),
											@movie_id				int,
											@type					char(1),
											@cinvendo_movie_name	varchar(50)

as

declare		@error		int

begin transaction

if @type = 'I'
begin

	delete		data_translate_movie
	where		movie_id = @movie_id
	and			data_provider_id = @data_provider_id
	and			movie_code = @movie_code

	select @error = @@error
	if @error != 0 
	begin
		raiserror ('Error: Could Not Delete from data_translate_movie', 16, 1)
		rollback transaction
		return -1
	end
end

if @type = 'E'
begin
	delete		attendance_movie_exclude
	where		data_provider_id = @data_provider_id
	and			movie_code = @movie_code

	select @error = @@error
	if @error != 0 
	begin
		raiserror ('Error: Could Not Delete from attendance_movie_exclude', 16, 1)
		rollback transaction
		return -1
	end
end

commit transaction
return 0
GO
