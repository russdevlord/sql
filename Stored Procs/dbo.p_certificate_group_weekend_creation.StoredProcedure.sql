/****** Object:  StoredProcedure [dbo].[p_certificate_group_weekend_creation]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_certificate_group_weekend_creation]
GO
/****** Object:  StoredProcedure [dbo].[p_certificate_group_weekend_creation]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_certificate_group_weekend_creation] 	@complex_id					int,
																							@screening_date			datetime,
																							@certificate_type			smallint,
																							@movie_target				int,
																							@country_code				char(1)
as

/*
 * Declare Variables
 */

declare 	@error										int,
					@errorode									int,
					@group_id								int,
					@loop										smallint,
					@group_name						varchar(60),
					@cert_name							varchar(60),
					@movie_id								int,
					@last_movie_id					int,
					@short_name						varchar(25),
					@long_name							varchar(60),
					@occ										smallint,
					@premium_cinema				char(1),
					@show_category					char(1),
					@print_medium						char(1),
					@three_d_type						int,
					@movie_print_medium		char(1),
					@sponsorships						int,
					@group_no								int,
					@movie_name						varchar(60)


/*
 * Begin Transaction
 */

begin transaction

/*
 * Declare Cinema Screen Movie Cursor
 */

declare 	movie_csr cursor static for
select		hist.movie_id,
				movie.short_name,
				mc.movie_name,
				hist.occurence,
				hist.premium_cinema,
				hist.show_category,
				hist.print_medium,
				hist.three_d_type,
				hist.movie_print_medium
from 		movie_history_weekend_prerun hist,
				movie,
				movie_country mc,
				classification class
where 		hist.complex_id = @complex_id 
and			hist.screening_date = @screening_date 
and			hist.movie_id = movie.movie_id 
and			movie.movie_id = mc.movie_id 
and			mc.country_code = @country_code 
and			mc.classification_id = class.classification_id 
and			hist.movie_id = 102
order by	movie.short_name asc, hist.occurence
for read only

/*
 * Open Cursor
 */

select @loop = 0
open movie_csr
fetch movie_csr into @movie_id, @short_name, @long_name, @occ, @premium_cinema, @show_category, @print_medium, @three_d_type, @movie_print_medium
while(@@fetch_status = 0)
begin

	/*
	 * Get Certificate Group Id
	 */

	execute @errorode = p_get_sequence_number 'certificate_group_weekend',5,@group_id OUTPUT
	if (@errorode !=0)
	begin
		rollback transaction
		close movie_csr
		deallocate movie_csr
		return -1
	end
		
	/*
	 * Setup Group Name
	 */

	if (@occ > 1)
		select @group_name = @short_name + ' (' + convert(varchar(2),@occ) + ')',
            @cert_name = @long_name + ' - ' + convert(varchar(2),@occ), 
            @movie_name = @movie_name + ' - ' + convert(varchar(2),@occ)
	else
		select @group_name = @short_name,
            @cert_name = @long_name
            
	/*
	 * Increment Loop Count
	 */

	select @loop = @loop + 1

	if @occ > @loop
		select @loop = @occ
 
	/*
	 * Create Certificate Group
	 */

	insert into certificate_group_weekend (
				certificate_group_id,
				complex_id,
				screening_date,
				group_no,
				group_short_name,
				group_name,
				is_movie,
				premium_cinema,
				show_category, 
				print_medium, 
				three_d_type,
				movie_print_medium) values (
				@group_id,
				@complex_id,
				@screening_date,
				@loop,
				@group_name,
				@cert_name,
				'Y',
				@premium_cinema,
				isnull(@show_category, 'U') , 
				@print_medium, 
				@three_d_type,
				@movie_print_medium
				)

	select @error = @@error
	if ( @error !=0 )
	begin
		rollback transaction
		close movie_csr
		deallocate movie_csr
		return @error
	end	

	/*
	 * Link Movie History
	 */
	
	update 	movie_history_weekend_prerun
	set 	certificate_group = @group_id
	where	movie_id = @movie_id and
			complex_id = @complex_id and
			screening_date = @screening_date and
			occurence = @occ

	select @error = @@error
	if ( @error !=0 )
	begin
		rollback transaction
		close movie_csr
		deallocate movie_csr
		return @error
	end	

	/*
	 * Fetch Next Movie
	 */

	fetch movie_csr into @movie_id, @short_name, @long_name, @occ, @premium_cinema, @show_category, @print_medium, @three_d_type, @movie_print_medium

end
close movie_csr
deallocate movie_csr

/*
 * Declare Normal Movie Cursor
 */

declare 	movie_csr cursor static for
select		hist.movie_id,
				movie.short_name,
				mc.movie_name + ' (' + convert(varchar(5),class.classification_code) + ')',
				hist.occurence,
				hist.premium_cinema,
				hist.show_category,
				hist.print_medium,
				hist.three_d_type,
				hist.movie_print_medium
from 		movie_history_weekend_prerun hist,
				movie,
				movie_country mc,
				classification class
where 		hist.complex_id = @complex_id 
and			hist.screening_date = @screening_date 
and			hist.movie_id = movie.movie_id 
and			movie.movie_id = mc.movie_id 
and			mc.country_code = @country_code 
and			mc.classification_id = class.classification_id 
and			hist.movie_id <> 102
order by	movie.short_name asc, hist.occurence
for read only

/*
 * Open Cursor
 */

open movie_csr
fetch movie_csr into @movie_id, @short_name, @long_name, @occ, @premium_cinema, @show_category, @print_medium, @three_d_type, @movie_print_medium
while(@@fetch_status = 0)
begin

	/*
	 * Get Certificate Group Id
	 */

	execute @errorode = p_get_sequence_number 'certificate_group_weekend',5,@group_id OUTPUT
	if (@errorode !=0)
	begin
		rollback transaction
		close movie_csr
		deallocate movie_csr
		return -1
	end
		
	/*
	 * Setup Group Name
	 */

	if (@occ > 1)
		select @group_name = @short_name + ' (' + convert(varchar(2),@occ) + ')',
            @cert_name = @long_name + ' - ' + convert(varchar(2),@occ), 
            @movie_name = @movie_name + ' - ' + convert(varchar(2),@occ)
	else
		select @group_name = @short_name,
            @cert_name = @long_name
            
	/*
	 * Increment Loop Count
	 */

	select @loop = @loop + 1

	/*
	 * Create Certificate Group
	 */

	insert into certificate_group_weekend (
				certificate_group_id,
				complex_id,
				screening_date,
				group_no,
				group_short_name,
				group_name,
				is_movie,
				premium_cinema,
				show_category, 
				print_medium, 
				three_d_type,
				movie_print_medium) values (
				@group_id,
				@complex_id,
				@screening_date,
				@loop,
				@group_name,
				@cert_name,
				'Y',
				@premium_cinema,
				isnull(@show_category, 'U') , 
				@print_medium, 
				@three_d_type,
				@movie_print_medium
				)

	select @error = @@error
	if ( @error !=0 )
	begin
		rollback transaction
		close movie_csr
		deallocate movie_csr
		return @error
	end	

	/*
	 * Link Movie History
	 */
	
	update 	movie_history_weekend_prerun
	set 	certificate_group = @group_id
	where	movie_id = @movie_id and
			complex_id = @complex_id and
			screening_date = @screening_date and
			occurence = @occ

	select @error = @@error
	if ( @error !=0 )
	begin
		rollback transaction
		close movie_csr
		deallocate movie_csr
		return @error
	end	

	/*
	 * Fetch Next Movie
	 */

	fetch movie_csr into @movie_id, @short_name, @long_name, @occ, @premium_cinema, @show_category, @print_medium, @three_d_type, @movie_print_medium

end
close movie_csr
deallocate movie_csr



/*
 * Create Groups based on the Certificate Type
 */

if @certificate_type = 2
begin
		
	select @loop = 1
	
	while(@loop <= @movie_target)
	begin
	
		/*
		 * Get Certificate Group Id
		 */
		
		execute @errorode = p_get_sequence_number 'certificate_group_weekend',5,@group_id OUTPUT
		if (@errorode !=0)
		begin
			rollback transaction
			return -1
		end
		
		/*
		 * Get Group No
		 */
		
		select	 @group_no =  isnull(max(group_no),0) + 1
		from		certificate_group_weekend
		where	complex_id = @complex_id
		and			screening_date = @screening_date
		
		select @error = @@error
		if ( @error !=0 )
		begin
			rollback transaction
			return @error
		end	

		/*
		 * Setup Group Name
		 */
		
		select @group_name = 'Screening Group ' + convert(varchar(2),@loop)
		
		/*
		 * Create Certificate Group
		 */
		
		insert into certificate_group_weekend (
			certificate_group_id,
			complex_id,
			screening_date,
			group_no,
			group_short_name,
			group_name,
			is_movie,
			premium_cinema,
			show_category,
			print_medium,
			three_d_type,
			movie_print_medium ) values (
			@group_id,
			@complex_id,
			@screening_date,
			@group_no,
			@group_name,
			@group_name,
			'N',
			'N',
			'U',
			'F',
			1,
			'F')
		
		select @error = @@error
		
		if ( @error !=0 )
		begin
			rollback transaction
			return @error
		end	
		
		/*
		 * Update Loop Counter
		 */
		
		select @loop = @loop + 1
		
	end 
end
else if @certificate_type = 3
begin
		
	select @loop = 1
	
	while(@loop <= @movie_target)
	begin
	
		/*
		 * Get Certificate Group Id
		 */
		
		execute @errorode = p_get_sequence_number 'certificate_group_weekend',5,@group_id OUTPUT
		if (@errorode !=0)
		begin
			rollback transaction
			return -1
		end
		
		/*
		 * Get Group No
		 */
		
		select	 @group_no =  isnull(max(group_no),0) + 1
		from		certificate_group_weekend
		where	complex_id = @complex_id
		and			screening_date = @screening_date
		
		select @error = @@error
		if ( @error !=0 )
		begin
			rollback transaction
			return @error
		end	
		
		/*
		 * Setup Group Name
		 */
		
		select @group_name = 'Screening Group ' + convert(varchar(2),@loop)
		
		/*
		 * Create Certificate Group
		 */
		
		insert into certificate_group_weekend (
			certificate_group_id,
			complex_id,
			screening_date,
			group_no,
			group_short_name,
			group_name,
			is_movie,
			premium_cinema,
			show_category,
			print_medium,
			three_d_type,
			movie_print_medium ) values (
			@group_id,
			@complex_id,
			@screening_date,
			@group_no,
			@group_name,
			@group_name,
			'N',
			'N',
			'U',
			'D',
			1,
			'D')
		
		select @error = @@error
		
		if ( @error !=0 )
		begin
			rollback transaction
			return @error
		end	
		
		/*
		 * Update Loop Counter
		 */
		
		select @loop = @loop + 1
		
	end 
end

/*
 * Commit and Return
 */

commit transaction
return 0
GO
