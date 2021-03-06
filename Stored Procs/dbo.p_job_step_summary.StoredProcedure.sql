/****** Object:  StoredProcedure [dbo].[p_job_step_summary]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_job_step_summary]
GO
/****** Object:  StoredProcedure [dbo].[p_job_step_summary]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_job_step_summary]		  @date_from   datetime,
					  @date_to     datetime,
					  @step_type	integer	
as
set nocount on 
declare  @branch_code			char(2),
			@job_step_type		integer,
			@branch_cnt		integer,
			@branch_duration	integer,
			@prod_cnt		integer,
			@prod_duration		integer,
			@ho_cnt			integer,
			@ho_duration		integer,
			@avg_duration		decimal(6,2),
			@total_duration		integer,
			@total_steps		integer


create table #report_items
(
	country_code		char(1)				null,
	branch_code			char(2)				null,
	branch 				varchar(50)			null,
	job_step_type		integer				null,
	job_step_code		char(5)				null,
	job_step_desc		varchar(30)			null,
	job_step_category varchar(30)			null,
	branch_cnt			integer				null,
	prod_cnt				integer				null,
	ho_cnt				integer				null,
	branch_duration   integer				null,
	prod_duration		integer				null,
	ho_duration			integer				null,
	total_avg 			decimal(6,2)		null,
	total_steps			integer				null
)


insert into #report_items (
	country_code,
	branch_code,
	branch,
	job_step_type,
	job_step_code,
	job_step_desc,
	job_step_category
)
SELECT   branch.country_code,
			branch.branch_code,   
         branch.branch_name,   
         job_step_type.step_type_id,   
         job_step_type.step_type_code,   
         job_step_type.step_type_desc,   
         job_step_category.job_step_category_desc  
    FROM branch,   
         job_step_type,   
         job_step_category  
   WHERE ( job_step_type.step_category = job_step_category.job_step_category_code ) and
			( job_step_type.step_type_id = @step_type )


 declare item_csr cursor static for
  select branch_code,
         job_step_type
    from #report_items
order by branch_code,job_step_type
     for read only

open item_csr
fetch item_csr into @branch_code, @job_step_type
while(@@fetch_status = 0)
begin
	-- Update Branch values.
	  SELECT @branch_cnt = count(job_step.job_step_id),
				@branch_duration = sum(job_step.actual_duration)
		 FROM job_step,   
				npu_job,   
				npu_request  
		WHERE ( job_step.job_id = npu_job.job_id ) and  
				( npu_job.request_no = npu_request.request_no ) and  
				( ( job_step.job_step_type = @job_step_type ) AND  
				( npu_request.branch_code = @branch_code ) ) and
				( job_step.actual_end >= @date_from and job_step.actual_end <= @date_to ) and
	         ( job_step.job_step_status = 'X' and job_step.job_step_outcome = 'S') and
				( npu_request.request_source = 'B' )

	-- Update Production values.
	  SELECT @prod_cnt = count(job_step.job_step_id),
				@prod_duration = sum(job_step.actual_duration)
		 FROM job_step,   
				npu_job,   
				npu_request  
		WHERE ( job_step.job_id = npu_job.job_id ) and  
				( npu_job.request_no = npu_request.request_no ) and  
				( ( job_step.job_step_type = @job_step_type ) AND  
				( npu_request.branch_code = @branch_code ) ) and
				( job_step.actual_end >= @date_from and job_step.actual_end <= @date_to ) and
	         ( job_step.job_step_status = 'X' and job_step.job_step_outcome = 'S') and
				( npu_request.request_source = 'P' )

	-- Update Head Office values.
	  SELECT @ho_cnt = count(job_step.job_step_id),
				@ho_duration = sum(job_step.actual_duration)
		 FROM job_step,   
				npu_job,   
				npu_request  
		WHERE ( job_step.job_id = npu_job.job_id ) and  
				( npu_job.request_no = npu_request.request_no ) and  
				( ( job_step.job_step_type = @job_step_type ) AND  
				( npu_request.branch_code = @branch_code ) ) and
				( job_step.actual_end >= @date_from and job_step.actual_end <= @date_to ) and
	         ( job_step.job_step_status = 'X' and job_step.job_step_outcome = 'S') and
				( npu_request.request_source = 'H' )

	--Sum totals.
	select @total_duration = isnull(@branch_duration,0) + isnull(@prod_duration,0) + isnull(@ho_duration,0)
	select @total_steps    = isnull(@branch_cnt,0) + isnull(@prod_cnt,0) + isnull(@ho_cnt,0)
	if @total_steps = 0
		select @avg_duration = 0 
	else
		select @avg_duration = convert(decimal(6,2),(convert(decimal(15,8),@total_duration) / convert(decimal(15,8),@total_steps)))

	--Update the report item record
	update #report_items 
		set branch_cnt = @branch_cnt,
			 prod_cnt = @prod_cnt,
			 ho_cnt = @ho_cnt,
			 branch_duration = @branch_duration,
			 prod_duration = @prod_duration,
			 ho_duration = @ho_duration,
			 total_avg = @avg_duration,
			 total_steps = @total_steps
	 where #report_items.branch_code = @branch_code and
			 #report_items.job_step_type = @job_step_type

	fetch item_csr into @branch_code, @job_step_type
end
close item_csr
deallocate item_csr


select * from #report_items
GO
