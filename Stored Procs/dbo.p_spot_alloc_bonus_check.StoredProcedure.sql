/****** Object:  StoredProcedure [dbo].[p_spot_alloc_bonus_check]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_spot_alloc_bonus_check]
GO
/****** Object:  StoredProcedure [dbo].[p_spot_alloc_bonus_check]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_spot_alloc_bonus_check]	@campaign_no	int,
										@complex_id		int,
										@spot_type		char(1),
										@add_remove		char(1)

as

declare		@error			int,
			@count			int,
			@bonus_allowed	char(1),
			@bonus_count	int

select 	@bonus_allowed = bonus_allowed
from	complex
where	complex_id = @complex_id

if @bonus_allowed = 'Y'
	return 0

select 	@count = count(spot_id)
from	campaign_spot
where	campaign_no = @campaign_no
and		complex_id = @complex_id
and 	spot_type = 'S'
and		spot_status != 'C'
and		spot_status != 'D'
and		spot_status != 'H'
and		spot_status != 'U'
and		spot_status != 'N'

select @error = @@error
if @error != 0
begin
	raiserror ('Error:  Cannot Determine no of Scheduled Spots', 16, 1)
	return -1
end

select 	@bonus_count = count(spot_id)
from	campaign_spot
where	campaign_no = @campaign_no
and		complex_id = @complex_id
and 	spot_type = 'B'

select @error = @@error
if @error != 0
begin
	raiserror ('Error:  Cannot Determine no of Bonus Spots', 16, 1)
	return -1
end

if @spot_type = 'B'
begin
	if @add_remove = 'A' and @count < 1 --adding from another complex
		goto error

	if @add_remove = 'C' and @count <= 1 --changing at the same complex
		goto error

	if @add_remove = 'R' and (@count = 0 and @bonus_count > 1) --removing from this complex
		goto error
end
else
begin
	if @add_remove = 'R' and (@count = 0)
		goto error
end

return 0

error:
	raiserror ('This Bonus Allocation will result in the complex no having Scheduled Spots.  Allocation denied.', 16, 1)
	return -1
GO
