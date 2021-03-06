/****** Object:  StoredProcedure [dbo].[p_branch_campaign_unassign]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_branch_campaign_unassign]
GO
/****** Object:  StoredProcedure [dbo].[p_branch_campaign_unassign]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_branch_campaign_unassign] 	@campaign_no	  	integer,
										@print_id      		integer,
										@branch_code    	char(2),
										@print_medium 		char(1),
										@three_d_type		integer
as

declare @error      integer

begin transaction

update 	print_transactions
set 	campaign_no = null
where 	campaign_no = @campaign_no 
and		print_id = @print_id 
and		branch_code = @branch_code 
and		print_medium = @print_medium
and		three_d_type = @three_d_type

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	return -100
end	

commit transaction
return 0
GO
