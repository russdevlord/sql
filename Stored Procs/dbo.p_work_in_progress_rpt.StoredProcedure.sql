/****** Object:  StoredProcedure [dbo].[p_work_in_progress_rpt]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_work_in_progress_rpt]
GO
/****** Object:  StoredProcedure [dbo].[p_work_in_progress_rpt]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_work_in_progress_rpt] @start_date			datetime,
                                   @end_date				datetime,
                                   @branch_code			char(2),
                                   @live_campaigns		char(1)
as
set nocount on 
/*
 * Declare Variables
 */

declare @error        				int,
        @rowcount     				int,
        @errorode							int,
        @request_date				datetime,
        @acceptance_date			datetime,
        @artwork_creation			datetime,
        @artwork_approval			datetime,
        @campaign_no					char(7),
        @poster_count				integer,
        @step_count					integer

/*
 * Create Temporary Table
 */

create table #wip
(
	branch_code					char(2)				null,
	proposal_date				datetime				null,
	proposal_wizard			char(1)				null,
	client_name					varchar(50)			null,
	contract_value				money					null,
	campaign_no					char(7)				null,
   campaign_status			char(1)				null,
   campaign_type				char(1)				null,
	name_on_slide				varchar(50)			null,
	branch_release				char(1)				null,
	npu_release					char(1)				null,
	ho_release					char(1)				null,
	official_period			datetime				null,
	nett_contract_value		money					null,
	start_date					datetime				null,
	rep_id						integer				null,
	rep_name						varchar(62)			null,
	request_date				datetime				null,
	acceptance_date			datetime				null,
   artwork_creation			datetime				null,
   artwork_approval			datetime				null,
   poster						char(1)				null
)


/*
 * Insert Proposals into Temp Table
 */

insert into #wip (
       branch_code,
       proposal_date,
       proposal_wizard,
       client_name,
       contract_value,
       rep_id,
       rep_name,
       poster )
select sp.branch_code,
       sp.proposal_date,
       sp.proposal_wizard,
       sp.client_name,
       sp.contract_value,
       rep.rep_id,
       rep.last_name + ', ' + rep.first_name,
       'N'
  from slide_proposal sp,
       sales_rep rep
 where sp.proposal_date >= @start_date and
       sp.proposal_date <= @end_date and
       sp.branch_code = @branch_code and
       sp.rep_id = rep.rep_id and
       sp.campaign_no is null

/*
 * Insert Campaigns into Temp Table
 */

insert into #wip (
       branch_code,
       proposal_date,
       proposal_wizard,
       client_name,
       contract_value,
       campaign_no,
       campaign_status,
       campaign_type,
       name_on_slide,
       branch_release,
       npu_release,
       ho_release,
       official_period,
       nett_contract_value,
       start_date,
       rep_id,
       rep_name,
       poster )
select sp.branch_code,
       sp.proposal_date,
       sp.proposal_wizard,
       sp.client_name,
       sp.contract_value,
       sc.campaign_no,
       sc.campaign_status,
       sc.campaign_type,
       sc.name_on_slide,
       sc.branch_release,
       sc.npu_release,
       sc.ho_release,
       sc.official_period,
       sc.nett_contract_value,
       sc.start_date,
       rep.rep_id,
       rep.last_name + ', ' + rep.first_name,
       'N'
  from slide_proposal sp,
       slide_campaign sc,
       sales_rep rep
 where sp.proposal_date >= @start_date and
       sp.proposal_date <= @end_date and
       sp.branch_code = @branch_code and
       sp.rep_id = rep.rep_id and
       sp.campaign_no = sc.campaign_no and
    (( sc.campaign_status = 'U' ) or
     ( sc.campaign_status = 'L' and @live_campaigns = 'Y' ))
       
 declare campaign_csr cursor static for
  select campaign_no
    from #wip
   where campaign_no is not null
order by proposal_date
     for read only
/*
 * Loop Campaigns
 */
open campaign_csr
fetch campaign_csr into @campaign_no
while(@@fetch_status = 0) 
begin

	/*
    * Determine Earliest Request Date
    */

	select @request_date = null

	select @request_date = min(creation_date)
     from npu_request
    where campaign_no = @campaign_no

	if(@request_date <> null)
		update #wip
         set request_date = @request_date
       where campaign_no = @campaign_no

	/*
    * Determine Earliest Accepted Request
    */

	select @acceptance_date = null

	select @acceptance_date = min(judgement_date)
     from npu_request
    where campaign_no = @campaign_no and
          request_judgement = 'A' --Accepted

	if(@acceptance_date <> null)
		update #wip
         set acceptance_date = @acceptance_date
       where campaign_no = @campaign_no

	/*
    * Determine Earliest Artwork Creation
    */

	select @artwork_creation = null

	select @artwork_creation = min(actual_end)
     from npu_request nr,
			 npu_job job,
          job_step stp,
          job_step_type jst
	 where nr.campaign_no = @campaign_no and
			 nr.request_no = job.request_no and
          job.job_id = stp.job_id and
          stp.job_step_status = 'X' and
          stp.job_step_outcome = 'S' and
          stp.job_step_type = jst.step_type_id and
          jst.step_type_code = 'NEWAW'

	if(@artwork_creation <> null)
		update #wip
         set artwork_creation = @artwork_creation
       where campaign_no = @campaign_no

	/*
    * Determine Earliest Artwork Approval
    */

	select @artwork_approval = null

	select @artwork_approval = min(actual_end)
     from npu_request nr,
			 npu_job job,
          job_step stp,
          job_step_type jst
	 where nr.campaign_no = @campaign_no and
			 nr.request_no = job.request_no and
          job.job_id = stp.job_id and
          stp.job_step_status = 'X' and
          stp.job_step_outcome = 'S' and
          stp.job_step_type = jst.step_type_id and
          jst.step_type_code = 'APPAW'

	if(@artwork_approval <> null)
		update #wip
         set artwork_approval = @artwork_approval
       where campaign_no = @campaign_no

	/*
    * Determine Poster
    */

	select @poster_count = 0

	select @poster_count = count(nr.request_no)
     from npu_request nr,
          request_type rt
    where nr.campaign_no = @campaign_no and
          nr.request_type = rt.request_type_id and
          rt.request_type_code = 'POSTR'

	select @poster_count = isnull(@poster_count,0)

	if(@poster_count = 0)
	begin

		select @poster_count = count(stp.job_step_id)
		  from npu_request nr,
				 npu_job job,
             job_step stp,
             job_step_type jst
		 where nr.campaign_no = @campaign_no and
				 nr.request_no = job.request_no and
             job.job_id = stp.job_id and
             stp.job_step_type = jst.step_type_id and
             jst.step_type_code = 'IMGPO'

		select @poster_count = isnull(@poster_count,0)

	end
       
	if(@poster_count > 0)
		update #wip
         set poster = 'Y'
       where campaign_no = @campaign_no

	/*
    * Fetch Next
    */

	fetch campaign_csr into @campaign_no

end
close campaign_csr

/*
 * Return Dataset
 */

select branch_code,
       proposal_date,
       proposal_wizard,
       client_name,
       contract_value,
       campaign_no,
       campaign_status,
       campaign_type,
       name_on_slide,
       branch_release,
       npu_release,
       ho_release,
       official_period,
       nett_contract_value,
       start_date,
       rep_id,
       rep_name,
       request_date,
       acceptance_date,
       artwork_creation,
       artwork_approval,
       poster
  from #wip
order by proposal_date,
         campaign_no

/*
 * Return Success
 */

return 0
GO
