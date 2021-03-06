/****** Object:  StoredProcedure [dbo].[p_campaign_account_update]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_campaign_account_update]
GO
/****** Object:  StoredProcedure [dbo].[p_campaign_account_update]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_campaign_account_update] @campaign_no		int

as

declare			@errno					int,
       				@errmsg   			varchar(255)
/*
 * Set Omnicom as the account for all Opera Agencies
 */

update film_campaign
set		onscreen_account_id = 32513
where	campaign_no = @campaign_no
and		onscreen_account_id in (select account_id from account where agency_id in (select agency_id from agency where agency_group_id in (select agency_group_id from agency_groups where buying_group_id = 3)))

select @errno = @@error
if (@errno != 0)
begin
	select @errno = 50000,
	@errmsg = 'Error updating Opera Billing onscreen accounts'
	goto error
end

update film_campaign
set		cinelight_account_id = 32513
where	campaign_no = @campaign_no
and		cinelight_account_id in (select account_id from account where agency_id in (select agency_id from agency where agency_group_id in (select agency_group_id from agency_groups where buying_group_id = 3)))

select @errno = @@error
if (@errno != 0)
begin
	select @errno = 50000,
	@errmsg = 'Error updating Opera Billing digilite accounts'
	goto error
end

update film_campaign
set		outpost_account_id = 32513
where	campaign_no = @campaign_no
and		outpost_account_id in (select account_id from account where agency_id in (select agency_id from agency where agency_group_id in (select agency_group_id from agency_groups where buying_group_id = 3)))

select @errno = @@error
if (@errno != 0)
begin
	select @errno = 50000,
	@errmsg = 'Error updating Opera Billing retail accounts'
	goto error
end

/*
 * Return
 */

return 0

/*
 * Error Checking
 */

error:
    rollback  transaction
    raiserror (@errmsg, 16, 1)
	return -1
GO
