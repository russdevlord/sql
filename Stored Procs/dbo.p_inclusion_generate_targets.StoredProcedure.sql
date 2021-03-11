USE [production]
GO
/****** Object:  StoredProcedure [dbo].[p_inclusion_generate_targets]    Script Date: 11/03/2021 2:30:34 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create proc [dbo].[p_inclusion_generate_targets]		@inclusion_id			int

as

declare		@error					int,
			@inclusion_type			int

select			@inclusion_type = inclusion_type
from			inclusion
where			inclusion_id = @inclusion_id

select @error = @@error
if @error <> 0
begin
	raiserror('Error obtaining inclusion type', 16, 1)
	return -1
end

begin transaction

if @inclusion_type = 29
	exec @error = p_follow_film_generate_targets @inclusion_id
else
	exec @error = p_inclusion_cinetam_generate_targets @inclusion_id


if @error <> 0
begin
	raiserror('Error generating targets', 16, 1)
	rollback transaction
	return -1
end

commit transaction
return 0
GO
