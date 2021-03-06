/****** Object:  StoredProcedure [dbo].[p_service_rep_change]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_service_rep_change]
GO
/****** Object:  StoredProcedure [dbo].[p_service_rep_change]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_service_rep_change] @new_rep		int,
                                 @old_rep		int
as
set nocount on 
declare @error			int

/*
 * Begin Transaction
 */

begin transaction

/*
 * Update Camapigns
 */

update slide_campaign
	set service_rep = @new_rep
 where is_closed <> 'Y' and
		 service_rep = @old_rep
		
select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	return -1
end	

/*
 * Commit and Return
 */

commit transaction
return 0
GO
