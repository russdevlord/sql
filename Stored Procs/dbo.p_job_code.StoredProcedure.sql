USE [production]
GO
/****** Object:  StoredProcedure [dbo].[p_job_code]    Script Date: 11/03/2021 2:30:34 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_job_code]	@request_no    	char(8),
                        @job_code			char(1) OUTPUT
as
set nocount on 

declare @error       	int,
        @count       	smallint,
        @max_code			char(1)

/*
 * Get Last Job Code for the Request
 */
	
select @max_code = max(job_code)
  from npu_job
 where request_no = @request_no

/*
 * Calculate New Job Code
 */
	
if((@max_code = 'Z') or (@max_code is null))
	select @job_code = 'A'
else
	select @job_code = char(ascii(@max_code) + 1)

/*
 * Return
 */

return 0
GO
