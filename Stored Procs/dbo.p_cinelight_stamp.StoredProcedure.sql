USE [production]
GO
/****** Object:  StoredProcedure [dbo].[p_cinelight_stamp]    Script Date: 11/03/2021 2:30:33 PM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_cinelight_stamp]		@player_name			varchar(40),
                                 	@screening_date			datetime,
                                 	@user          			char(30),
                                 	@status					char(1)
as

declare @error     		int,
        @sent_revision	smallint,
        @new_revision	smallint

/*
 * Get Revision Numbers
 */

select @sent_revision = IsNull(max(cinelight_revision),-1)
  from cinelight_dsn_player_date
 where player_name = @player_name and
       screening_date = @screening_date

/*
 * Calculate New revision
 */

select @new_revision = @sent_revision + 1

/*
 * Begin Transaction
 */

begin transaction

/*
 * Set the cinelight Generation and Revision
 */

update cinelight_dsn_player_date 
   set cinelight_generation = getdate(),
       cinelight_revision = @new_revision,
       cinelight_generation_user = @user,
       cinelight_generation_status = @status
 where player_name = @player_name and
       screening_date = @screening_date

select @error = @@error
if (@error != 0)
begin
	rollback transaction
	raiserror ( 'Error', 16, 1) 
   return -1
end	

/*
 * Commit and Return
 */

commit transaction
return 0
GO
