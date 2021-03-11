USE [production]
GO
/****** Object:  StoredProcedure [dbo].[p_attendance_complex_tran_update]    Script Date: 11/03/2021 2:30:33 PM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create proc [dbo].[p_attendance_complex_tran_update]	@data_provider_id		int,
											@complex_code				varchar(30),
											@complex_name				varchar(255),
											@employee_id			int,
											@process_date			datetime,
											@exclusion_reason		varchar(255),
											@complex_id				int,
											@type					char(1),
											@cinvendo_complex_name	varchar(50)

as

declare		@error		int

begin transaction

if @type = 'I'
begin

	delete		data_translate_complex
	where		complex_id = @complex_id
	and			data_provider_id = @data_provider_id
	and			complex_code = @complex_code

	select @error = @@error
	if @error != 0 
	begin
		raiserror ('Error: Could Not Delete from data_translate_complex', 16, 1)
		rollback transaction
		return -1
	end
end

if @type = 'E'
begin
	delete		attendance_complex_exclude
	where		data_provider_id = @data_provider_id
	and			complex_code = @complex_code

	select @error = @@error
	if @error != 0 
	begin
		raiserror ('Error: Could Not Delete from attendance_complex_exclude', 16, 1)
		rollback transaction
		return -1
	end
end

commit transaction
return 0
GO
