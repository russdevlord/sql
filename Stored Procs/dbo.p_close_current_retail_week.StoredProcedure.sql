/****** Object:  StoredProcedure [dbo].[p_close_current_retail_week]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_close_current_retail_week]
GO
/****** Object:  StoredProcedure [dbo].[p_close_current_retail_week]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_close_current_retail_week]

as

declare			@error 				int,
				@min_open_week		datetime

set nocount on

begin transaction

update 	outpost_screening_dates
set		screening_date_status = 'X'
where 	screening_date_status = 'C'

select @error = @@error
if @error <> 0
begin
	raiserror ('Error closing current retail week', 16, 1)
	rollback transaction
	return -100
end

select 		@min_open_week = min(screening_date)
from		outpost_screening_dates 
where 		screening_date_status = 'O'

select @error = @@error
if @error <> 0
begin
	raiserror ('Error selecting current retail week', 16, 1)
	rollback transaction
	return -100
end

update 	outpost_screening_dates
set		screening_date_status = 'C'
where 	screening_date = @min_open_week

select @error = @@error
if @error <> 0
begin
	raiserror ('Error setting current retail week', 16, 1)
	rollback transaction
	return -100
end


update outpost_spot
set spot_status = 'X'
where spot_status = 'A'
and screening_date = @min_open_week

select @error = @@error
if @error <> 0
begin
	raiserror ('Error updating outpost_spot records', 16, 1)
	rollback transaction
	return -100
end


commit transaction
return 0
GO
