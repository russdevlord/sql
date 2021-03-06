/****** Object:  StoredProcedure [dbo].[p_certificate_group_empty]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_certificate_group_empty]
GO
/****** Object:  StoredProcedure [dbo].[p_certificate_group_empty]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_certificate_group_empty] @complex_id			integer,
                                      @screening_date		datetime
as

declare @error     		int

/*
 * Begin Transaction
 */

begin transaction

/*
 * Delete Empty Groups
 */

delete certificate_group
 where complex_id = @complex_id and
       screening_date = @screening_date and
       is_movie = 'N' and
       not exists ( select certificate_item_id
                      from certificate_item citem
                     where citem.certificate_group = certificate_group.certificate_group_id )

select @error = @@error
if (@error != 0)
begin
	rollback transaction
	raiserror ( 'Error', 16, 1) 
   return -1
end	

/*
 * Commit and Return
 */

commit transaction
return 0
GO
