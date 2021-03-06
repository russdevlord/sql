/****** Object:  StoredProcedure [dbo].[p_complex_campaign_unassign]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_complex_campaign_unassign]
GO
/****** Object:  StoredProcedure [dbo].[p_complex_campaign_unassign]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_complex_campaign_unassign] @campaign_no	  integer,
											  		 @print_id      integer,
                                   		 @complex_id    integer
as

declare @error      integer

begin transaction

update print_transactions
	set campaign_no = null
 where campaign_no = @campaign_no and
		 print_id = @print_id and
		 complex_id = @complex_id and
		 cinema_qty <> 0

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ( 'Error', 16, 1) 
	return @error
end	

commit transaction
return 0
GO
