USE [production]
GO
/****** Object:  StoredProcedure [dbo].[p_dart_upload_data]    Script Date: 11/03/2021 2:30:34 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[p_dart_upload_data]		@screening_date			datetime
	
AS

SET NOCOUNT ON

DECLARE		@cmd_OTS				varchar(1000),
						@cmd_Watcher        varchar(1000),
						@error							int

/*
 * Stage 1 - Upload Quividi data
 */ 
 
/*	Use Dynamic SQL because the Row terminators are LF*/

--Oppurtunity to See
/*SET @cmd_OTS = 'BULK INSERT #t_dart_OTS
FROM ''c:\Locationdata.csv''
WITH (      FIELDTERMINATOR = '','',
            ROWTERMINATOR = '''+CHAR(10)+''')'*/

SET @cmd_OTS = 'BULK INSERT #t_dart_OTS
FROM ''\\valsydsql01\m$\Dart Data Files\Locationdata.csv''
WITH (      FIELDTERMINATOR = '','',
            ROWTERMINATOR = '''+CHAR(10)+''')'


--Watcher Data        
/*SET @cmd_Watcher = 'BULK INSERT #t_dart_watcher
FROM ''c:\Watcherdata.csv''
WITH (      FIELDTERMINATOR = '','',
            ROWTERMINATOR = '''+CHAR(10)+''')'    */  

SET @cmd_Watcher = 'BULK INSERT #t_dart_watcher
FROM ''\\valsydsql01\m$\Dart Data Files\Watcherdata.csv''
WITH (      FIELDTERMINATOR = '','',
            ROWTERMINATOR = '''+CHAR(10)+''')'

--Create the Temp Tables
Create table #t_dart_OTS
(
	Location_ID				int,
	start_time					datetime,
	time_resolution			int,
	OTS_count				int,
	watcher_count			int
)

Create table #t_dart_watcher
(
	location_id					int,
	gender						int,
	age_band					int,
	start_time					datetime,
	session_time				int,
	attention_time			int,
	watcher_count			int,
	age_value					int,
	features						int,
	mood							bigint	
)

Create table #t_dart_OTS_dist
(
	Location_ID				int,
	start_time					datetime,
	time_resolution			int,
	OTS_count				int,
	watcher_count			int
)

Create table #t_dart_watcher_dist
(
	location_id							int,
	gender								int,
	age_band							int,
	start_time							datetime,
	session_time						int,
	attention_time					int,
	watcher_count					int,
	age_value							tinyint,
	glasses								tinyint,
	moustache							tinyint,
	beard									tinyint,
	mood_very_unhappy			tinyint,
	mood_unhappy					tinyint,
	mood_neutral						tinyint,
	mood_happy						tinyint,
	mood_very_happy				tinyint
)

--Execute the Bulk Upload
EXEC(@cmd_OTS)

select @error = @@error
if @error <> 0 
begin
	raiserror ('Error uploading OTS file', 16, 1)
	return -1
end

EXEC(@cmd_Watcher)

select @error = @@error
if @error <> 0 
begin
	raiserror ('Error uploading Watcher file', 16, 1)
	return -1
end

insert		into #t_dart_OTS_dist 
select		distinct Location_ID,
				start_time,
				time_resolution,
				OTS_count,
				watcher_count
from		#t_dart_OTS
where		start_time between @screening_date and dateadd(wk, 1, @screening_date)

select @error = @@error
if @error <> 0 
begin
	raiserror ('Error distincting the ots file', 16, 1)
	return -1
end

update #t_dart_watcher set mood = mood + 2147483648

select @error = @@error
if @error <> 0 
begin
	raiserror ('Error adding 2147483648 to mood', 16, 1)
	return -1
end

insert		into #t_dart_watcher_dist 
select		location_id,
				gender,
				age_band,
				start_time,
				session_time,
				attention_time,
				watcher_count,
				age_value,  
				dbo.BinaryToDecimal(convert(char(2), convert(char(1), tbl.features / 2 % 2) +  convert(char(1), tbl.features % 2))) as glasses,
				dbo.BinaryToDecimal(convert(char(2), convert(char(1), tbl.features / 8 % 2) +  convert(char(1), tbl.features / 4 % 2))) as moustache,
				dbo.BinaryToDecimal(convert(char(2), convert(char(1), tbl.features / 32 % 2) +  convert(char(1), tbl.features / 16 % 2))) as beard,
				100 * dbo.BinaryToDecimal(dbo.converttobase(tbl.mood, 2, 25, 8)) / 255 as mood_very_unhappy,
				100 * dbo.BinaryToDecimal(dbo.converttobase(tbl.mood, 2, 17, 8)) / 255 as mood_unhappy,
				100 - ((100 * dbo.BinaryToDecimal(dbo.converttobase(tbl.mood, 2, 25, 8)) / 255) + (100 * dbo.BinaryToDecimal(dbo.converttobase(tbl.mood, 2, 17, 8)) / 255) + (100 * dbo.BinaryToDecimal(dbo.converttobase(tbl.mood, 2, 9, 8)) / 255)  + (100 * dbo.BinaryToDecimal(dbo.converttobase(tbl.mood, 2, 1, 8)) / 255)) as mood_neutral,
				100 * dbo.BinaryToDecimal(dbo.converttobase(tbl.mood, 2, 9, 8)) / 255 as mood_happy,
				100 * dbo.BinaryToDecimal(dbo.converttobase(tbl.mood, 2, 1, 8)) / 255 as mood_very_happy
from		#t_dart_watcher tbl
where		age_value < 32767
and			mood < 32767
and			features < 32767
	
select @error = @@error
if @error <> 0 
begin
	raiserror ('Error distincting the viewer file', 16, 1)
	return -1
end

--select * from #t_dart_watcher_dist 

delete		dart_quividi_ots
where		screening_date = @screening_date

select @error = @@error
if @error <> 0 
begin
	raiserror ('Error deleting dart_quividi_ots data', 16, 1)
	return -1
end

delete		dart_quividi_details
where		screening_date = @screening_date

select @error = @@error
if @error <> 0 
begin
	raiserror ('Error deleting dart_quividi_details data', 16, 1)
	return -1
end

/*
 * Stage 2 Load Data into Dart Quividi Data Detailed - Expert site types
 */ 

insert			into dart_quividi_details
select			distinct @screening_date,
					dw.start_time,
					dd.dart_demographics_id,
					'A',
					dqpx.outpost_panel_id, 
					'A',
					sum(dw.watcher_count) as Viewers,
					avg(dw.session_time / 10) as Dwell_avg,
					min(dw.session_time / 10) as dwell_min,
					max(dw.session_time / 10) as dwell_max,
					avg(dw.attention_time / 10) as attention_avg,
					min(dw.attention_time / 10) as attention_min,
					max(dw.attention_time / 10) as attention_max,
					glasses,
					moustache,
					beard,
					mood_very_unhappy,
					mood_unhappy,
					mood_neutral,
					mood_happy,
					mood_very_happy
From			#t_dart_watcher_dist DW,
					dart_quividi_panel_xref dqpx,
					dart_demographics dd		
WHERE		dw.start_time between @screening_date and dateadd(wk, 1, @screening_date)
and				dw.age_value between dd.min_age and dd.max_age
and				case dw.gender when 1 then 'M' when 2 then 'F' else 'U' end = dd.gender
and				dd.dart_demographics_id > 20
and				dw.location_id =  dqpx.quividi_id
and				dw.age_value is not null
and				glasses < 32767
and				moustache < 32767
and				beard < 32767
and				mood_very_unhappy < 32767
and				mood_unhappy < 32767
and				mood_neutral < 32767
and				mood_happy < 32767
and				mood_very_happy < 32767
group by		dw.start_time,
					dd.dart_demographics_id,
					dqpx.outpost_panel_id,
					glasses,
					moustache,
					beard,
					mood_very_unhappy,
					mood_unhappy,
					mood_neutral,
					mood_happy,
					mood_very_happy,
					dd.dart_demographics_id

select @error = @@error
if @error <> 0 
begin
	raiserror ('Error inserting into dart_quividi_details part 2', 16, 1)
	return -1
end

--OTS Information
insert			into	dart_quividi_ots
Select			outpost_panel_id, 
					@screening_date,
					start_time, 
					'A',
					sum(ots_count), 
					sum(watcher_count)
FROM			#t_dart_OTS_dist
JOIN			dart_quividi_panel_xref dqpx
						ON  #t_dart_OTS_dist.Location_ID =  dqpx.quividi_id
WHERE		start_time between @screening_date and dateadd(wk, 1, @screening_date)
group by		outpost_panel_id, 
					start_time

select @error = @@error
if @error <> 0 
begin
	raiserror ('Error inserting in OTS table', 16, 1)
	return -1
end

/*
 * Update Country
 */ 

update		dart_quividi_ots
set				country_code = 'Z'
where			screening_date = @screening_date
and				outpost_panel_id in (select outpost_panel_id from outpost_panel where outpost_venue_id in (select outpost_venue_id from outpost_venue where state_code = 'NZ'))

select @error = @@error
if @error <> 0 
begin
	raiserror ('Error updating tower tv records to NZ in dart_quividi_ots table', 16, 1)
	return -1
end


update		dart_quividi_details
set				country_code = 'Z'
where			screening_date = @screening_date
and				outpost_panel_id in (select outpost_panel_id from outpost_panel where outpost_venue_id in (select outpost_venue_id from outpost_venue where state_code = 'NZ'))

select @error = @@error
if @error <> 0 
begin
	raiserror ('Error updating tower tv records to NZ in dart_quividi_details table', 16, 1)
	return -1
end

return 0
GO
