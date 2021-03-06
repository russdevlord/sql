/****** Object:  StoredProcedure [dbo].[p_movie_history_weekend_prerun_creation]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_movie_history_weekend_prerun_creation]
GO
/****** Object:  StoredProcedure [dbo].[p_movie_history_weekend_prerun_creation]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_movie_history_weekend_prerun_creation]		@screening_date			datetime

as

declare			@error										int,
						@arg_date									varchar(8),
						@exhibitor_complex_code		varchar(30),
						@complex_name						varchar(60),						
						@exhibitor_film_code				varchar(30),
						@movie_title								varchar(150),
						@no_sessions								int,
						@gold_class								char(1),
						@complex_id								int,
						@movie_id									int,
						@provider_id								int,
						@rowcount									int,
						@occurence								int,
						@movie_id_current					int,
						@three_d_type							int,
						@complex_id_current				int

set nocount on

begin transaction

delete	certificate_item_weekend
where	certificate_group in (select certificate_group_id from certificate_group_weekend where screening_date = @screening_date)

select @error = @@error
if @error <> 0
begin
	rollback transaction
	raiserror ('Failed to delete weekend items', 16, 1)
	return -1
end

delete movie_history_weekend_prerun
where screening_date = @screening_date

select @error = @@error
if @error <> 0
begin
	rollback transaction
	raiserror ('Failed to delete weekend history', 16, 1)
	return -1
end

delete certificate_group_weekend
where screening_date = @screening_date

select @error = @@error
if @error <> 0
begin
	rollback transaction
	raiserror ('Failed to delete weekend groups', 16, 1)
	return -1
end

select @arg_date =  convert(char(8),@screening_date,112)  

declare			vista_csr cursor for
select			provider_id, 
					exhibitor_complex_code,
					complex_name,
					exhibitor_film_code,
					movie_title,
					no_sessions,
					gold_class
from				vista_data_temp
order by		provider_id, 
					exhibitor_complex_code,
					complex_name,
					exhibitor_film_code,
					movie_title,
					no_sessions,
					gold_class
for				read only

select @movie_id_current = 0
select	@occurence = 0
select	@complex_id_current = 0

open vista_csr
fetch vista_csr into @provider_id, @exhibitor_complex_code,@complex_name,@exhibitor_film_code,@movie_title,@no_sessions,@gold_class
while(@@fetch_status = 0)
begin

	if left(@movie_title, 4) = '(3D)'
		select @three_d_type = 2
	else
		select @three_d_type = 1
		

	select	@complex_id = complex_id
	from	data_translate_complex
	where	data_provider_id = @provider_id
	and		complex_code = @exhibitor_complex_code
	
	select	@error = @@error,
				@rowcount = @@rowcount	
				
	--do erroring			
	if @error <> 0
	begin
		rollback transaction
		raiserror ('Error when trying to link complex', 16, 1)
		return -1
	end
	
	select	@movie_id = movie_id
	from	data_translate_movie
	where	data_provider_id = @provider_id
	and		movie_code = @exhibitor_film_code
	
	select	@error = @@error,
				@rowcount = @@rowcount	
				
	--do erroring				
	if @error <> 0
	begin
		rollback transaction
		raiserror ('Error when trying to link movie', 16, 1)
		return -1
	end
	
	--increment movie compare and occurence field
	if @movie_id <> @movie_id_current
		select @occurence = 1
	else
		select 	@occurence = @occurence + 1
	
	if @movie_id is not null 
	begin
		insert into movie_history_weekend_prerun 
		(
		movie_id, 
		complex_id,
		screening_date,
		occurence,
		print_medium,
		three_d_type,
		altered,
		advertising_open,
		source,
		start_date,
		premium_cinema,
		show_category,
		movie_print_medium,
		sessions_scheduled,
		country,
		status
		)
		values	(
		@movie_id,
		@complex_id,
		@screening_date,
		@occurence,
		'D',
		@three_d_type,
		'N',
		'Y',
		'C',
		@screening_date,
		@gold_class,
		'U',
		'D',
		@no_sessions,
		'A',
		'C'
		)

		select @error = @@error
		if @error <> 0
		begin
			rollback transaction
			raiserror ('Error when insert programming row', 16, 1)
			return -1
		end

	end
	
	select @movie_id_current = @movie_id
	select @complex_id_current = @complex_id
	
	select @movie_id = null
	select @complex_id = null

	fetch vista_csr into @provider_id, @exhibitor_complex_code,@complex_name,@exhibitor_film_code,@movie_title,@no_sessions,@gold_class
end

commit transaction
return 0
GO
