/****** Object:  StoredProcedure [dbo].[p_delete_certificate_print_exhibitor]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_delete_certificate_print_exhibitor]
GO
/****** Object:  StoredProcedure [dbo].[p_delete_certificate_print_exhibitor]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[p_delete_certificate_print_exhibitor]		@screening_date				datetime,
																@print_id					int,
																@exhibitor_id				int
as

declare			@error 										int,
				@seq_no										int,
				@certificate_group_id						int,
				@rowcount									int,
				@spot_reference								int,
				@audience_spot								int,
				@inclusion_id								int,
				@cinetam_reporting_demographics_id			int,
				@inclusion_type								int,
				@attendance_estimate						int,
				@movie_id									int,
				@complex_id									int,
				@spot_id									int,
				@no_movies									int,
				@print_medium								char(1),
				@three_d_type								int
				
set nocount on

begin transaction

declare		group_csr cursor forward_only static for
select    	distinct certificate_group_id,
			cg.complex_id,
			spot_reference
from		certificate_group cg
inner join	certificate_item on cg.certificate_group_id = certificate_item.certificate_group
inner join	complex on cg.complex_id = complex.complex_id
where		cg.screening_date = @screening_date
and			print_id = @print_id
and			complex.exhibitor_id = @exhibitor_id
group by	certificate_group_id,
			cg.complex_id,
			spot_reference
order by	certificate_group_id
for			read only


open group_csr
fetch group_csr into @certificate_group_id, @complex_id, @spot_id
while(@@fetch_status=0)
begin

	select			@audience_spot = count(spot_id)
	from			inclusion_campaign_spot_xref
	inner join		certificate_item on inclusion_campaign_spot_xref.spot_id = certificate_item.spot_reference
	where			certificate_group = @certificate_group_id
	and				print_id = @print_id

	if @audience_spot > 0
	begin
		select			@inclusion_id = inclusion.inclusion_id,
						@cinetam_reporting_demographics_id = cinetam_reporting_demographics_id,
						@inclusion_type = inclusion.inclusion_type
		from			inclusion_campaign_spot_xref
		inner join		certificate_item on inclusion_campaign_spot_xref.spot_id = certificate_item.spot_reference
		inner join		inclusion on inclusion_campaign_spot_xref.inclusion_id = inclusion.inclusion_id
		left outer join	inclusion_cinetam_master_target on inclusion.inclusion_id = inclusion_cinetam_master_target.inclusion_id
		where			certificate_group = @certificate_group_id
		and				print_id = @print_id

		select  @error = @@error,
				@rowcount = @@rowcount
    
		if @error <> 0 or @rowcount = 0
		begin
			raiserror ('Error - failed to find inclusion_id and demo', 16, 1)
			rollback transaction
			return -100
		end

		if @inclusion_type = 29 or @inclusion_type = 24 or @inclusion_type = 32 --FAP, MAP & TAP
		begin
			select			@attendance_estimate = cmce.attendance,
							@movie_id = cmce.movie_id,
							@print_medium = movie_history.print_medium,
							@three_d_type = movie_history.three_d_type
			from			cinetam_movie_complex_estimates cmce
			inner join		movie_history on cmce.complex_id = movie_history.complex_id
			and				cmce.screening_date = movie_history.screening_date
			and				cmce.movie_id = movie_history.movie_id
			where			certificate_group = @certificate_group_id
			and				cmce.cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id

			select  @error = @@error,
					@rowcount = @@rowcount
    
			if @error <> 0 or @rowcount = 0
			begin
				raiserror ('Error - failed to find estimate for allocation reduction', 16, 1)
				rollback transaction
				return -100
			end

			select			@no_movies = count(*)
			from			movie_history
			where			screening_date = @screening_date
			and				movie_id = @movie_id
			and				complex_id = @complex_id
			and				print_medium = @print_medium
			and				three_d_type = @three_d_type

			select  @error = @@error,
					@rowcount = @@rowcount
    
			if @error <> 0 or @rowcount = 0
			begin
				raiserror ('Error - failed to find estimate for allocation reduction', 16, 1)
				rollback transaction
				return -100
			end

			if @no_movies = 0 
			begin
				select			@no_movies = 1
			end

			if @inclusion_type = 29
			begin
				update			inclusion_follow_film_targets
				set				achieved_attendance = achieved_attendance - (@attendance_estimate / @no_movies)
				where			inclusion_id = @inclusion_id
				and				complex_id = @complex_id
				and				screening_date = @screening_date
				and				movie_id = @movie_id

				select  @error = @@error,
						@rowcount = @@rowcount
    
				if @error <> 0 or @rowcount = 0
				begin
					raiserror ('Error - failed to find seq no', 16, 1)
					rollback transaction
					return -100
				end
			end
			else
			begin
				update			inclusion_cinetam_targets
				set				achieved_attendance = achieved_attendance - (@attendance_estimate / @no_movies)
				where			inclusion_id = @inclusion_id
				and				complex_id = @complex_id
				and				screening_date = @screening_date

				select  @error = @@error,
						@rowcount = @@rowcount
    
				if @error <> 0 or @rowcount = 0
				begin
					raiserror ('Error - failed to find seq no', 16, 1)
					rollback transaction
					return -100
				end
			end
		end
	end
	else
	begin
		update			campaign_spot
		set				spot_status = 'U'
		from			certificate_item
		where			certificate_item.certificate_group = @certificate_group_id 
		and				print_id = @print_id 
		and				spot_id = spot_reference
	
		select  @error = @@error
    
		if @error <> 0 
		begin
			raiserror ('Error - failed to update spot', 16, 1)
			rollback transaction
			return -100
		end	
	end

	select			@seq_no = min(sequence_no)
	from			certificate_item
	where 			certificate_item.certificate_group = @certificate_group_id 
	and				print_id = @print_id
	
    select  @error = @@error,
            @rowcount = @@rowcount
    
    if @error <> 0 or @rowcount = 0
    begin
        raiserror ('Error - failed to find seq no', 16, 1)
        rollback transaction
        return -100
    end
    
    update			certificate_item
    set				sequence_no = sequence_no - 1
    where			certificate_item.certificate_group = @certificate_group_id 
    and				sequence_no > @seq_no
    
    select		@error = @@error,
				@rowcount = @@rowcount
    
    if @error <> 0 /*or @rowcount = 0*/
    begin
        raiserror ('Error - failed to update subsequent sequence numbers', 16, 1)
        rollback transaction
        return -100
    end
    
    delete      certificate_item
    where       certificate_item.certificate_group = @certificate_group_id 
	and			print_id = @print_id 
        
    select  @error = @@error,
            @rowcount = @@rowcount
    
    if @error <> 0 or @rowcount = 0
    begin
        raiserror ('Error - failed to delete cert item', 16, 1)
        rollback transaction
        return -100
    end


	if @audience_spot > 0
	begin

		delete			inclusion_campaign_spot_xref
		where			spot_id = @spot_id

		select  @error = @@error,
				@rowcount = @@rowcount
    
		if @error <> 0 or @rowcount = 0
		begin
			raiserror ('Error - failed to delete ', 16, 1)
			rollback transaction
			return -100
		end


		delete			campaign_spot
		where			spot_id = @spot_id

		select  @error = @@error,
				@rowcount = @@rowcount
    
		if @error <> 0 or @rowcount = 0
		begin
			raiserror ('Error - failed to find inclusion_id and demo', 16, 1)
			rollback transaction
			return -100
		end
	end
		
	fetch group_csr into @certificate_group_id, @complex_id, @spot_id
end

deallocate group_csr


commit transaction
return 0
GO
