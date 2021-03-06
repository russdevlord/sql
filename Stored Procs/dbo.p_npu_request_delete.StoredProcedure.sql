/****** Object:  StoredProcedure [dbo].[p_npu_request_delete]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_npu_request_delete]
GO
/****** Object:  StoredProcedure [dbo].[p_npu_request_delete]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_npu_request_delete] @request_no          char(8),
                                 @system_admin        char(1)
as
set nocount on 
/*
 * Declare Procedure Variables
 */

declare @error          		integer,
        @rowcount					integer,
        @count						integer

/*
 * Check Request
 */

select @count = count(request_no)
  from npu_request
 where request_no = @request_no

select @error = @@error,
       @rowcount = @@rowcount

if(@error != 0 or @count != 1)
begin
	raiserror ('Delete Request: Error Reading NPU Requests.', 16, 1)
	return -1
end

/*
 * Check Request is NEW
 */

select @count = count(request_no) 
  from npu_request
 where request_no = @request_no
   and request_status = 'N'

select @error = @@error,
		 @rowcount = @@rowcount

if ((@error != 0 or @count != 1) and (@system_admin != 'Y'))
begin
	raiserror ('Delete Request: NPU Request is NOT New.', 16, 1)
	return -1
end

/*
 * Check Jobs
 */

select @count = count(request_no)
  from npu_job
 where request_no = @request_no

select @error = @@error,
		 @rowcount = @@rowcount
 
if ((@error !=0 or @count > 0) and (@system_admin != 'Y'))
begin
	raiserror ('Delete Request: Request cannot be deleted because it has jobs.', 16, 1)
	return -1
end

/*
 * Begin Transaction
 */

begin transaction

/*
 * Delete Production Output
 */

delete from production_output
 where request_no = @request_no

select @error = @@error

if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Delete Request: Error Deleting Production Output. Delete Request Failed.', 16, 1)
	return @error
end

/*
 * Delete Job Complex
 */

delete from job_complex
 where job_id in (select job_id
						  from npu_job
						 where request_no = @request_no)

select @error = @@error

if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Delete Request: Error Deleting Job Complexes. Delete Request Failed.', 16, 1)
	return @error
end

/*
 * Delete Job Step
 */

delete from job_step
 where job_id in (select job_id
						  from npu_job
						 where request_no = @request_no)

select @error = @@error

if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Delete Request: Error Deleting Job Steps. Delete Request Failed.', 16, 1)
	return @error
end

/*
 * Set any 'New' Voiceovers to 'Cancelled'
 */

update voiceover
   set voiceover.voiceover_status = 'X'
 where voiceover.voiceover_status = 'N' and
       voiceover.voiceover_id in (select npu_job.voiceover_id
											   from npu_job
											  where request_no = @request_no)

select @error = @@error

if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Delete Request: Error Cancelling Voiceovers. Delete Request Failed.', 16, 1)
	return @error
end

/*
 * Delete NPU Job
 */

delete from npu_job
  from npu_job
  where request_no = @request_no

select @error = @@error

if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Delete Request: Error Deleting NPU Job. Delete Request Failed.', 16, 1)
	return @error
end

/*
 * Delete Request Artwork Complex
 */

delete from request_artwork_complex
 where request_artwork_id IN (select request_artwork_id 
										  from request_artwork
										 where request_no = @request_no)

select @error = @@error

if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Delete Request: Error Deleting Request Artwork Complex References. Delete Request Failed.', 16, 1)
	return @error
end

/* 
 * Delete Request Artwork
 */

delete from request_artwork
 where request_no = @request_no

select @error = @@error

if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Delete Request: Error Deleting Request Artwork References. Delete Request Failed.', 16, 1)
	return @error
end

/* 
 * Delete Request Voiceover
 */

delete from request_voiceover
 where request_no = @request_no

select @error = @@error

if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Delete Request: Error Deleting Request Voiceover References. Delete Request Failed.', 16, 1)
	return @error
end

/* 
 * Delete NPU Request
 */

delete from npu_request
 where request_no = @request_no

select @error = @@error

if ( @error !=0 )
begin
	rollback transaction
	raiserror ('Delete Request: Error Deleting Request. Delete Request Failed.', 16, 1)
   return @error
end

/*
 * Commit and Return
 */

commit transaction
return 0
GO
