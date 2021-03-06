/****** Object:  StoredProcedure [dbo].[p_delete_inclusion]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_delete_inclusion]
GO
/****** Object:  StoredProcedure [dbo].[p_delete_inclusion]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_delete_inclusion]		@inclusion_id		integer

as

declare @error          int,
        @rowcount			int


--Check if the inclusion has been used anywhere.
if exists (select 1
             from inclusion_spot
            where inclusion_id = @inclusion_id)
begin
	raiserror ('Campaign inclusion is allocated to some spots and cannot be deleted.', 16, 1)
	return -1
end

--Check if the inclusion has been used anywhere.
if exists (select 1
             from inclusion
            where inclusion_id = @inclusion_id 
			and  tran_id is not null)
begin
	raiserror ('Campaign inclusion is allocated to some spots and cannot be deleted.', 16, 1)
	return -1
end

/*
 * Begin Transaction
 */

begin transaction

/*
 * Delete inclusion from pattern
 */

delete inclusion_pattern
 where inclusion_id = @inclusion_id
select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	return -1
end	



delete inclusion_cinetam_master_target
 where inclusion_id = @inclusion_id
select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	return -1
end	

delete inclusion_follow_film_targets
 where inclusion_id = @inclusion_id
select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	return -1
end	

delete inclusion_cinetam_targets
 where inclusion_id = @inclusion_id
select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	return -1
end	

delete inclusion_cinetam_package
 where inclusion_id = @inclusion_id
select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	return -1
end	

delete inclusion_cinetam_settings
 where inclusion_id = @inclusion_id
select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	return -1
end	



/*
 * Delete inclusion
 */

delete inclusion
 where inclusion_id = @inclusion_id

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
