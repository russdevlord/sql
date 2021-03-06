/****** Object:  StoredProcedure [dbo].[p_delete_movie]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_delete_movie]
GO
/****** Object:  StoredProcedure [dbo].[p_delete_movie]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_delete_movie]		@movie_id		integer

as

declare @error          int,
        @rowcount			int


--Check if the movie has been used anywhere.
if exists (select 1
             from movie_screening_instructions
            where movie_id = @movie_id)
begin
	raiserror ('Movie is targetted by some packages and cannot be deleted.', 16, 1)
	return -1
end

if exists (select 1
             from movie_history
            where movie_id = @movie_id)
begin
	raiserror ('Movie has movie history records and cannot be deleted.', 16, 1)
	return -1
end

if exists (select 1
             from film_campaign_movie_archive
            where movie_id = @movie_id)
begin
	raiserror ('Movie is used in archive records and cannot be deleted.', 16, 1)
	return -1
end

if exists (select 1 
			    from cinema_attendance
				where movie_id = @movie_id)
begin
	raiserror ('Movie is used in attendance records and cannot be deleted.', 16, 1)
	return -1
end


/*
 * Begin Transaction
 */

begin transaction

/*
 * Delete movie country
 */
delete movie_country
 where movie_id = @movie_id
select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	return -1
end	

/*
 * Delete movie targets
 */
delete target_categories
 where movie_id = @movie_id
select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	return -1
end	

delete target_audience
 where movie_id = @movie_id
select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	return -1
end	


delete movie_screening_instructions
 where movie_id = @movie_id
select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	return -1
end	

/*
 * Delete movie
 */
delete movie
 where movie_id = @movie_id

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	return -1
end	

/*
 * Commit and Return
 */

commit transaction
return 0
GO
