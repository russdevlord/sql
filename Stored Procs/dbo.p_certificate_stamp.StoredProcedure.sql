/****** Object:  StoredProcedure [dbo].[p_certificate_stamp]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_certificate_stamp]
GO
/****** Object:  StoredProcedure [dbo].[p_certificate_stamp]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO







CREATE PROC [dbo].[p_certificate_stamp]		@complex_id			int,
											@screening_date		datetime,
											@user          		char(30),
											@status				char(1)
as

declare			@error     						int,
				@sent_revision				    smallint,
				@new_revision					smallint,
				@cert_grp_store					int,
				@seq_no							int,
				@cert_grp						int,
				@cert_item_id					int,
				@print_id						int,
				@trailer_seq					int,
				@3d								int,
				@premium						int,
				@cert_group_id					int,
				@sequence_no					int,
				@local_count					int,
				@insider_count				    int,
				@insider_first					int,
				@insider_last					int,
				@first_seq						int,
				@last_seq						int,
				@2nd_insider_count				int,
				@2nd_insider_first	            int,
				@2nd_insider_last	            int,
				@2nd_first_seq		            int,
				@2nd_last_seq		            int,
				@moonlight						int,
				@certificate_group_id			int,
				@certificate_item_id			int,
				@state_code						char(2),
				@3d_print_id					int,
				@3d_cutdown						int,
				@original_print_id				int,
				@print_row						int,
				@medium_count					int,
				@threed_count					int,
				@item_threed					int,
				@substitution_print_id			int,
				@item_medium					char(1),
				@print_package_id				int,
				@spot_id						int,
				@exhibitor_id					int,
				@premium_cinema					char(1),
				@tms_yes						int,
				@cineads_id						int
			
			

set nocount on

create table #spots_to_delete
(
	spot_id			int			not null
)

/*
 * Get Revision Numbers
 */

select 			@sent_revision = IsNull(max(revision),-1)
from 			certificate_history
where			complex_id = @complex_id 
and				screening_date = @screening_date

select			@exhibitor_id = exhibitor_id
from			complex
where			complex_id =  @complex_id

select			@tms_yes = count(*)
from			complex_ftp_path
where			complex_id = @complex_id

select			@cineads_id = ident_id
from			complex_screen_scheduling_xref	
where			complex_id = @complex_id

/*
 * Calculate New revision

 */

select @new_revision = @sent_revision + 1

select  @state_code = state_code
from    complex 
where   complex_id = @complex_id

/*
 * Get Insider Shell Prints
 */
/*
select 	@first_seq = min(sequence_no)
from 	film_shell_print
where	shell_code = 'FSA0265'

select 	@last_seq = max(sequence_no)
from 	film_shell_print
where	shell_code = 'FSA0265'

select 	@insider_first = print_id
from 	film_shell_print
where	shell_code = 'FSA0265'
and		sequence_no = @first_seq

select 	@insider_last = print_id
from 	film_shell_print
where	shell_code = 'FSA0265'
and		sequence_no = @last_seq

select 	@2nd_first_seq = min(sequence_no)
from 	film_shell_print
where	shell_code = 'FSA0309'

select 	@2nd_last_seq = max(sequence_no)
from 	film_shell_print
where	shell_code = 'FSA0309'

select 	@2nd_insider_first = print_id
from 	film_shell_print
where	shell_code = 'FSA0309'
and		sequence_no = @first_seq

select 	@2nd_insider_last = print_id
from 	film_shell_print
where	shell_code = 'FSA0309'
and		sequence_no = @last_seq
*/

/*
 * Begin Transaction
 */

begin transaction

/*
 * Set the Certificate Generation and Revision
 */

update complex_date 
   set certificate_generation = getdate(),
       certificate_revision = @new_revision,
       certificate_generation_user = @user,
       certificate_status = @status
 where complex_id = @complex_id and
       screening_date = @screening_date

select @error = @@error
if (@error != 0)
begin
	rollback transaction
	raiserror ('Error', 16, 1 ) 
   return -1
end	

declare 	cert_group_csr cursor forward_only for
select		cg.certificate_group_id
from		certificate_group cg
where 		cg.screening_date = @screening_date
and			cg.complex_id = @complex_id
group by	cg.certificate_group_id
order by	cg.certificate_group_id
for 		read only

open cert_group_csr
fetch cert_group_csr into @cert_group_id
while(@@fetch_status = 0)
begin
	
	select 		@insider_count = 0,
				@2nd_insider_count = 0,
				@local_count = 0,
				@moonlight = 0
					
	select		@premium_cinema  = premium_cinema					
	from		certificate_group
	where 		certificate_group_id = @cert_group_id
	
	if (@exhibitor_id = 205 or @exhibitor_id = 191) and @premium_cinema = 'Y'
	begin
		delete certificate_item
		where certificate_group = @cert_group_id
		and print_id in (6,21616, 21617, 21618, 21619, 21620, 21621, 40504 )

		declare		cert_item_csr cursor forward_only for
		select			ci.certificate_item_id
		from			certificate_item ci
		where 			ci.certificate_group = @cert_group_id 
		order by		ci.sequence_no
		for 				read only
		
		select 	@seq_no = 0
		
		open cert_item_csr
		fetch cert_item_csr into @cert_item_id
		while(@@fetch_status=0)
		begin
			select 	@seq_no = @seq_no + 1
		
			update 	certificate_item
			set 	sequence_no = @seq_no
			where	certificate_item_id = @cert_item_id
		
			select @error = @@error
			if (@error != 0)
			begin
				rollback transaction
				raiserror ('Error updating seq nos', 16, 1 ) 
			   	return -1
			end	
		
			fetch cert_item_csr into @cert_item_id
		end
		
		deallocate cert_item_csr

	end
/*	
	select		@moonlight = count(certificate_item_id)
	from		certificate_item ci
	where 		ci.certificate_group = @cert_group_id
	and			print_id = 14798

	if @moonlight > 0 
	begin
		delete certificate_item
		where certificate_group = @cert_group_id
		and print_id in (1,10, 11, 12)
	end	
	
	select 		@insider_count = count(certificate_item_id)
	from		certificate_item ci
	where 		ci.certificate_group = @cert_group_id
	and			(print_id = @insider_first 
	or			print_id = @insider_last)
	
	select 		@2nd_insider_count = count(certificate_item_id)
	from		certificate_item ci
	where 		ci.certificate_group = @cert_group_id
	and			(print_id = @2nd_insider_first 
	or			print_id = @2nd_insider_last)

	select 		@local_count = isnull(count(certificate_item_id),0)
	from		certificate_item ci
	where 		ci.certificate_group = @cert_group_id
	and			(print_id = 9)

	if (@insider_count > 0 or @2nd_insider_count > 0) and @local_count = 0
	begin

		update 	certificate_item
		set 	sequence_no = sequence_no + 5
		where	certificate_group = @cert_group_id

		select @error = @@error
		if (@error != 0)
		begin
			rollback transaction
			raiserror ('Error', 16, 1 ) 'Error updating seq nos'
			return -1
		end	

		execute @error = p_get_sequence_number 'certificate_item',5,@sequence_no OUTPUT
		if (@error !=0)
		begin
			rollback transaction
			return -1
		end

		insert into certificate_item (
		certificate_item_id,
		certificate_group,
		print_id,
		sequence_no,
		item_comment,
		spot_reference,
		item_show,
		certificate_auto_create,
		certificate_source,
		print_medium,
		three_d_type,
		campaign_summary,
		premium_cinema)
		values 	(
		@sequence_no,
		@cert_group_id,
		9,
		2,
		'',
		null,
		'Y',
		'Y',
		'S',
		'D',
		1,
		'',
		'N'
		)
			
		select @error = @@error
		if (@error != 0)
		begin
			rollback transaction
			raiserror ('Error', 16, 1 ) 'Error updating seq nos'
		   	return -1
		end	

		update 	certificate_item
		set 			sequence_no = 1
		where		certificate_group = @cert_group_id
		and			print_id = @insider_first
	
		select @error = @@error
		if (@error != 0)
		begin
			rollback transaction
			raiserror ('Error', 16, 1 ) 'Error updating seq nos'
		   	return -1
		end	

		update 	certificate_item
		set 	sequence_no = 1
		where	certificate_group = @cert_group_id
		and		print_id = @2nd_insider_first
	
		select @error = @@error
		if (@error != 0)
		begin
			rollback transaction
			raiserror ('Error', 16, 1 ) 'Error updating seq nos'
		   	return -1
		end	

		update 	certificate_item
		set 	sequence_no = 3
		where	certificate_group = @cert_group_id
		and		print_id = 1
	
		select @error = @@error
		if (@error != 0)
		begin
			rollback transaction
			raiserror ('Error', 16, 1 ) 'Error updating seq nos'
		   	return -1
		end	

		update 	certificate_item
		set 	sequence_no = 2
		where	certificate_group = @cert_group_id
		and		print_id = 9
	
		select @error = @@error
		if (@error != 0)
		begin
			rollback transaction
			raiserror ('Error', 16, 1 ) 'Error updating seq nos'
		   	return -1
		end	

		update 	certificate_item
		set		sequence_no = 190
		where	certificate_group = @cert_group_id
		and		print_id = @insider_last
	
		select @error = @@error
		if (@error != 0)
		begin
			rollback transaction
			raiserror ('Error', 16, 1 ) 'Error updating seq nos'
		   	return -1
		end	

		update 	certificate_item
		set		sequence_no = 190
		where	certificate_group = @cert_group_id
		and		print_id = @2nd_insider_last
	
		select @error = @@error
		if (@error != 0)
		begin
			rollback transaction
			raiserror ('Error', 16, 1 ) 'Error updating seq nos'
		   	return -1
		end	

		update 	certificate_item
		set 	sequence_no = 200
		where	certificate_group = @cert_group_id
		and		print_id = 6
	
		select @error = @@error
		if (@error != 0)
		begin
			rollback transaction
			raiserror ('Error', 16, 1 ) 'Error updating seq nos'
		   	return -1
		end	

		update 	certificate_item
		set 	sequence_no = 200
		where	certificate_group = @cert_group_id
		and		print_id = 13696
	
		select @error = @@error
		if (@error != 0)
		begin
			rollback transaction
			raiserror ('Error', 16, 1 ) 'Error updating seq nos'
		   	return -1
		end	

		update 	certificate_item
		set 	sequence_no = 210
		where	certificate_group = @cert_group_id
		and		print_id = 3
	
		select @error = @@error
		if (@error != 0)
		begin
			rollback transaction
			raiserror ('Error', 16, 1 ) 'Error updating seq nos'
		   	return -1
		end	
		*/

		declare	cert_item_csr cursor forward_only for
		select		ci.certificate_item_id
		from			certificate_item ci
		where 		ci.certificate_group = @cert_group_id 
		order by		ci.sequence_no
		for 				read only
		
		select 	@seq_no = 0
		
		open cert_item_csr
		fetch cert_item_csr into @cert_item_id
		while(@@fetch_status=0)
		begin
			select 	@seq_no = @seq_no + 1
		
			update 	certificate_item
			set 	sequence_no = @seq_no
			where	certificate_item_id = @cert_item_id
		
			select @error = @@error
			if (@error != 0)
			begin
				rollback transaction
				raiserror ('Error updating seq nos', 16, 1 ) 
			   	return -1
			end	
		
			fetch cert_item_csr into @cert_item_id
		end
		
		deallocate cert_item_csr

	--end
	fetch cert_group_csr into @cert_group_id

end

update 			certificate_item
set 			print_id = 40504 
from			certificate_group cg
where 			certificate_item.certificate_group = cg.certificate_group_id 
and				cg.screening_date = @screening_date
and				certificate_item.print_id in (1, 10)
and 			cg.print_medium = 'D'
and				cg.complex_id = @complex_id

select @error = @@error
if (@error != 0)
begin
	rollback transaction
	raiserror ('Error', 16, 1 ) 
	return -1
end	

/*
 * Update to CINEads tag for appropriate movies
 */

update			certificate_item
set 			print_id = @cineads_id
from			certificate_group cg
where 			certificate_item.certificate_group = cg.certificate_group_id 
and				cg.screening_date = @screening_date
and				certificate_item.print_id in (18)
and 			cg.print_medium = 'D'
and				cg.complex_id = @complex_id

select @error = @@error
if (@error != 0)
begin
	rollback transaction
	raiserror ('Error', 16, 1 ) 
	return -1
end	

insert into certificate_prints
select 		distinct ci.print_id,
			cg.complex_id,
			cg.screening_date
from		certificate_group cg,
			certificate_item ci
where 		ci.certificate_group = cg.certificate_group_id 
and			cg.screening_date = @screening_date
and			cg.complex_id = @complex_id
and			ci.print_id not in (select print_id from certificate_prints where complex_id = @complex_id) 
group by	ci.print_id,
			cg.complex_id,
			cg.screening_date

select @error = @@error
if (@error != 0)
begin
	rollback transaction
	raiserror ('Error', 16, 1 ) 
   return -1
end	

/*
 * Change over tag substitution prints
 */
 
declare		print_substitution_csr cursor for 
select			original_print_id,
					substitution_print_id,
					film_campaign_print_substitution.print_package_id,
					spot_id
from			film_campaign_print_substitution,
					print_package,
					campaign_spot
where			campaign_spot.package_id = print_package.package_id
and				campaign_spot.complex_id = film_campaign_print_substitution.complex_id
and				print_package.print_package_id = film_campaign_print_substitution.print_package_id
and				print_package.print_id = film_campaign_print_substitution.original_print_id
and				campaign_spot.complex_id = @complex_id
and				campaign_spot.screening_date = @screening_date
order by		spot_id, 
					original_print_id
for			read only			

open print_substitution_csr
fetch print_substitution_csr into @original_print_id, @substitution_print_id, @print_package_id, @spot_id
while(@@fetch_status = 0)
begin

	select		@item_medium = print_medium,
					@item_threed = three_d_type
	from		certificate_item
	where		spot_reference = @spot_id
	and			print_id = @original_print_id
	
	select	@error = @@error,
			@print_row = @@rowcount
			
	if @error <> 0
	begin
		rollback transaction
		raiserror ('Error: Failed to find subsitution row', 16, 1)
		return -1 
	end
	
	select		@medium_count = count(*)
	from		film_campaign_print_sub_medium
	where		original_print_id = @original_print_id
	and			substitution_print_id = @substitution_print_id
	and			print_package_id = @print_package_id
	and			complex_id = @complex_id
	and			print_medium = @item_medium
	
	select @error = @@error 
	if @error <> 0
	begin
		rollback transaction
		raiserror ('Error: Failed to find subsitution medium', 16, 1)
		return -1 
	end

	select		@threed_count = count(*)
	from		film_campaign_print_sub_threed
	where		original_print_id = @original_print_id
	and			substitution_print_id = @substitution_print_id
	and			print_package_id = @print_package_id
	and			complex_id = @complex_id
	and			three_d_type = @item_threed
	
	select @error = @@error 
	if @error <> 0
	begin
		rollback transaction
		raiserror ('Error: Failed to find subsitution dimension', 16, 1)
		return -1 
	end	

	if @threed_count = 0 and @item_threed > 1
	begin
		select		@item_threed = 1
	
		select		@threed_count = count(*)
		from		film_campaign_print_sub_threed
		where		original_print_id = @original_print_id
		and			substitution_print_id = @substitution_print_id
		and			print_package_id = @print_package_id
		and			complex_id = @complex_id
		and			three_d_type = @item_threed
		
		select @error = @@error 
		if @error <> 0
		begin
			rollback transaction
			raiserror ('Error: Failed to find subsitution dimension', 16, 1)
			return -1 
		end		
	end
	
	if @print_row > 0 and @medium_count = 1 and @threed_count = 1
	begin
	
		update		certificate_item
		set			print_id = @substitution_print_id,
					three_d_type = @item_threed,
					print_medium = @item_medium
		where		spot_reference = @spot_id
		and			print_id = @original_print_id	
		
		select @error = @@error 
		if @error <> 0
		begin
			rollback transaction
			raiserror ('Error: Failed to find subsitution dimension', 16, 1)
			return -1 
		end				
	end

	fetch print_substitution_csr into @original_print_id, @substitution_print_id, @print_package_id, @spot_id
end 


/*
 * Update pre-existing competitor campaigns that are scheduled to count towards avails/booking levels etc so that they are not shown on the certificates
 */

/*update		certificate_item
set			item_show = 'N'
where		print_id in (32271, 32348, 32284, 32332, 32347, 32349, 32333, 32334, 32336, 32338, 32335, 32289, 32286, 32293, 32283, 32272, 32327, 32297, 32281, 32326, 32287, 32284, 32285, 32298, 32295, 32290, 32280, 32276, 32278, 32277, 32296, 32282, 32288, 32275, 32324, 32273, 32291, 32323, 32294, 32292, 32329, 32328)


select @error = @@error 
if @error <> 0
begin
	rollback transaction
	raiserror 50050 'Error: Failed to updaet '
	return -1 
end				
*/
/*
 * Update sequence numbers for  pre-existing competitor campaigns that are scheduled to count towards avails/booking levels etc so that they do not appear to skip
 */

--NA for now.

/*
 * Delete Unallocated Schedule Created Spots
 */

delete		inclusion_campaign_spot_xref
where		spot_id in (	select		spot_id 
							from			campaign_spot
							where			complex_id = @complex_id 
							and				screening_date = @screening_date 
							and				schedule_auto_create in ('C', 'S')
							and				spot_status <> 'X'
							and				spot_id not in (select spot_id from film_spot_xref)
							and				(spot_type = 'M' 
							or				spot_type = 'Y' 
							or				spot_type = 'G' 
							or				spot_type = 'F' 
							or				spot_type = 'K'
							or				spot_type = 'T' 
							or				spot_type = 'A') )

select @error = @@error
if (@error != 0)
begin
	rollback transaction
	raiserror ('Error', 16, 1 ) 
   return -1
end	

insert into		#spots_to_delete
select			spot_id
from			campaign_spot
where			spot_status <> 'X'
and				spot_type = 'M'
and				complex_id = @complex_id
and				screening_date = @screening_date

select @error = @@error 
if @error <> 0
begin
	rollback transaction
	raiserror ('Error: Failed to delete makeup spots that were not allocated ', 16, 1)
	return -1 
end		

insert into		#spots_to_delete
select			spot_id
from			campaign_spot
where			complex_id = @complex_id 
and				screening_date = @screening_date 
and				schedule_auto_create in ('C', 'S')
and				spot_status <> 'X' 
and				spot_status <> 'P'
and				spot_id not in (select spot_id from film_spot_xref) 
and				(spot_type = 'M' 
or				spot_type = 'Y' 
or				spot_type = 'G')

select @error = @@error
if (@error != 0)
begin
	rollback transaction
	raiserror ('Error', 16, 1 ) 
   return -1
end		

insert into		#spots_to_delete
select			spot_id
from			campaign_spot
where			complex_id = @complex_id
and				screening_date = @screening_date
and				spot_status <> 'X'
and				spot_type in ('A', 'F', 'K', 'T')

select @error = @@error
if (@error != 0)
begin
	rollback transaction
	raiserror ('Error', 16, 1 ) 
   return -1
end		

insert into		#spots_to_delete
select			spot_id
from			campaign_spot,
				campaign_package
where			campaign_spot.package_id = campaign_package.package_id
and				complex_id = @complex_id 
and				screening_date = @screening_date 
and				spot_status <> 'X' 
and				spot_status <> 'P'
and				spot_type = 'W' 
and				all_movies = 'A'
and				premium_screen_type <> 'N'

select @error = @@error
if (@error != 0)
begin
	rollback transaction
	raiserror ('Error', 16, 1 ) 
   return -1
end		

delete			campaign_spot
from			#spots_to_delete
where			campaign_spot.spot_id = #spots_to_delete.spot_id
and				campaign_spot.complex_id = @complex_id
and				campaign_spot.screening_date = @screening_date

select @error = @@error 
if @error <> 0
begin
	rollback transaction
	raiserror ('Error: Failed to delete spots that were not allocated.', 16, 1)
	return -1 
end	

/*
 * Update Audience Targets to say they are processed
 */

update				inclusion_follow_film_targets 
set					processed = 'Y' 
where				complex_id = @complex_id
and					screening_date = @screening_date

select @error = @@error
if (@error != 0)
begin
	rollback transaction
	raiserror ('Error', 16, 1 ) 
   return -1
end	

update				inclusion_cinetam_targets 
set					processed = 'Y' 
where				complex_id = @complex_id
and					screening_date = @screening_date

select @error = @@error
if (@error != 0)
begin
	rollback transaction
	raiserror ('Error', 16, 1 ) 
   return -1
end	

--Moving Coke Cola
if @tms_yes > 0
begin
	update	certificate_item_tms_section_xref
	set		section_position = 2
	where	certificate_item_id in (select			certificate_item_id 
													from				certificate_item 
													inner join		campaign_spot on certificate_item.spot_reference = campaign_spot.spot_id
													inner join		film_campaign on campaign_spot.campaign_no = film_campaign.campaign_no
													where			complex_id = @complex_id
													and				screening_date = @screening_date
													and				client_id in (50553,50554,57290))		

	select @error = @@error
	if (@error != 0)
	begin
		rollback transaction
		raiserror ('Error', 16, 1 ) 
	   return -1
	end	
end

/*
 * Commit and Return
 */

commit transaction
return 0
GO
