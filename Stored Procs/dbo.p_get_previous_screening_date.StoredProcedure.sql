/****** Object:  StoredProcedure [dbo].[p_get_previous_screening_date]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_get_previous_screening_date]
GO
/****** Object:  StoredProcedure [dbo].[p_get_previous_screening_date]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_get_previous_screening_date]	@screening_date		datetime,
																					@mode							int
																					
as

declare 			@error												int,
						@previous_screening_date			datetime,
						@period_no										int

if @mode = 1 /* Onscreen */
begin
	select 	@period_no = period_no
	from		film_screening_dates
	where	screening_date = @screening_date
	
	select @error = @@error
	if @error <> 0 
	begin
		raiserror ('Error retrieving period no', 16, 1)
		return -1
	end
	
	select 	@previous_screening_date = max(screening_date)
	from		film_screening_dates
	where	screening_date < @screening_date
	and			period_no = @period_no
	
	select @error = @@error
	if @error <> 0 
	begin
		raiserror ('Error retrieving previous screening_date', 16, 1)
		return -1
	end
end																					

if @mode = 2 /* Retail */
begin
	select 	@period_no = period_no
	from		outpost_screening_dates
	where	screening_date = @screening_date
	
	select @error = @@error
	if @error <> 0 
	begin
		raiserror ('Error retrieving period no', 16, 1)
		return -1
	end
	
	select 	@previous_screening_date = max(screening_date)
	from		outpost_screening_dates
	where	screening_date < @screening_date
	and			period_no = @period_no
	
	select @error = @@error
	if @error <> 0 
	begin
		raiserror ('Error retrieving previous screening_date', 16, 1)
		return -1
	end
end																					

select @previous_screening_date

return 0
GO
