/****** Object:  StoredProcedure [dbo].[p_npu_request_control_sel]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_npu_request_control_sel]
GO
/****** Object:  StoredProcedure [dbo].[p_npu_request_control_sel]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_npu_request_control_sel] @branch_code			char(2),
                                      @requestor			integer,
                                      @request_source		char(1),
                                      @campaign_no			varchar(7),
                                      @admin_group_no		integer,
                                      @exclude				char(1),
                                      @request_status_1	char(1),
                                      @request_status_2	char(1),
                                      @request_status_3	char(1),
                                      @request_status_4	char(1)
as
set nocount on 
/*
 * Declare Procedure Variables
 */

declare @error          			integer,
        @rowcount						integer,
        @branch_code_tmp			char(2),
        @requestor_tmp				integer,
        @request_source_tmp		char(1)

/*
 * Create Temporary Tables
 */

create table #npu_requests
(
   request_no					char(8)			null,
   request_desc				varchar(50)		null,
   campaign_no					char(7)			null,
   request_type				integer			null,
   request_status				char(1)			null,
   request_priority			char(1)			null,
   priority_score				integer			null,
   requestor					integer			null,
   request_source				char(1)			null,
   request_link				char(1)			null,
   branch_code					char(2)			null,
   request_judgement			char(1)			null,
   submit_date					datetime			null,
   judgement_date				datetime			null,
   request_instructions		varchar(255)	null,
   request_comments			varchar(255)	null,
   creation_date				datetime			null,
   artwork_alert				char(1)			null
)

select @branch_code_tmp = branch_code
  from branch
 where @branch_code = branch_code

select @requestor_tmp = employee_id
  from employee
 where @requestor = employee_id

select @request_source_tmp = request_source_code
  from request_source
 where @request_source = request_source_code

select @branch_code = @branch_code_tmp,
       @requestor = @requestor_tmp,
       @request_source = @request_source_tmp

insert into #npu_requests
  select npu_request.request_no,   
         npu_request.request_desc,   
         npu_request.campaign_no,   
         npu_request.request_type,   
         npu_request.request_status,   
         npu_request.request_priority,   
         job_priority.priority_score,   
         npu_request.requestor,   
         npu_request.request_source,   
         npu_request.request_link,   
         npu_request.branch_code,   
         npu_request.request_judgement,   
         npu_request.submit_date,   
         npu_request.judgement_date,   
         npu_request.request_instructions,   
         npu_request.request_comments,   
         npu_request.creation_date,
         'N'
    from npu_request,
         request_type,
         job_priority,
         employee
   where npu_request.request_type = request_type.request_type_id and
         npu_request.request_priority = job_priority.job_priority_code and
         npu_request.requestor = employee.employee_id and
         ( npu_request.branch_code = @branch_code or @branch_code is null ) and
         ( npu_request.requestor = @requestor or @requestor is null ) and
         ( npu_request.campaign_no like @campaign_no + '%' or
           @campaign_no is null ) and
         ( request_type.admin_group_no = @admin_group_no or @admin_group_no is null ) and
         ( npu_request.request_source <= @request_source or @request_source is null ) and

         ( ( ( npu_request.request_status in ( @request_status_1, @request_status_2, @request_status_3, @request_status_4 ) and @exclude <> 'Y' and
             ( @request_status_1 is not null or @request_status_2 is not null or @request_status_3 is not null or @request_status_4 is not null ) ) or
             ( @request_status_1 is null and @request_status_2 is null and @request_status_3 is null and @request_status_4 is null ) ) or

           ( npu_request.request_status not in ( @request_status_1, @request_status_2, @request_status_3, @request_status_4 ) and @exclude = 'Y' ) )

update #npu_requests
   set artwork_alert = 'Y'
  from npu_job,
       artwork,
       artwork_version
 where #npu_requests.request_no = npu_job.request_no and
       npu_job.artwork_id = artwork.artwork_id and
       artwork.artwork_id = artwork_version.artwork_id and
       npu_job.version_no = artwork.version_no and
       #npu_requests.request_status = 'A' and
       npu_job.job_status <> 'C' and
       npu_job.job_status <> 'X' and
       ( ( artwork_version.approval_status <> 'O' and artwork_version.approval_status <> 'A' ) or
         ( artwork_version.approval_status = 'A' and
           exists ( select job_step.job_step_id
                      from job_step,
                           job_step_type
                     where npu_job.job_id = job_step.job_id and
                           job_step.job_step_type = job_step_type.step_type_id and
                           job_step.job_step_status = 'O' and
                           job_step_type.step_type_code in ( 'MINAW', 'ALTAW', 'APPAW' ) ) ) )

/*
 * Select
 */

select * from #npu_requests

return 0
GO
