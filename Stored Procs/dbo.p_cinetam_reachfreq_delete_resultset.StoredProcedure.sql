/****** Object:  StoredProcedure [dbo].[p_cinetam_reachfreq_delete_resultset]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cinetam_reachfreq_delete_resultset]
GO
/****** Object:  StoredProcedure [dbo].[p_cinetam_reachfreq_delete_resultset]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_cinetam_reachfreq_delete_resultset]			@resultset_id				int

as

declare	@error				int


begin transaction

delete	cinetam_reachfreq_result_criteria_pattern
from		cinetam_reachfreq_result_criteria
where	cinetam_reachfreq_result_criteria_pattern.result_criteria_id = cinetam_reachfreq_result_criteria.result_criteria_id
and			resultset_id = @resultset_id

select @error = @@error
if @error != 0
begin
	raiserror ('Error deleting patterns', 16, 1)
	rollback transaction
	return -1
end

delete	cinetam_reachfreq_result_criteria
where	resultset_id = @resultset_id

select @error = @@error
if @error != 0
begin
	raiserror ('Error deleting results', 16, 1)
	rollback transaction
	return -1
end

delete	cinetam_reachfreq_resultset
where	resultset_id = @resultset_id

select @error = @@error
if @error != 0
begin
	raiserror ('Error deleting resultset', 16, 1)
	rollback transaction
	return -1
end

commit transaction
return 0
GO
