/****** Object:  StoredProcedure [dbo].[p_dart_run_process]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_dart_run_process]
GO
/****** Object:  StoredProcedure [dbo].[p_dart_run_process]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE proc [dbo].[p_dart_run_process]			@screening_date			datetime
																		
as

declare					@error					int,
								@country_code		char(1),
								@cmdpath				nvarchar(200)


print @screening_date
print 'Step 1 - start'
exec @error = p_dart_upload_quividi_qnulls	@screening_date

if @error <> 0
begin
	raiserror ('Error: Step 1 failed', 16, 1)
	return -1
end

print 'Step 1 - end'
print convert(varchar(50), getdate(), 109)

print 'Step 2 - start'
exec @error = p_dart_upload_dcmedia	@screening_date

if @error <> 0
begin
	raiserror ('Error: Step 2 failed', 16, 1)
	return -1
end

print 'Step 2 - end'
print convert(varchar(50), getdate(), 109)

print 'Step 3 - start'
exec @error = p_dart_store_campaign_info	@screening_date

if @error <> 0
begin
	raiserror ('Error: Step 3failed', 16, 1)
	return -1
end

print 'Step 3 - end'
print convert(varchar(50), getdate(), 109)

print 'Step 4 - start'
exec @error = p_dart_store_engagement	@screening_date

if @error <> 0
begin
	raiserror ('Error: Step 4 failed', 16, 1)
	return -1
end

print 'Step 4 - end'
print convert(varchar(50), getdate(), 109)

print 'Step 5 - start'
exec @error = p_dart_store_tower_ots	@screening_date

if @error <> 0
begin
	raiserror ('Error: Step 5 failed', 16, 1)
	return -1
end

print 'Step 5 - end'
print convert(varchar(50), getdate(), 109)


print 'Step 6 - start'

/*set @cmdpath = 'MD '+ ''f:\Dart Data Files\' + convert(varchar(50), getdate(), 105) + '''
exec master.dbo.xp_cmdshell @cmdpath

set @cmdpath = 'MOVE '+ ''f:\Dart Data Files\dartots.csv' 'f:\Dart Data Files\' +  + convert(varchar(50), getdate(), 105) + '\dartots ' + convert(varchar(50), getdate(), 105) + '.csv''
exec master.dbo.xp_cmdshell @cmdpath

set @cmdpath = 'MOVE '+ ''f:\Dart Data Files\dartviewers.csv' 'f:\Dart Data Files\' +  + convert(varchar(50), getdate(), 105) + '\dartviewers ' + convert(varchar(50), getdate(), 105) + '.csv''
exec master.dbo.xp_cmdshell @cmdpath 
*/
print 'Step 6 - end'
print convert(varchar(50), getdate(), 109)

return 0
GO
