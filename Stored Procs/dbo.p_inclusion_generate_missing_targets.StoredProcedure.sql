USE [production]
GO
/****** Object:  StoredProcedure [dbo].[p_inclusion_generate_missing_targets]    Script Date: 11/03/2021 2:30:34 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_inclusion_generate_missing_targets]			@inclusion_id			int

as

declare				@error							int,
						@inclusion_type			int

set nocount on

select			@inclusion_type = inclusion_type
from				inclusion
where			inclusion_id = @inclusion_id

if @inclusion_type = 29
begin
	exec @error = p_follow_film_generate_missing_targets @inclusion_id
end
else
begin
	exec @error = p_inclusion_audience_generate_missing_targets @inclusion_id
end

return 0
GO
