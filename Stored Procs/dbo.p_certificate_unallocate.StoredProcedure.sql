USE [production]
GO
/****** Object:  StoredProcedure [dbo].[p_certificate_unallocate]    Script Date: 11/03/2021 2:30:33 PM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_certificate_unallocate] @complex_id			int,
                                     @screening_date		datetime,
                                     @reason				varchar(255),
                                     @certificate_score		smallint
                                     
as

declare @error     		int

/*
 * Begin Transaction
 */

begin transaction

/*
 * Unallocate all Active spots screening at this Complex Date
 */

update campaign_spot
   set spot_status = 'U',
       spot_instruction = @reason,
       certificate_score = @certificate_score
 where complex_id = @complex_id and
       screening_date = @screening_date and
       spot_status = 'A'
       
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
