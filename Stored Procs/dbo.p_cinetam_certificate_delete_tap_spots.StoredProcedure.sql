/****** Object:  StoredProcedure [dbo].[p_cinetam_certificate_delete_tap_spots]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cinetam_certificate_delete_tap_spots]
GO
/****** Object:  StoredProcedure [dbo].[p_cinetam_certificate_delete_tap_spots]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_cinetam_certificate_delete_tap_spots]			@complex_id				int,
																										@screening_date		datetime
																										
as

declare			@error			int

begin transaction

delete tap_inc_spot_xref
where spot_id in (select spot_id from campaign_spot where spot_type = 'T' and spot_status = 'U' and complex_id = @complex_id and screening_date = @screening_date)

select @error = @@error
if @error <> 0
begin
	rollback transaction
	raiserror ('Erro deleting unallocated TAP Xref spots', 16, 1)
	return -1
end

delete campaign_spot where spot_type = 'T' and spot_status = 'U' and complex_id = @complex_id and screening_date = @screening_date

select @error = @@error
if @error <> 0
begin
	rollback transaction
	raiserror ('Erro deleting unallocated TAP spots', 16, 1)
	return -1
end

commit transaction

return 0
GO
