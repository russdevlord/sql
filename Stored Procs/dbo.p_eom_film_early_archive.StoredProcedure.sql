/****** Object:  StoredProcedure [dbo].[p_eom_film_early_archive]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_eom_film_early_archive]
GO
/****** Object:  StoredProcedure [dbo].[p_eom_film_early_archive]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_eom_film_early_archive] @campaign_no		integer

as

declare @error        				integer,
		  @errorode        				integer 


begin transaction

/*
 * Create Movie Archive
 */

execute @errorode = p_arc_film_campaign_movie @campaign_no
if (@errorode !=0)
begin
	rollback transaction
	raiserror ('Error : Failed to archive movie screening information.', 16, 1)
	return -1
end

/*
 * Update Film Campaign Packages - Set the average rate and spot count
 */

execute @errorode = p_arc_film_campaign_avg_rates @campaign_no
if (@errorode !=0)
begin
	rollback transaction
	raiserror ('Error : Failed to archive average rate information.', 16, 1)
	return -1
end

/*
 * Update Film Campaign Packages - Set the average rate and spot count
 */

execute @errorode = p_eom_certificate_item_arc @campaign_no
if (@errorode !=0)
begin
	rollback transaction
	raiserror ('Error : Failed to archive certiticate information.', 16, 1)
	return -1
end

/*
 * Update Film Campaign
 */

update film_campaign
	set campaign_expiry_idc = 'Y' --Closed
 where campaign_no = @campaign_no

select @error = @@error
if (@error !=0)
begin
	rollback transaction
	raiserror ('Error : Failed to update film_campaign.', 16, 1)
	return -1
end	

commit transaction
return 0
GO
