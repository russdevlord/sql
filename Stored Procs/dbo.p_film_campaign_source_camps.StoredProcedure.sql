/****** Object:  StoredProcedure [dbo].[p_film_campaign_source_camps]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_film_campaign_source_camps]
GO
/****** Object:  StoredProcedure [dbo].[p_film_campaign_source_camps]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
create proc [dbo].[p_film_campaign_source_camps] @campaign_no integer
as

declare @error						integer,
		@source_campaign		integer,
		@makegood_amt			money,
		@dandc_amt				money,
		@delete_charge_id		integer

/*
 * Create Temp Table
 */

create table #campaigns
(
	campaign_no 		integer		null,
	delete_charge_id	integer		null,	
	makegood_amt		money		null,
	dandc_amt		money		null
)

/*
 * Populate Temp Table
 */

insert into #campaigns (campaign_no, delete_charge_id)
  select distinct source_campaign,
		  delete_charge_id
   from delete_charge
  where destination_campaign = @campaign_no

/*
 * Declare Cursor
 */

 declare source_csr cursor static for
  select campaign_no ,
			delete_charge_id
    from #campaigns
order by campaign_no

/*
 * Loop through cursor
 */

open source_csr
fetch source_csr into @source_campaign, @delete_charge_id
while(@@fetch_status=0)
begin

	select 	@makegood_amt = isnull(sum(makegood_rate), 0)
	from 	campaign_spot,
			delete_charge_spots
	where 	campaign_spot.spot_id = delete_charge_spots.spot_id
	and 	delete_charge_spots.delete_charge_id = @delete_charge_id
	and 	delete_charge_spots.campaign_no = @campaign_no
	and 	delete_charge_spots.source_dest = 'D'
	
	select 	@makegood_amt = @makegood_amt + isnull(sum(makegood_rate), 0)
	from 	cinelight_spot,
			delete_charge_cinelight_spots
	where 	cinelight_spot.spot_id = delete_charge_cinelight_spots.spot_id
	and 	delete_charge_cinelight_spots.delete_charge_id = @delete_charge_id
	and 	delete_charge_cinelight_spots.campaign_no = @source_campaign
	and 	delete_charge_cinelight_spots.source_dest = 'D'

	select 	@makegood_amt = @makegood_amt + isnull(sum(makegood_rate), 0)
	from 	inclusion_spot,
			inclusion,
			delete_charge_inclusion_spots
	where 	inclusion_spot.spot_id = delete_charge_inclusion_spots.spot_id
	and 	delete_charge_inclusion_spots.delete_charge_id = @delete_charge_id
	and 	delete_charge_inclusion_spots.campaign_no = @source_campaign
	and 	delete_charge_inclusion_spots.source_dest = 'D'
	and		inclusion.inclusion_id = inclusion_spot.inclusion_id
	and		inclusion.inclusion_type = 5

	select 	@dandc_amt = isnull(sum(charge_rate), 0)
	from 	campaign_spot,
			delete_charge_spots
	where 	campaign_spot.spot_id = delete_charge_spots.spot_id
	and 	delete_charge_spots.delete_charge_id = @delete_charge_id
	and 	delete_charge_spots.campaign_no = @source_campaign
	and 	delete_charge_spots.source_dest = 'S'
	and 	campaign_spot.spot_type <> 'D'
	
	select 	@dandc_amt = @dandc_amt + isnull(sum(charge_rate), 0)
	from 	cinelight_spot,
			delete_charge_cinelight_spots
	where 	cinelight_spot.spot_id = delete_charge_cinelight_spots.spot_id
	and 	delete_charge_cinelight_spots.delete_charge_id = @delete_charge_id
	and 	delete_charge_cinelight_spots.campaign_no = @source_campaign
	and 	delete_charge_cinelight_spots.source_dest = 'S'
	and 	cinelight_spot.spot_type <> 'D'

	select 	@dandc_amt = @dandc_amt + isnull(sum(charge_rate), 0)
	from 	inclusion_spot,
			inclusion,
			delete_charge_inclusion_spots
	where 	inclusion_spot.spot_id = delete_charge_inclusion_spots.spot_id
	and 	delete_charge_inclusion_spots.delete_charge_id = @delete_charge_id
	and 	delete_charge_inclusion_spots.campaign_no = @source_campaign
	and 	delete_charge_inclusion_spots.source_dest = 'S'
	and 	inclusion_spot.spot_type <> 'D'
	and		inclusion.inclusion_id = inclusion_spot.inclusion_id
	and		inclusion.inclusion_type = 5
	
	update 	#campaigns
	set 	makegood_amt = @makegood_amt,
			dandc_amt = @dandc_amt
	where 	campaign_no = @source_campaign
	
	fetch source_csr into @source_campaign, @delete_charge_id
end

close source_csr
deallocate source_csr

/*
 * Select and Return
 */

select * from #campaigns
return 0
GO
