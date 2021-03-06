/****** Object:  StoredProcedure [dbo].[p_upload_movie_sessions]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_upload_movie_sessions]
GO
/****** Object:  StoredProcedure [dbo].[p_upload_movie_sessions]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[p_upload_movie_sessions]		@file_to_upload			varchar(1000)
	
AS

SET NOCOUNT ON

DECLARE		@cmd_file_upload		varchar(2000),
						@error							int

/*
 * Stage 1 - Upload Session data
 */ 
 
/*	Use Dynamic SQL because the Row terminators are LF*/

--Oppurtunity to See
SET @cmd_file_upload = 'BULK INSERT #session_temp
FROM ''' + @file_to_upload + '''WITH (      FIELDTERMINATOR = ''/t'',  ROWTERMINATOR = '''+CHAR(10)+''')'

--Create the Temp Tables
Create table #session_temp
(
	provider_id							int							null,
	screening_date						datetime					null,
	start_date								datetime					null,
	session_time							datetime					null,
	exhibitor_complex_code		varchar(30)			null,
	complex_name						varchar(255)         null,
	exhbiitor_movie_code			varchar(30)			null,
	movie_title								varchar(255)         null,
	movie_medium						varchar(10)			null,
	advertising_medium				varchar(10)			null,
	three_d_presentation			varchar(10)			null,
	premium_screen_code			varchar(10)			null
)

--Execute the Bulk Upload

EXEC(@cmd_file_upload)

select @error = @@error
if @error <> 0 
begin
	raiserror ('Error uploading session file', 16, 1)
	return -1
end

begin transaction

insert		into movie_history_session_raw_data 
select		provider_id,
				screening_date,
				start_date,
				session_time,
				exhibitor_complex_code,
				complex_name,
				exhbiitor_movie_code,
				movie_title,
				movie_medium,
				advertising_medium,
				three_d_presentation,
				premium_screen_code
from		#session_temp

select @error = @@error
if @error <> 0 
begin
	raiserror ('Error moving rows to the main table', 16, 1)
	rollback transaction
	return -1
end

commit transaction
return 0
GO
