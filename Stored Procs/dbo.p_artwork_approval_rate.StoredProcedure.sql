/****** Object:  StoredProcedure [dbo].[p_artwork_approval_rate]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_artwork_approval_rate]
GO
/****** Object:  StoredProcedure [dbo].[p_artwork_approval_rate]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_artwork_approval_rate]	@branch_code		char(1),
                                    @start_date			datetime,
												@end_date			datetime,
     											@exclude_term		char(1)

as

declare  @rep_id			integer,
			@campaign_no	char(7),
			@job_id			integer,
		   @app_ok 			integer,
		   @app_alters		integer,
		   @rejected		integer,
		   @major_alt		integer,
		   @minor_alt		integer,
         @artwork_id		integer,
         @version_no		integer,
         @step_outcome  char(1),
         @step_type		integer,
         @approval_status char(1)



create table #results
(
	rep_id		integer		null,
	campaign_no	char(7)		null,
	job_id		integer		null,
   app_ok 		integer 		null,
   app_alters	integer		null,
   rejected		integer		null,
   major_alt	integer		null,
   minor_alt	integer		null
)


declare camp_csr cursor static for
  select campaign_no, slide_proposal.rep_id
    from slide_proposal,
         sales_rep
   where sales_rep.rep_id = slide_proposal.rep_id and
         (sales_rep.branch_code = @branch_code or @branch_code = '@') and
			(sales_rep.status = 'A' or @exclude_term = 'N') and
         slide_proposal.campaign_no is not null and
         exists ( select 1
                    from npu_job,
                         npu_request
					    where npu_request.request_no = npu_job.request_no and
								 npu_request.campaign_no = slide_proposal.campaign_no and
								 npu_job.start_date >= @start_date and  
								 npu_job.start_date <= @end_date and 
								 npu_job.job_type in (1,2,3,10,11,12) )

order by campaign_no
     for read only

open camp_csr
fetch camp_csr into @campaign_no, @rep_id
while(@@fetch_status = 0) 
begin

	declare	job_csr cursor static for
	select	job_id, artwork_id, version_no
	from	npu_job,
			npu_request
	where 	npu_request.request_no = npu_job.request_no and
			npu_request.campaign_no = @campaign_no and
			npu_job.start_date >= @start_date and  
			npu_job.start_date <= @end_date and 
			npu_job.job_type in (1,2,3,10,11,12)
	order by job_id
	for read only

	open job_csr
	fetch job_csr into @job_id, @artwork_id, @version_no
	while(@@fetch_status = 0) 
	begin

		select @app_ok = 0,
				 @app_alters = 0,
				 @rejected = 0,
				 @major_alt = 0,
				 @minor_alt = 0

		declare	step_csr cursor static for
		select 	job_step_outcome, job_step_type
		from 	job_step
		where 	job_id = @job_id and
				job_step_type in (8,19,21) and
				job_step_status = 'X'
		order by job_step_id
		for read only

		open step_csr
		fetch step_csr into @step_outcome, @step_type
		while(@@fetch_status = 0) 
		begin
			if @step_type = 19 --major alter
				select @major_alt = @major_alt + 1
			
			if @step_type = 21 --minor alter
				select @minor_alt = @minor_alt + 1

			if @step_type = 8 --Approval
			begin
				if @step_outcome = 'F'
					select @rejected = @rejected + 1

				if @step_outcome = 'S' 
				begin
					select @approval_status = approval_status
                 from artwork_version
                where artwork_id = @artwork_id and
                      version_no = @version_no
					
					if @approval_status = 'O'
						select @app_ok = @app_ok + 1

					if @approval_status = 'A'
						select @app_alters = @app_alters + 1
				end
			end

			fetch step_csr into @step_outcome, @step_type
		end
      	deallocate step_csr

		insert into #results values (@rep_id, @campaign_no, @job_id, @app_ok, @app_alters, @rejected, @major_alt, @minor_alt) 

		fetch job_csr into @job_id, @artwork_id, @version_no
	end
   	deallocate job_csr

	fetch camp_csr into @campaign_no, @rep_id
end
deallocate camp_csr

--Return
select sr.branch_code,
       r.rep_id,
       sr.status,
       r.campaign_no,
       sc.name_on_slide,
       j.job_type,
       a.artwork_key,  
	    r.app_ok,
	    r.app_alters,
   	 r.rejected,
	    r.major_alt,
   	 r.minor_alt
  from #results r,
       artwork a,
       npu_job j,
       sales_rep sr,
       slide_campaign sc
 where r.rep_id = sr.rep_id and
       r.job_id = j.job_id and
       j.artwork_id = a.artwork_id and
       r.campaign_no = sc.campaign_no
return 0
GO
