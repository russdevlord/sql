/****** Object:  StoredProcedure [dbo].[p_spot_status_update]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_spot_status_update]
GO
/****** Object:  StoredProcedure [dbo].[p_spot_status_update]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_spot_status_update] @spot_id		integer,
                                 @new_status	char(1)
as

/*
 * Declare Procedure Variables
 */

declare			@error							integer,
					@rowcount					integer,
					@spot_type					char(1),
					@charge_rate 				decimal,
					@cert_score				integer,
					@spot_redirect			integer,
					@inclusion_count			int,
					@inclusion_id				int,
					@demo_id					int,
					@attendance				int,
					@complex_id				int,
					@screening_date			datetime,
					@spot_date					datetime, 
					@movie_id					int

select			@spot_type = spot_type,
					@charge_rate = charge_rate,
					@cert_score = certificate_score,
					@spot_redirect = spot_redirect,
					@complex_id = complex_id,
					@spot_date = screening_date
from				campaign_spot 
where			spot_id = @spot_id
 
 if @new_status <> 'U' and @spot_redirect is not null
 begin
    raiserror ('Cannot allocate spot as its unallocation has already been directed to a new allocated spot', 16, 1)
    return -100
  end

select			@inclusion_count = count(*)
from				inclusion_campaign_spot_xref
where			spot_id = @spot_id

if @inclusion_count > 0
begin
	select			@inclusion_id = inclusion_id
	from				inclusion_campaign_spot_xref
	where			spot_id = @spot_id

	select @error = @@error
	if ( @error !=0 )
	begin
		raiserror ('p_spot_status_update: could not get inclusion id', 16, 1)
		return @error
	end	

	select			@demo_id = cinetam_reporting_demographics_id
	from				inclusion_cinetam_master_target
	where			inclusion_id = @inclusion_id

	select @error = @@error
	if ( @error !=0 )
	begin
		raiserror ('p_spot_status_update: could not get demo id', 16, 1)
		return @error
	end	
end

/*
 * Begin Transaction
 */

begin transaction

/*
 * Update Spot
 */
if (@new_status = 'U')
begin
	if (@spot_type = 'Y')
	begin
		update campaign_spot
			set spot_status = @new_status,
				 spot_instruction = 'Manual Unallocation',
				onscreen = 'N'		
		 where spot_id = @spot_id
		
		select @error = @@error
		if ( @error !=0 )
		begin
			rollback transaction
			raiserror ('p_spot_status_update: Update Error', 16, 1)
			return @error
		end	

		update film_plan
			set current_spend = current_spend - @charge_rate
		 where film_plan_id = @cert_score
	
		select @error = @@error
		if (@error != 0)
		begin
			rollback transaction
			raiserror ('p_spot_status_update: Update Error(2)', 16, 1)
			return -1
		end	

	end
	else
	begin
		update campaign_spot
			set spot_status = @new_status,
				 certificate_score = 10,
				 spot_instruction = 'Manual Unallocation',
				onscreen = 'N'
		 where spot_id = @spot_id
		
		select @error = @@error
		if ( @error !=0 )
		begin
			rollback transaction
			raiserror ('p_spot_status_update: Update Error(3)', 16, 1)
			return -1
		end	
	end
end
else if (@new_status = 'X')
begin
	if (@spot_type = 'Y') 
	begin
		update campaign_spot
			set spot_status = @new_status,
				 spot_instruction = 'No Errors',
				onscreen = 'Y'
		 where spot_id = @spot_id
	
		select @error = @@error
		if ( @error !=0 )
		begin
			rollback transaction
			raiserror ('p_spot_status_update: Update Error(4)', 16, 1)
			return -1
		end	

		update film_plan
			set current_spend = current_spend + @charge_rate
		 where film_plan_id = @cert_score
	
		select @error = @@error
		if (@error != 0)
		begin
			rollback transaction
			raiserror ('p_spot_status_update: Update Error(5)', 16, 1)
			return -1
		end	
	end
	else
	begin
		update campaign_spot
			set spot_status = @new_status,
				 certificate_score = 0,
				 spot_instruction = 'No Errors',
				onscreen = 'Y'
		 where spot_id = @spot_id
	
		select @error = @@error
		if ( @error !=0 )
		begin
			rollback transaction
			raiserror ('p_spot_status_update: Update Error (6)', 16, 1)
			return -1
		end	
	end
end
else if @new_status = 'N'
begin

	update			campaign_spot
	set				spot_status = @new_status,
						certificate_score = 0,
						spot_instruction = 'No Errors'
	where			spot_id = @spot_id
	
	select @error = @@error
	if ( @error !=0 )
	begin
		rollback transaction
		raiserror ('p_spot_status_update: Update Error (6)', 16, 1)
		return -1
	end	

	if @inclusion_count > 0
	begin

		delete			inclusion_cinetam_complex_attendance
		where			inclusion_id = @inclusion_id
		and				screening_date = @screening_date

		delete			inclusion_cinetam_attendance
		where			inclusion_id = @inclusion_id
		and				screening_date = @screening_date

		insert into 	inclusion_cinetam_complex_attendance 
		select			inclusion_id,
							campaign_no,
							screening_date,
							complex_id,
							cinetam_reporting_demographics_id,
							movie_id,
							isnull(attendance,0) 
		from				v_inclusion_cinetam_complex_attendance 
		where			inclusion_id = @inclusion_id
		and				screening_date = @screening_date

		insert into 	inclusion_cinetam_attendance 
		select			inclusion_id,
							campaign_no,
							screening_date,
							cinetam_reporting_demographics_id,
							movie_id,
							isnull(attendance,0) 
		from				v_inclusion_cinetam_attendance 
		where			inclusion_id = @inclusion_id
		and				screening_date = @screening_date

		select			@attendance = cmce.attendance,
							@movie_id = cmce.movie_id
		from				v_certificate_item_distinct 
		inner join		movie_history on v_certificate_item_distinct.certificate_group = movie_history.certificate_group
		inner join		cinetam_movie_complex_estimates cmce on movie_history.complex_id = cmce.complex_id and movie_history.screening_date = cmce.screening_date and movie_history.movie_id = cmce.movie_id 
		where			spot_reference = @spot_id
		and				cinetam_reporting_demographics_id = @demo_id

		select @error = @@error
		if ( @error !=0 )
		begin
			rollback transaction
			raiserror ('p_spot_status_update: could not get attendance', 16, 1)
			return -1
		end	

		if @spot_type = 'F'
		begin
			select			@inclusion_count = count(*)
			from				inclusion_follow_film_targets
			where			complex_id = @complex_id
			and				processed = 'N'
			and				inclusion_id = @inclusion_id
			and				movie_id = @movie_id

			if @inclusion_count > 0
			begin
				select			@screening_date = min(screening_date)
				from				inclusion_follow_film_targets
				where			complex_id = @complex_id
				and				processed = 'N'
				and				inclusion_id = @inclusion_id
				and				movie_id = @movie_id

				update			inclusion_follow_film_targets
				set				target_attendance = target_attendance + @attendance
				where			complex_id = @complex_id
				and				processed = 'N'
				and				inclusion_id = @inclusion_id
				and				screening_date = @screening_date
				and				movie_id = @movie_id
			end
			else
			begin
				select			@inclusion_count = count(*)
				from				inclusion_follow_film_targets
				where			processed = 'N'
				and				inclusion_id = @inclusion_id
				and				movie_id = @movie_id

				if @inclusion_count > 0
				begin
					select			@screening_date = min(screening_date),
										@complex_id = min(complex_id)
					from				inclusion_follow_film_targets
					where			processed = 'N'
					and				inclusion_id = @inclusion_id
					and				movie_id = @movie_id

					update			inclusion_follow_film_targets
					set				target_attendance = target_attendance + @attendance
					where			complex_id = @complex_id
					and				processed = 'N'
					and				inclusion_id = @inclusion_id
					and				screening_date = @screening_date
					and				movie_id = @movie_id
				end
			end
		end
		else
		begin
			select			@inclusion_count = count(*)
			from				inclusion_cinetam_targets
			where			complex_id = @complex_id
			and				processed = 'N'
			and				inclusion_id = @inclusion_id

			if @inclusion_count > 0
			begin
				select			@screening_date = min(screening_date)
				from				inclusion_cinetam_targets
				where			complex_id = @complex_id
				and				processed = 'N'
				and				inclusion_id = @inclusion_id

				update			inclusion_cinetam_targets
				set				target_attendance = target_attendance + @attendance
				where			complex_id = @complex_id
				and				processed = 'N'
				and				inclusion_id = @inclusion_id
				and				screening_date = @screening_date

			end
			else
			begin
				select			@inclusion_count = count(*)
				from				inclusion_cinetam_targets
				where			processed = 'N'
				and				inclusion_id = @inclusion_id

				if @inclusion_count > 0
				begin
					select			@screening_date = min(screening_date),
										@complex_id = min(complex_id)
					from				inclusion_cinetam_targets
					where			processed = 'N'
					and				inclusion_id = @inclusion_id

					update			inclusion_cinetam_targets
					set				target_attendance = target_attendance + @attendance
					where			complex_id = @complex_id
					and				processed = 'N'
					and				inclusion_id = @inclusion_id
					and				screening_date = @screening_date
				end
			end
		end
	end
end
else
begin
	if (@spot_type = 'Y') 
	begin
		update campaign_spot
			set spot_status = @new_status,
				 spot_instruction = 'No Errors'
		 where spot_id = @spot_id
	
		select @error = @@error
		if ( @error !=0 )
		begin
			rollback transaction
			raiserror ('p_spot_status_update: Update Error(4)', 16, 1)
			return -1
		end	

		update film_plan
			set current_spend = current_spend + @charge_rate
		 where film_plan_id = @cert_score
	
		select @error = @@error
		if (@error != 0)
		begin
			rollback transaction
			raiserror ('p_spot_status_update: Update Error(5)', 16, 1)
			return -1
		end	
	end
	else
	begin
		update campaign_spot
			set spot_status = @new_status,
				 certificate_score = 0,
				 spot_instruction = 'No Errors'
		 where spot_id = @spot_id
	
		select @error = @@error
		if ( @error !=0 )
		begin
			rollback transaction
			raiserror ('p_spot_status_update: Update Error (6)', 16, 1)
			return -1
		end	
	end
end

commit transaction
return 0
GO
