/****** Object:  StoredProcedure [dbo].[p_certificate_reset_weekend]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_certificate_reset_weekend]
GO
/****** Object:  StoredProcedure [dbo].[p_certificate_reset_weekend]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_certificate_reset_weekend] @complex_id			int,
																							@screening_date 	datetime
as

/*
 * Declare Variables
 */

declare @error     				int,
        @errorode                 int,
        @spot_id				int,
        @cert_score				int,
        @charge_rate			money,
		@rate					money,
        @spot_redirect          int

/*
 * Begin Transaction
 */

begin transaction

delete certificate_item_weekend
 where certificate_group in (select certificate_group_id from  certificate_group_weekend
                              where complex_id = @complex_id and
                                    screening_date = @screening_date)

select @error = @@error
if (@error != 0)
begin
	rollback transaction
	raiserror ( 'Error', 16, 1) 
   return -1
end	

/*
 * Remove all Certificate Groups and (Certificate Items -> Cascade)
 */

delete certificate_group_weekend
 where complex_id = @complex_id and
       screening_date = @screening_date

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
