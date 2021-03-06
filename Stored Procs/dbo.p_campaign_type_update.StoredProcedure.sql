/****** Object:  StoredProcedure [dbo].[p_campaign_type_update]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_campaign_type_update]
GO
/****** Object:  StoredProcedure [dbo].[p_campaign_type_update]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_campaign_type_update] @campaign_no				integer,
                                       @old_campaign_type		tinyint,
                                       @new_campaign_type		tinyint
as

/*
 * Declare Variables
 */

declare @error     	            int,
        @new_rate		        money,
        @new_type		        char(1),
        @reset_rate	            char(1),
		@campaign_status	    char(1)

/*
 * If no change return
 */

if (@old_campaign_type = @new_campaign_type) or (@old_Campaign_type + 5 = @new_campaign_type) or (@old_campaign_type = @new_campaign_type + 5) 
	return 0

/*
 * If Campaign not Proposal Return
 */
/*
select @campaign_status = campaign_status from film_campaign where campaign_no = @campaign_no

if @campaign_status != 'P'
	return 0*/

/*
 * Initialise Variables
 */

select @reset_rate = 'N'

/*
 * Change from Normal
 */

if ((@old_campaign_type = 0) or (@old_campaign_type = 5))
begin

	/*
    * Part Contra
    */

	if ((@new_campaign_type = 1) or (@new_campaign_type = 6))
		return 0

	/*
    * Contra
    */

	if ((@new_campaign_type = 2) or (@new_campaign_type = 7))
	begin
		select @new_type = 'C'
      select @new_rate = 0
	end

	/*
    * No Charge
    */

	if ((@new_campaign_type = 3) or (@new_campaign_type = 8))
	begin
		select @new_type = 'N'
      select @new_rate = 0
	end

	/*
    * House (same as contra)
    */

	if ((@new_campaign_type = 4) or (@new_campaign_type = 9))
	begin
		select @new_type = 'C'
      select @new_rate = 0
	end


end

/*
 * Change from Part Contra
 */

if ((@old_campaign_type = 1) or (@old_campaign_type = 6))
begin

	/*
    * Normal
    */

	if ((@new_campaign_type = 0) or (@new_campaign_type = 5))
	begin
		select @new_type = 'S'
      select @reset_rate = 'Y'
	end

	/*
    * Contra
    */

	if ((@new_campaign_type = 2) or (@new_campaign_type = 7))
	begin
		select @new_type = 'C'
      select @new_rate = 0
	end

	/*
    * No Charge
    */

	if ((@new_campaign_type = 3) or (@new_campaign_type = 8))
	begin
		select @new_type = 'N'
      select @new_rate = 0
	end

	/*
    * House (same as contra)
    */

	if ((@new_campaign_type = 4) or (@new_campaign_type = 9))
	begin
		select @new_type = 'C'
      select @new_rate = 0
	end

end

/*
 * Change from Contra
 */

if ((@old_campaign_type = 2) or (@old_campaign_type = 7))
begin

	/*
    * Normal
    */

	if ((@new_campaign_type = 0) or (@new_campaign_type = 5))
	begin
		select @new_type = 'S'
		select @reset_rate = 'Y'
	end

	/*
    * Part Contra
    */

	if ((@new_campaign_type = 1) or (@new_campaign_type = 6))
		return 0

	/*
    * No Charge
    */

	if ((@new_campaign_type = 3) or (@new_campaign_type = 8))
	begin
		select @new_type = 'N'
      select @new_rate = 0
	end

	/*
    * House (same as contra)
    */

	if ((@new_campaign_type = 4) or (@new_campaign_type = 9))
	begin
		select @new_type = 'C'
      select @new_rate = 0
	end


end

/*
 * Change from No Charge
 */

if ((@old_campaign_type = 3) or (@old_campaign_type = 8))
begin

	/*
    * Normal
    */

	if ((@new_campaign_type = 0) or (@new_campaign_type = 5))
	begin
		select @new_type = 'S'
		select @reset_rate = 'Y'
	end

	/*
    * Part Contra
    */

	if ((@new_campaign_type = 1) or (@new_campaign_type = 6))
	begin
		select @new_type = 'C'
      select @new_rate = 0
	end

	/*
    * Contra
    */

	if ((@new_campaign_type = 2) or (@new_campaign_type = 7))
	begin
		select @new_type = 'C'
      select @new_rate = 0
	end

	/*
    * No Charge
    */

	if ((@new_campaign_type = 4) or (@new_campaign_type = 9))
	begin
		select @new_type = 'C'
      select @new_rate = 0
	end

end

/*
 * Change from House
 */

if ((@old_campaign_type = 4) or (@old_campaign_type = 9))
begin

	/*
    * Normal
    */

	if ((@new_campaign_type = 0) or (@new_campaign_type = 5))
	begin
		select @new_type = 'S'
		select @reset_rate = 'Y'
	end

	/*
    * Part Contra
    */

	if ((@new_campaign_type = 1) or (@new_campaign_type = 6))
	begin
		select @new_type = 'C'
      select @new_rate = 0
	end

	/*
    * Contra
    */

	if ((@new_campaign_type = 2) or (@new_campaign_type = 7))
	begin
		select @new_type = 'C'
      select @new_rate = 0
	end

	/*
    * House (same as contra)
    */

	if ((@new_campaign_type = 4) or (@new_campaign_type = 9))
	begin
		select @new_type = 'C'
      select @new_rate = 0
	end


end

/*
 * Begin Transaction
 */

begin transaction

/*
 * Update Spots
 */

if (@reset_rate = 'Y')
begin

	update 	campaign_spot  
	set 	charge_rate = campaign_package.charge_rate,
			spot_type = @new_type
	from 	campaign_package
	where 	campaign_spot.campaign_no = @campaign_no and
			spot_type not in ('B','V','M') and
			campaign_spot.package_id = campaign_package.package_id and
			campaign_spot.campaign_no = campaign_package.campaign_no 
	
	select @error = @@error
	if ( @error !=0 )
	begin
		raiserror ('Error Russ is looking for', 16, 1)
		rollback transaction
		return -1
	end	

end
else
begin

	update campaign_spot  
		set charge_rate = @new_rate,
          spot_type = @new_type
	 where campaign_no = @campaign_no and
			 spot_type not in ('B','V','M')
	
	select @error = @@error
	if ( @error !=0 )
	begin
			raiserror ('Error Russ is looking for 2', 16, 1)
		rollback transaction
		return -1
	end	

end

/*
 * Commit and Return
 */

commit transaction
return 0
GO
