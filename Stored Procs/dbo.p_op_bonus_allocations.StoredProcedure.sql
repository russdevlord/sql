/****** Object:  StoredProcedure [dbo].[p_op_bonus_allocations]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_op_bonus_allocations]
GO
/****** Object:  StoredProcedure [dbo].[p_op_bonus_allocations]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create proc [dbo].[p_op_bonus_allocations]  	@campaign_no              	int,
											@outpost_panel_id                 varchar(4000),
											@start_date                 datetime,
											@end_date                   datetime,
											@package_id                 int,
											@allocation_count           int,
											@allocation_value           numeric(9,2),
											@spot_type					char(1)

as

/*==============================================================*
 * DESC:- Analyses the best way to spread bonus allocations     *
 *        to outpost_venuees for a campaign.                          *
 *                                                              *
 *                       CHANGE HISTORY                         *
 *                       ==============                         *
 *                                                              *
 * Ver    DATE     		BY   DESCRIPTION                        *
 * === =========== 		===  ===========                        *
 *  1   5-Mar-2008 		DH  Initial Build  						*
 *  2   30-Nov-2010     MR	Added GoodWill Bonus                *
 *                                                              *
 *==============================================================*/

set nocount on

declare @target_date 					datetime, 
		@count 							int, 
		@prev_activity_date 			datetime, 
		@next_activity_date 			datetime, 
		@startpos 						smallint, 
		@endpos 						smallint, 
		@allocation_count_remaining 	int,
		@allocation_value_remaining 	numeric(9,2), 
		@rows 							int,
		@allocate_outpost_panel_id 			int, 
		@allocate_billing_date 			datetime, 
		@new_bonus_allocations 			smallint, 
		@allocation_effected 			int

/*
 * put the selected outpost_venuees into a temp table
 */

select @spot_type = upper(@spot_type)

create table #tmp_outpost_panels 
(
	outpost_panel_id			int 
)

select @outpost_panel_id = @outpost_panel_id + ','    -- put a comma at the end of the string to make it easier to parse

select @startpos = 1

select @endpos = charindex(',',@outpost_panel_id,@startpos)

while (@endpos > 0)
begin
	insert 	#tmp_outpost_panels 
	values	(convert(int,substring(@outpost_panel_id,@startpos,@endpos - @startpos)))

	select @startpos = @endpos + 1
	select @endpos = charindex(',',@outpost_panel_id,@startpos)
end

/*
 * create the temp table that will hold the allocations
 */

create table #tmp_allocations 
(
	outpost_panel_id				int,
	outpost_spot			int,
	billing_date			datetime,
	new_bonus_allocations 	int,
	charge_rate				numeric(9,2) 
)


/*
 * get the spot allocations for the campaign sorted by billing date
 */

select @target_date = dateadd(dd,1,@end_date)

select 	convert(int,@campaign_no) as campaign_no,
		outpost_spot.outpost_panel_id,
		outpost_venue_name,
		billing_date,
		count(spot_id) as spot_count,
		sum(charge_rate) as charge_rate_total,
		0 as bonus_allocations_count,
		0 as bonus_percent,
		convert(int, ( 1 / convert(numeric(6,2),
		count(spot_id)) ) * 100 ) as new_bonus_percent
  into 	#tmp_spots
  from 	outpost_spot,  outpost_venue, #tmp_outpost_panels, outpost_panel 
 where 	campaign_no = @campaign_no and
       	( @package_id = -1 or package_id = @package_id ) and
       	( billing_date between @start_date and @end_date ) and
       	spot_type in ('B', 'W', 'S') and
       	spot_status in ('A','P') and
       	tran_id is null and
       	outpost_venue.outpost_venue_id = outpost_panel.outpost_venue_id and
		outpost_panel.outpost_panel_id = outpost_spot.outpost_panel_id and
       	outpost_venue.bonus_allowed = 'Y' and
		outpost_panel.outpost_panel_id = #tmp_outpost_panels.outpost_panel_id
group by outpost_spot.outpost_panel_id, outpost_venue_name, billing_date


/*
 * get the bonus allocations already assigned to the campaign
 */

select convert(int,@campaign_no) as campaign_no,outpost_spot.outpost_panel_id,billing_date,count(spot_id) as bonus_allocations_count
  into #tmp_bonuses
  from outpost_spot,  outpost_venue, #tmp_outpost_panels, outpost_panel
 where campaign_no = @campaign_no and
       ( @package_id = -1 or package_id = @package_id ) and
       ( billing_date between @start_date and @end_date ) and
       spot_type in ('B','W') and
       spot_status in ('A','P') and
       	tran_id is null and
       	outpost_venue.outpost_venue_id = outpost_panel.outpost_venue_id and
		outpost_panel.outpost_panel_id = outpost_spot.outpost_panel_id and
       outpost_venue.bonus_allowed = 'Y' and
		outpost_panel.outpost_panel_id = #tmp_outpost_panels.outpost_panel_id
group by outpost_spot.outpost_panel_id, billing_date


/*
 * merge the results
 */

update #tmp_spots
   set bonus_allocations_count = #tmp_bonuses.bonus_allocations_count,
       bonus_percent = ( convert(numeric(6,2), #tmp_bonuses.bonus_allocations_count) / convert(numeric(6,2), #tmp_spots.spot_count) ) * 100,
       new_bonus_percent = ( convert(numeric(6,2), #tmp_bonuses.bonus_allocations_count + 1 ) / convert(numeric(6,2), #tmp_spots.spot_count) ) * 100
  from #tmp_spots, #tmp_bonuses
 where #tmp_spots.outpost_panel_id = #tmp_bonuses.outpost_panel_id and
       #tmp_spots.billing_date = #tmp_bonuses.billing_date

/*
 * search the campaign for the best spot to allocate the bonuses
 */

select 	@allocation_count_remaining = @allocation_count,
	   	@allocation_value_remaining = @allocation_value

while ( @allocation_count_remaining + @allocation_value_remaining ) > 0
begin

	/*
	 * process all spots for the next date within the range until 100% of the spots are allocated as bonuses 
	 */

	set rowcount 0
	select top 1 @target_date = billing_date from #tmp_spots where billing_date < @target_date order by billing_date desc
	if ( @@rowcount = 0 ) 
		break

	select top 1 @prev_activity_date = billing_date from outpost_spot where campaign_no = @campaign_no and billing_date < @target_date order by billing_date desc
	select top 1 @next_activity_date = billing_date from outpost_spot where campaign_no = @campaign_no and billing_date > @target_date order by billing_date

	/* copy all spots for the date into a separate table (to make it easier to process them) */
	select *, convert(char(1),'N') as sequential_bonuses, convert(smallint,0) as new_bonus_allocations into #tmp_target_spots from #tmp_spots where billing_date = @target_date and bonus_percent < 100

	/* set sequential_bonuses when there is a bonus allocation in the previous billing date at the same outpost_venue */
	update #tmp_target_spots set sequential_bonuses = 'Y' where exists (select * from outpost_spot where campaign_no = @campaign_no and billing_date = @prev_activity_date and outpost_panel_id = #tmp_target_spots.outpost_panel_id and spot_type in ('B','W'))

	/* set sequential_bonuses when there is a bonus allocation in the following billing date at the same outpost_venue */
	update #tmp_target_spots set sequential_bonuses = 'Y' where sequential_bonuses = 'N' and exists (select * from outpost_spot where campaign_no = @campaign_no and billing_date = @next_activity_date and outpost_panel_id = #tmp_target_spots.outpost_panel_id and spot_type in ('B','W'))

	select @rows = 0

	while ( @allocation_count_remaining + @allocation_value_remaining ) > 0
	begin
		/* first apply bonuses to outpost_venuees that will have less than or equal to 20% bonus allocations with no sequential allocations */
		exec p_op_bonus_allocations_assignment 0,20,'N',@allocation_count_remaining OUTPUT,@allocation_value_remaining OUTPUT,@rows OUTPUT
		if @rows > 0
			continue             -- loop back around until no more rows within these parameters

		/* now apply remaining bonuses to outpost_venuees that will have less than or equal to than 25% bonus allocations with no sequential allocations */
		exec p_op_bonus_allocations_assignment 20,25,'N',@allocation_count_remaining OUTPUT,@allocation_value_remaining OUTPUT,@rows OUTPUT
		if @rows > 0
			continue             -- loop back around until no more rows within these parameters

		/* now apply remaining bonuses to outpost_venuees that will have less than or equal to than 33% bonus allocations with no sequential allocations */
		exec p_op_bonus_allocations_assignment 25,33,'N',@allocation_count_remaining OUTPUT,@allocation_value_remaining OUTPUT,@rows OUTPUT
		if @rows > 0
			continue             -- loop back around until no more rows within these parameters

		/* now apply remaining bonuses to outpost_venuees that will have less than or equal to than 50% bonus allocations with no sequential allocations */
		exec p_op_bonus_allocations_assignment 33,50,'N',@allocation_count_remaining OUTPUT,@allocation_value_remaining OUTPUT,@rows OUTPUT
		if @rows > 0
			continue             -- loop back around until no more rows within these parameters

		/* now apply remaining bonuses to outpost_venuees that will have less than 75% bonus allocations with no sequential allocations */
		exec p_op_bonus_allocations_assignment 50,75,'N',@allocation_count_remaining OUTPUT,@allocation_value_remaining OUTPUT,@rows OUTPUT
		if @rows > 0
			continue             -- loop back around until no more rows within these parameters

		/* now apply remaining bonuses to outpost_venuees that will have less than 100% bonus allocations with no sequential allocations */
		exec p_op_bonus_allocations_assignment 75,100,'N',@allocation_count_remaining OUTPUT,@allocation_value_remaining OUTPUT,@rows OUTPUT
		if @rows > 0
			continue             -- loop back around until no more rows within these parameters

		/* now apply remaining bonuses to outpost_venuees that will have less than or equal to than 50% bonus allocations with sequential allocations */
		exec p_op_bonus_allocations_assignment 0,50,'Y',@allocation_count_remaining OUTPUT,@allocation_value_remaining OUTPUT,@rows OUTPUT
		if @rows > 0
			continue             -- loop back around until no more rows within these parameters

		/* now apply remaining bonuses to outpost_venuees that will have 100% bonus allocations with sequential allocations */
		exec p_op_bonus_allocations_assignment 50,100,'Y',@allocation_count_remaining OUTPUT,@allocation_value_remaining OUTPUT,@rows OUTPUT
		if @rows > 0
			continue             -- loop back around until no more rows within these parameters

		/* if we get to this point then we have allocated 100% of the spots for this date and there are still more allocations that need to be made. So now we go back and apply them to the next date */
		break

	end

	set rowcount 0

	/* add the new allocations to our temp allcoations table (only for allocation by count processing - allocation by value processing has already inserted its rows in the called proc) */
	if ( @allocation_count > 0 )
		insert #tmp_allocations select outpost_panel_id, 0, billing_date, new_bonus_allocations,0 from #tmp_target_spots where new_bonus_allocations > 0
	
	drop table #tmp_target_spots

end

set rowcount 0


/*
 * apply the bonus allocations to the campaign
 */
if ( @allocation_count > 0 )
begin
	/* allocation has been done by a count: we don't know the spot_id so read through the temp allocations table apply accordingly. */
	declare allocate_cursor cursor for
		select outpost_panel_id,billing_date,new_bonus_allocations from #tmp_allocations
	open allocate_cursor 
	fetch allocate_cursor into @allocate_outpost_panel_id,@allocate_billing_date,@new_bonus_allocations
	while ( @@fetch_status = 0 )
	begin
		set rowcount @new_bonus_allocations
		update outpost_spot
		   set charge_rate = 0,
                       spot_type = @spot_type
		from	outpost_panel
                 where outpost_spot.outpost_panel_id = outpost_panel.outpost_panel_id and
						campaign_no = @campaign_no and
                       outpost_panel.outpost_panel_id = @allocate_outpost_panel_id and
                     ( @package_id = -1 or package_id = @package_id ) and
                       billing_date = @allocate_billing_date and
                       spot_type = 'S' and
                       spot_status in ('A','P')
		set rowcount 0

		fetch allocate_cursor into @allocate_outpost_panel_id,@allocate_billing_date,@new_bonus_allocations
	end
	close allocate_cursor 
	deallocate allocate_cursor 
	set rowcount 0
end
else
begin
	/* allocation has been done by a $ value: we do know the spot_id so allocate to those spots. */
	update outpost_spot
	   set charge_rate = 0,
               spot_type = @spot_type
         where spot_id IN ( select outpost_spot from #tmp_allocations )
end	
	

/*
 * replace the allocation results for feedback
 */
select @allocation_effected = sum(new_bonus_allocations) from #tmp_allocations


/*
 * return the results
 */
select ts.outpost_panel_id,ts.outpost_venue_name,ts.billing_date,ts.spot_count,ts.bonus_allocations_count,ta.new_bonus_allocations,@allocation_count_remaining AS allocation_count_remaining, @allocation_value_remaining AS allocation_value_remaining, @allocation_effected AS allocations_applied
  from #tmp_spots ts, #tmp_allocations ta
 where ts.outpost_panel_id = ta.outpost_panel_id
  and  ts.billing_date = ta.billing_date
 order by ts.billing_date desc, ts.outpost_venue_name       

RETURN 0
GO
