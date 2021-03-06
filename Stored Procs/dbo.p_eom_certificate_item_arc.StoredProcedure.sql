/****** Object:  StoredProcedure [dbo].[p_eom_certificate_item_arc]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_eom_certificate_item_arc]
GO
/****** Object:  StoredProcedure [dbo].[p_eom_certificate_item_arc]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_eom_certificate_item_arc] @campaign_no				integer

as

declare @error 		integer

begin transaction

/*
 * Update Certificate Items
 */

update certificate_item
	set campaign_summary = 'Y'
  from campaign_spot spot
 where spot.campaign_no = @campaign_no and
		 spot.spot_id = certificate_item.spot_reference

select @error = @@error
if (@error !=0)
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
