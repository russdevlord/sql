/****** Object:  StoredProcedure [dbo].[p_posters_per_campaign]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_posters_per_campaign]
GO
/****** Object:  StoredProcedure [dbo].[p_posters_per_campaign]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_posters_per_campaign]	@branch_code		char(1),
                                    @start_date			datetime,
									@end_date			datetime,
    								@exclude_term		char(1)

as
set nocount on 
declare  @rep_id		integer,
	@camp_count		integer,
	@poster_count		integer



create table #results
(
	rep_id		integer		null,
	campaigns	integer		null,
	posters		integer		null
)

declare rep_csr cursor static for
  select distinct sales_rep.rep_id
    from slide_campaign,
         slide_proposal,
         sales_rep
   where slide_campaign.campaign_no = slide_proposal.campaign_no and
         slide_campaign.campaign_status <> 'U' and
         slide_campaign.campaign_status <> 'Z' and
         slide_proposal.creation_period >= @start_date and  
         slide_proposal.creation_period <= @end_date and
         slide_proposal.campaign_no is not null and
         sales_rep.rep_id = slide_proposal.rep_id and
         (sales_rep.branch_code = @branch_code or @branch_code = '@') and
	(sales_rep.status = 'A' or @exclude_term = 'N')
order by sales_rep.rep_id
     for read only

open rep_csr
fetch rep_csr into @rep_id
while(@@fetch_status = 0) 
begin
	--Select a count of contracts for this 
   select @camp_count = count(slide_proposal.campaign_no)
     from slide_proposal,
          slide_campaign,
          sales_rep
    where slide_campaign.campaign_no = slide_proposal.campaign_no and
          slide_campaign.campaign_status <> 'U' and
          slide_campaign.campaign_status <> 'Z' and
          slide_proposal.creation_period >= @start_date and  
          slide_proposal.creation_period <= @end_date and
	       slide_proposal.campaign_no is not null and
          sales_rep.rep_id = slide_proposal.rep_id and
          (sales_rep.branch_code = @branch_code or @branch_code = '@') and
			 (sales_rep.status = 'A' or @exclude_term = 'N') and
          sales_rep.rep_id = @rep_id

	--Select a count of campaigns that have image posters job steps (15)
   select @poster_count = count(distinct slide_proposal.campaign_no)
     from slide_proposal,
          npu_request,
          npu_job,
          job_step,
          slide_campaign,
          sales_rep
    where slide_campaign.campaign_no = slide_proposal.campaign_no and
          slide_campaign.campaign_status <> 'U' and
          slide_campaign.campaign_status <> 'Z' and
          job_step.job_id = npu_job.job_id and  
          npu_job.request_no = npu_request.request_no and
          job_step.job_step_type = 15 and
          slide_proposal.campaign_no = npu_request.campaign_no and
          slide_proposal.creation_period >= @start_date and  
          slide_proposal.creation_period <= @end_date and
	       slide_proposal.campaign_no is not null and
          sales_rep.rep_id = slide_proposal.rep_id and
          (sales_rep.branch_code = @branch_code or @branch_code = '@') and
 			 (sales_rep.status = 'A' or @exclude_term = 'N') and
          sales_rep.rep_id = @rep_id

	insert into #results values ( @rep_id, @camp_count, @poster_count)

	fetch rep_csr into @rep_id
end
close rep_csr
deallocate rep_csr

--Return
select sr.branch_code,
       sr.status,
       r.rep_id,
		 r.campaigns,
       r.posters
  from #results r,
       sales_rep sr
 where r.rep_id = sr.rep_id

return 0
GO
