/****** Object:  StoredProcedure [dbo].[p_availability_delete_follow_film]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_availability_delete_follow_film]
GO
/****** Object:  StoredProcedure [dbo].[p_availability_delete_follow_film]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_availability_delete_follow_film]		@movie_id			int,
																			@country_code	char(1),
																			@mode					int
as

/*
 * Mode
 * 1 = Delete Master and Target tables
 * 2 = Delete Target tables only
 *
 */

declare				@error						int,
						@error_msg				varchar(100)

begin transaction

if @mode >= 1
begin
	delete		availability_follow_film_complex
	where		movie_id = @movie_id
	and			country_code = @country_code
	
	select @error = @@error
	if @error <> 0
	begin
		raiserror('Error: failed to delete complex level targets', 16, 1)
		rollback transaction
		return -1
	end
end

if @mode = 1
begin
	delete		availability_follow_film_master
	where		movie_id = @movie_id
	and			country_code = @country_code
	
	select @error = @@error
	if @error <> 0
	begin
		raiserror('Error: failed to delete master target', 16, 1)
		rollback transaction
		return -1
	end
end

commit transaction
return 0
GO
