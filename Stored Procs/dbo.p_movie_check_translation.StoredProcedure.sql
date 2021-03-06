/****** Object:  StoredProcedure [dbo].[p_movie_check_translation]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_movie_check_translation]
GO
/****** Object:  StoredProcedure [dbo].[p_movie_check_translation]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create proc [dbo].[p_movie_check_translation]		@complex_id				int,
											@movie_id				int

as

declare			@error						int,
				@xml_count					int,
				@data_provider_id			int

set nocount on

select			@xml_count = count(*)
from			complex_ftp_path
where			complex_id = @complex_id

select			@error = @@error
if @error <> 0
begin
	raiserror ('Error determining if this complex is receiving XML packs for pre-show', 16, 1)
	return -1
end

if @xml_count = 0
begin
	select 1 as movie_ok
	return 0
end

select			@data_provider_id = data_provider_id
from			data_translate_complex
where			complex_id = @complex_id
group by		data_provider_id	

select			@error = @@error
if @error <> 0
begin
	raiserror ('Error determining this what data provider this complex belongs to', 16, 1)
	return -1
end

select			@xml_count = count(*)
from			data_translate_movie
where			movie_id = @movie_id
and				data_provider_id = @data_provider_id

select			@error = @@error
if @error <> 0
begin
	raiserror ('Error determining this data provider codes for this movie', 16, 1)
	return -1
end

if @xml_count = 0
begin
	raiserror ('This movie has no translation code and cannot be programmed for an XML complex.  Please contact the exhibitor to obtain their codes or wait until the movie appears in a feed for translation.', 16, 1)
	return -1
end
else
begin
	select 1 as movie_ok
	return 0
end

return 0
GO
