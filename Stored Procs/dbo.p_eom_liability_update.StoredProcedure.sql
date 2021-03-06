/****** Object:  StoredProcedure [dbo].[p_eom_liability_update]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_eom_liability_update]
GO
/****** Object:  StoredProcedure [dbo].[p_eom_liability_update]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create proc [dbo].[p_eom_liability_update] @mode                    int,
                                  @accounting_period       datetime
as
set nocount on 
/*
 * Declare Variables
 */
 
declare @error          int,
        @rowcount       int,
        @cutoff_period  datetime

/*
 * Get Cinema Agreement Cut Over Period
 */


select @cutoff_period = convert(datetime, parameter_string) 
  from system_parameters 
 where parameter_name = 'cinema_agreement_cut'

select @error = @@error,
       @rowcount = @@rowcount
       
if @error != 0 or @rowcount != 1 
begin
    rollback transaction
    raiserror ('There was an error obtaining Cinema Agreement Cut Over Period.', 16, 1)
    return -100
end

/*
 * Begin Transaction
 */       

begin transaction

/*
 * Ensure that the Oscreen Flag has been set correctly on Campaign Spots
 */

if @mode = 1
begin
    update campaign_spot
       set onscreen = 'Y'
      from film_screening_dates fsd
     where campaign_spot.screening_date = fsd.screening_date
       and fsd.screening_date_status = 'X'
       and campaign_spot.onscreen = 'N'
       and campaign_spot.spot_status = 'N' -- no show

    select @error = @@error
    if @error != 0
    begin
        rollback transaction
        raiserror ('There was an error updating the ONSCREEN flag in the Campaign Spot table for No Show spots.', 16, 1)
        return -100
    end
end

if @mode = 2 
begin
    update campaign_spot
       set onscreen = 'Y'
      from film_screening_dates fsd
     where campaign_spot.screening_date = fsd.screening_date
       and fsd.screening_date_status = 'X'
       and campaign_spot.onscreen = 'N'
       and campaign_spot.spot_status = 'X' -- allocated


    select @error = @@error
    if @error != 0
    begin
        rollback transaction
        raiserror ('There was an error updating the ONSCREEN flag in the Campaign Spot table for Allocated spots.', 16, 1)
        return -100
    end
end

/*
 * Set Creation Period for Spot Liability
 */

if @mode = 3 
begin
    update spot_liability
       set creation_period = @accounting_period
     where creation_period is null
     
    select @error = @@error
    if @error != 0
    begin
        rollback transaction
        raiserror ('There was an error updating the Creation Period on the Spot Liability table.', 16, 1)
        return -100
    end

    update cinelight_spot_liability
       set creation_period = @accounting_period
     where creation_period is null
     
    select @error = @@error
    if @error != 0
    begin
        rollback transaction
        raiserror ('There was an error updating the Creation Period on the Cinelight Spot Liability table.', 16, 1)
        return -100
    end

--     update inclusion_spot_liability
--        set creation_period = @accounting_period
--      where creation_period is null
--      
--     select @error = @@error
--     if @error != 0
--     begin
--         rollback transaction
--         raiserror ('There was an error updating the Creation Period on the Inclusion Spot Liability table.', 16, 1)
--         return -100
--     end
end
 
/*
 * Set Prior To Cut Over Origin Period 
 */
 
if @mode = 4
begin
    update spot_liability
       set origin_period = campaign_spot.billing_period
      from campaign_spot
     where spot_liability.origin_period is null 
       and campaign_spot.spot_id = spot_liability.spot_id
       and campaign_spot.billing_period < @cutoff_period
       
    select @error = @@error
    if @error != 0
    begin
        rollback transaction
        raiserror ('There was an error updating the Prior Origin Period on the Spot Liability table.', 16, 1)
        return -100
    end

    update cinelight_spot_liability
       set origin_period = cinelight_spot.billing_period
      from cinelight_spot
     where cinelight_spot_liability.origin_period is null 
       and cinelight_spot.spot_id = cinelight_spot_liability.spot_id
       and cinelight_spot.billing_period < @cutoff_period
       
    select @error = @@error
    if @error != 0
    begin
        rollback transaction
        raiserror ('There was an error updating the Prior Origin Period on the Cinelight Spot Liability table.', 16, 1)
        return -100
    end

--     update inclusion_spot_liability
--        set origin_period = inclusion_spot.billing_period
--       from inclusion_spot
--      where inclusion_spot_liability.origin_period is null 
--        and inclusion_spot.spot_id = inclusion_spot_liability.spot_id
--        and inclusion_spot.billing_period < @cutoff_period
--        
--     select @error = @@error
--     if @error != 0
--     begin
--         rollback transaction
--         raiserror ('There was an error updating the Prior Origin Period on the Inclusion Spot Liability table.', 16, 1)
--         return -100
--     end
end

/*
 * Set After Cut Over Origin Period 
 */
 
if @mode = 5
begin
    update spot_liability
       set origin_period = film_screening_dates.billing_period
      from campaign_spot,
           film_screening_dates
     where spot_liability.origin_period is null 
       and campaign_spot.spot_id = spot_liability.spot_id
       and campaign_spot.onscreen = 'Y'
       and film_screening_dates.screening_date = campaign_spot.screening_date
       and campaign_spot.billing_period >= @cutoff_period
       
    select @error = @@error
    if @error != 0
    begin
        rollback transaction
        raiserror ('There was an error updating the Post Origin Period on the Spot Liability table.', 16, 1)
        return -100
    end

    update cinelight_spot_liability
       set origin_period = film_screening_dates.billing_period
      from cinelight_spot,
           film_screening_dates
     where cinelight_spot_liability.origin_period is null 
       and cinelight_spot.spot_id = cinelight_spot_liability.spot_id
       and cinelight_spot.spot_status = 'X'
       and film_screening_dates.screening_date = cinelight_spot.screening_date
       and cinelight_spot.billing_period >= @cutoff_period
       
    select @error = @@error
    if @error != 0
    begin
        rollback transaction
        raiserror ('There was an error updating the Post Origin Period on the Cinelight Spot Liability table.', 16, 1)
        return -100
    end

--     update inclusion_spot_liability
--        set origin_period = film_screening_dates.billing_period
--       from inclusion_spot,
--            film_screening_dates
--      where inclusion_spot_liability.origin_period is null 
--        and inclusion_spot.spot_id = inclusion_spot_liability.spot_id
--        and inclusion_spot.spot_status = 'X'
--        and film_screening_dates.screening_date = inclusion_spot.screening_date
--        and inclusion_spot.billing_period >= @cutoff_period
--        
--     select @error = @@error
--     if @error != 0
--     begin
--         rollback transaction
--         raiserror ('There was an error updating the Post Origin Period on the inclusion Spot Liability table.', 16, 1)
--         return -100
--     end
end
 
/*
 * Release any prior spot liability records whose corresponding spot has Onscreen flag set to 'Y'
 */

if @mode = 6 
begin
    update spot_liability
       set release_period = @accounting_period
      from campaign_spot,
           liability_type
     where spot_liability.release_period is null
       and spot_liability.origin_period is not null
       and campaign_spot.spot_id = spot_liability.spot_id
       and campaign_spot.billing_period < @cutoff_period
       and spot_liability.liability_type = liability_type.liability_type_id
       and liability_type.liability_category_id <> 6 -- Collection
       
    select @error = @@error
    if @error != 0
    begin
        rollback transaction
        raiserror ('There was an error updating the Release Period on the Spot Liability for Pre Cutover Spots.', 16, 1)
        return -100
    end

    update cinelight_spot_liability
       set release_period = @accounting_period
      from cinelight_spot,
           liability_type
     where cinelight_spot_liability.release_period is null
       and cinelight_spot_liability.origin_period is not null
       and cinelight_spot.spot_id = cinelight_spot_liability.spot_id
       and cinelight_spot.billing_period < @cutoff_period
       and cinelight_spot_liability.liability_type = liability_type.liability_type_id
       and liability_type.liability_category_id <> 6 -- Collection
       
    select @error = @@error
    if @error != 0
    begin
        rollback transaction
        raiserror ('There was an error updating the Release Period on the Spot Liability for Pre Cutover Spots.', 16, 1)
        return -100
    end

--     update inclusion_spot_liability
--        set release_period = @accounting_period
--       from inclusion_spot,
--            liability_type
--      where inclusion_spot_liability.release_period is null
--        and inclusion_spot_liability.origin_period is not null
--        and inclusion_spot.spot_id = inclusion_spot_liability.spot_id
--        and inclusion_spot.billing_period < @cutoff_period
--        and inclusion_spot_liability.liability_type = liability_type.liability_type_id
--        and liability_type.liability_category_id <> 6 -- Collection
--        
--     select @error = @@error
--     if @error != 0
--     begin
--         rollback transaction
--         raiserror ('There was an error updating the Release Period on the Spot Liability for Pre Cutover Spots.', 16, 1)
--         return -100
--     end
end

if @mode = 7 
begin
    update spot_liability
       set release_period = @accounting_period
      from campaign_spot,
           liability_type
     where spot_liability.release_period is null
       and spot_liability.origin_period is not null
       and campaign_spot.onscreen = 'Y'
       and campaign_spot.spot_id = spot_liability.spot_id
       and campaign_spot.billing_period < @cutoff_period
       and spot_liability.liability_type = liability_type.liability_type_id
       and liability_type.liability_category_id = 6 -- Collection
       
    select @error = @@error
    if @error != 0
    begin
        rollback transaction
        raiserror ('There was an error updating the Release Period on the Collection Spot Liability for Pre Cutover Spots.', 16, 1)
        return -100
    end

    update cinelight_spot_liability
       set release_period = @accounting_period
      from cinelight_spot,
           liability_type
     where cinelight_spot_liability.release_period is null
       and cinelight_spot_liability.origin_period is not null
       and cinelight_spot.spot_status = 'X'
       and cinelight_spot.spot_id = cinelight_spot_liability.spot_id
       and cinelight_spot.billing_period < @cutoff_period
       and cinelight_spot_liability.liability_type = liability_type.liability_type_id
       and liability_type.liability_category_id = 6 -- Collection
       
    select @error = @@error
    if @error != 0
    begin
        rollback transaction
        raiserror ('There was an error updating the Release Period on the Collection Cinelight Spot Liability for Pre Cutover Spots.', 16, 1)
        return -100
    end

--     update inclusion_spot_liability
--        set release_period = @accounting_period
--       from inclusion_spot,
--            liability_type
--      where inclusion_spot_liability.release_period is null
--        and inclusion_spot_liability.origin_period is not null
--        and inclusion_spot.spot_status = 'X'
--        and inclusion_spot.spot_id = inclusion_spot_liability.spot_id
--        and inclusion_spot.billing_period < @cutoff_period
--        and inclusion_spot_liability.liability_type = liability_type.liability_type_id
--        and liability_type.liability_category_id = 6 -- Collection
--        
--     select @error = @@error
--     if @error != 0
--     begin
--         rollback transaction
--         raiserror ('There was an error updating the Release Period on the Collection inclusion Spot Liability for Pre Cutover Spots.', 16, 1)
--         return -100
--     end

end

/*
 * Release Spot Liability Gone to Screen for Post Cut Over Period Spots
 */
 
if @mode = 8 
begin
    update spot_liability
       set release_period = @accounting_period
      from campaign_spot
     where spot_liability.release_period is null
       and spot_liability.origin_period is not null
       and campaign_spot.onscreen = 'Y'
       and campaign_spot.billing_period >= @cutoff_period
       and campaign_spot.spot_id = spot_liability.spot_id
          
    select @error = @@error
    if @error != 0
    begin
        rollback transaction
        raiserror ('There was an error updating the Release Period on the Spot Liability for Post Cutover Spots.', 16, 1)
        return -100
    end

    update cinelight_spot_liability
       set release_period = @accounting_period
      from cinelight_spot
     where cinelight_spot_liability.release_period is null
       and cinelight_spot_liability.origin_period is not null
       and cinelight_spot.spot_status = 'X'
       and cinelight_spot.billing_period >= @cutoff_period
       and cinelight_spot.spot_id = cinelight_spot_liability.spot_id
          
    select @error = @@error
    if @error != 0
    begin
        rollback transaction
        raiserror ('There was an error updating the Release Period on the Cinelight Spot Liability for Post Cutover Spots.', 16, 1)
        return -100
    end

--     update inclusion_spot_liability
--        set release_period = @accounting_period
--       from inclusion_spot
--      where inclusion_spot_liability.release_period is null
--        and inclusion_spot_liability.origin_period is not null
--        and inclusion_spot.spot_status = 'X'
--        and inclusion_spot.billing_period >= @cutoff_period
--        and inclusion_spot.spot_id = inclusion_spot_liability.spot_id
--           
--     select @error = @@error
--     if @error != 0
--     begin
--         rollback transaction
--         raiserror ('There was an error updating the Release Period on the inclusion Spot Liability for Post Cutover Spots.', 16, 1)
--         return -100
--     end
end
 
/*
 * Commit and Return Success
 */


commit transaction
return 0
GO
