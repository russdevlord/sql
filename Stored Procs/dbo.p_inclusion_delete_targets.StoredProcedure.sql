/****** Object:  StoredProcedure [dbo].[p_inclusion_delete_targets]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_inclusion_delete_targets]
GO
/****** Object:  StoredProcedure [dbo].[p_inclusion_delete_targets]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_inclusion_delete_targets]	@inclusion_id		int
											
as

declare		@error			int,
			@screened		int,
			@attendance		int

set nocount on

begin transaction

select		@attendance = 0

select		@attendance = isnull(SUM(original_target_attendance), 0)
from		inclusion_follow_film_targets
where		inclusion_id = @inclusion_id
and			processed = 'N'

select @error = @@error

if @error <> 0
begin
	raiserror ('Error reducing master targer - follow film', 16, 1)
	rollback transaction
	return -1
end

update		inclusion_cinetam_master_target
set			attendance = attendance - @attendance
where		inclusion_id = @inclusion_id

select @error = @@error

if @error <> 0
begin
	raiserror ('Error reducing master targer - follow film', 16, 1)
	rollback transaction
	return -1
end

delete		inclusion_follow_film_targets
where		inclusion_id = @inclusion_id
and			processed = 'N'

select @error = @@error

if @error <> 0
begin
	raiserror ('Error deleting follow film targets', 16, 1)
	rollback transaction
	return -1
end

select		@attendance = 0

select		@attendance = isnull(SUM(original_target_attendance), 0)
from		inclusion_cinetam_targets
where		inclusion_id = @inclusion_id
and			processed = 'N'

select @error = @@error

if @error <> 0
begin
	raiserror ('Error reducing master targer - MAPTAP', 16, 1)
	rollback transaction
	return -1
end

update		inclusion_cinetam_master_target
set			attendance = attendance - @attendance
where		inclusion_id = @inclusion_id

select @error = @@error

if @error <> 0
begin
	raiserror ('Error reducing master targer - MAPTAP', 16, 1)
	rollback transaction
	return -1
end

delete		inclusion_cinetam_targets
where		inclusion_id = @inclusion_id
and			processed = 'N'

select @error = @@error

if @error <> 0
begin
	raiserror ('Error deleting movie mix tap targets', 16, 1)
	rollback transaction
	return -1
end

commit transaction
return 0
GO
