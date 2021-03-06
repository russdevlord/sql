/****** Object:  StoredProcedure [dbo].[p_mycampaign_copy_and_submit_revision]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_mycampaign_copy_and_submit_revision]
GO
/****** Object:  StoredProcedure [dbo].[p_mycampaign_copy_and_submit_revision]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_mycampaign_copy_and_submit_revision]			@revision_no					int,
																														@package_id				int,
																														@screening_date			datetime
																												
as 

declare			@error								int,
						@campaign_no			int,
						@new_revision_no		int,
						@csr_revision_no		int,
						@csr_package_id		int,
						@rowcount						int

set nocount on

begin transaction

/*
 * Set Calling Revision to Submitted
*/
 
update	campaign_package_revision
set			revision_status_code = 'S'
where	revision_no = @revision_no
and			package_id = @package_id

select @error = @@error
if @error <> 0
begin
	raiserror ('Error updating package revision to submitted', 16, 1)
	rollback transaction
	return -1
end

select	@rowcount = count(*)
from		campaign_package_ins_rev
where	revision_no = @revision_no
and			package_id = @package_id

select	@rowcount = count(*)
from		campaign_package_ins_xref
where	revision_no = @revision_no
and			package_id = @package_id
and			screening_date = @screening_date

select @error = @@error
if @error <> 0
begin
	raiserror ('Error updating package revision to submitted', 16, 1)
	rollback transaction
	return -1
end

if @rowcount <> 0 
begin
	update	campaign_package_ins_xref
	set			revision_status_code = 'S'
	where	revision_no = @revision_no
	and			package_id = @package_id
	and			screening_date = @screening_date
	
	select @error = @@error
	if @error <> 0
	begin
		raiserror ('Error updating package revision to submitted', 16, 1)
		rollback transaction
		return -1
	end
end
else
begin
	insert into campaign_package_ins_xref
	(
	package_id,
	revision_no,
	screening_date,
	revision_status_code
	) values 
	(
	@package_id,
	@revision_no,
	@screening_date,
	'S'
	)
	
	select @error = @@error
	if @error <> 0
	begin
		raiserror ('Error updating package revision to submitted', 16, 1)
		rollback transaction
		return -1
	end
end

/*
 * Loop campaign packages that aren't the calling package
*/
 
declare		copy_revision_csr cursor for
select		package_id, 
					max(revision_no)
from			campaign_package_revision
where		package_id <> @package_id
and				package_id in (select package_id from campaign_package where campaign_no in (select campaign_no from campaign_package where package_id = @package_id))
group by	package_id
union
select		package_id, 
					0
from			campaign_package
where		package_id <> @package_id
and				package_id in (select package_id from campaign_package where campaign_no in (select campaign_no from campaign_package where package_id = @package_id))
and				package_id not in (select package_id from campaign_package_revision where campaign_no in (select campaign_no from campaign_package where package_id = @package_id))
group by	package_id
order by	package_id
					 
					
open		copy_revision_csr
fetch		copy_revision_csr into @csr_package_id, @csr_revision_no
while(@@fetch_status = 0)
begin

	--insert campaign_package_revision
	insert into campaign_package_revision
	(
	revision_no,
	package_id,
	revision_date,
	revision_status_code,
	current_revision,
	decision_maker,
	decision_date,
	requestor,
	last_reviewed_date,
	last_reviewed_by,
	revision_comment
	)
	select 	@csr_revision_no + 1,
					@csr_package_id,
					revision_date,
					revision_status_code,
					current_revision,
					decision_maker,
					decision_date,
					requestor,
					last_reviewed_date,
					last_reviewed_by,
					revision_comment
	from 		campaign_package_revision
	where	package_id = @package_id
	and			revision_no = @revision_no			
	
	select @error = @@error
	if @error <> 0
	begin
		rollback transaction
		raiserror ('Error: copying campaign_package_revision ', 16, 1)
		return -1
	end
	
	--insert campaign_package_ins_rev
	insert into campaign_package_ins_rev
	(
	revision_no,
	package_id,
	screening_position,
    screening_trailers,
    school_holidays,
    follow_film,
    movie_mix,
    movie_bands,
    movie_band_variable,
    certificate_priority,
    client_clash,
    movie_brief,
    ins_complete,
    allow_product_clashing,
    follow_film_restricted,
    client_diff_product,
    premium_screen_type,
    all_movies,
    cinema_exclusive,
    allow_3d,
    dimension_preference,
    allow_subcategory_clashing 
	)
	select 	@csr_revision_no + 1,
					@csr_package_id,
					screening_position,
					screening_trailers,
					school_holidays,
					follow_film,
					movie_mix,
					movie_bands,
					movie_band_variable,
					certificate_priority,
					client_clash,
					movie_brief,
					ins_complete,
					allow_product_clashing,
					follow_film_restricted,
					client_diff_product,
					premium_screen_type,
					all_movies,
					cinema_exclusive,
					allow_3d,
					dimension_preference,
					allow_subcategory_clashing 
	from 		campaign_package_ins_rev
	where	package_id = @package_id
	and			revision_no = @revision_no			
	
	select @error = @@error
	if @error <> 0
	begin
		rollback transaction
		raiserror ('Error: copying campaign_package_ins_rev ', 16, 1)
		return -1
	end

--insert campaign_classification_rev
	insert into campaign_classification_rev
	(
	revision_no,
	classification_id,
	package_id,
	instruction_type
	)
	select 	@csr_revision_no + 1,
					classification_id,
					@csr_package_id,
					instruction_type
	from 		campaign_classification_rev
	where	package_id = @package_id
	and			revision_no = @revision_no			
	
	select @error = @@error
	if @error <> 0
	begin
		rollback transaction
		raiserror ('Error: copying campaign_classification_rev ', 16, 1)
		return -1
	end
	
	
	--insert campaign_category_rev
	insert into campaign_category_rev
	(
	revision_no,
	movie_category_code,
	package_id, 
	instruction_type
	)
	select 	@csr_revision_no + 1,
					movie_category_code,
					@csr_package_id,
					instruction_type
	from 		campaign_category_rev
	where	package_id = @package_id
	and			revision_no = @revision_no			
	
	select @error = @@error
	if @error <> 0
	begin
		rollback transaction
		raiserror ('Error: copying campaign_category_rev ', 16, 1)
		return -1
	end
	
	--insert campaign_audience_rev
	insert into campaign_audience_rev
	(
	revision_no,
	audience_profile_code,
	package_id,
	instruction_type
	)
	select 	@csr_revision_no + 1,
					audience_profile_code,
					@csr_package_id,
					instruction_type
	from 		campaign_audience_rev
	where	package_id = @package_id
	and			revision_no = @revision_no			
	
	select @error = @@error
	if @error <> 0
	begin
		rollback transaction
		raiserror ('Error: copying campaign_audience_rev ', 16, 1)
		return -1
	end
	
		--insert movie_screening_ins_rev
	insert into movie_screening_ins_rev
	(
	revision_no,
	movie_id,
	package_id,
	instruction_type,
	sequence_no
	)
	select 	@csr_revision_no + 1,
					movie_id,
					@csr_package_id,
					instruction_type,
					sequence_no
	from 		movie_screening_ins_rev
	where	package_id = @package_id
	and			revision_no = @revision_no			
	
	select @error = @@error
	if @error <> 0
	begin
		rollback transaction
		raiserror ('Error: copying movie_screening_ins_rev ', 16, 1)
		return -1
	end
	
	update campaign_package_ins_xref
	set revision_status_code = 'D'
	where revision_status_code = 'S' 
	and			revision_no = @csr_revision_no
	and			package_id = @csr_package_id
	and			screening_date = @screening_date
	
	select @error = @@error
	if @error <> 0
	begin
		raiserror ('Error updating package revision to submitted', 16, 1)
		rollback transaction
		return -1
	end
		
		
	insert into campaign_package_ins_xref
	(
	package_id,
	revision_no,
	screening_date,
	revision_status_code
	) values 
	(
	@csr_package_id,
	@csr_revision_no + 1,
	@screening_date,
	'S'
	)
	
	select @error = @@error
	if @error <> 0
	begin
		raiserror ('Error updating package revision to submitted', 16, 1)
		rollback transaction
		return -1
	end
		
	fetch		copy_revision_csr into @csr_package_id, @csr_revision_no
end


commit transaction
return 0
GO
