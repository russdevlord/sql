/****** Object:  StoredProcedure [dbo].[p_op_certificate_gen_details]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_op_certificate_gen_details]
GO
/****** Object:  StoredProcedure [dbo].[p_op_certificate_gen_details]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_op_certificate_gen_details] 	@player_name			varchar(40),
                                      		@screening_date			datetime  
as

/*
 * Declare Variables
 */

declare @error					int,
        @errorode					int,
        @count					int,
        @state_code     	    char(3),
        @country_code		    char(1),
        @school_holidays	    char(1),
		@outpost_venue_id				int

/*
 * Get Country and State of the Cinema outpost_venue
 */

select @state_code = state.state_code,
       @country_code = state.country_code
  from outpost_venue,
       state,
	   outpost_player
 where outpost_player.player_name = @player_name and
	   outpost_venue.outpost_venue_id = outpost_player.outpost_venue_id and
       outpost_venue.state_code = state.state_code

/*
 * Determine if its School Holidays 
 */

select @count = isnull(count(screening_date),0)
  from school_holiday_xref
 where state_code = @state_code and
       screening_date = @screening_date

if (@count > 0)
	select @school_holidays = 'Y'
else
	select @school_holidays = 'N'

/*
 * Return Dataset
 */

select 	1,
		@school_holidays,
       	@country_code,
		outpost_player_date.max_ads,
		outpost_player_date.max_time,
		outpost_player.presentation_format,
       	outpost_player.player_name,
		outpost_player_date.max_ads_trailers,
		outpost_player_date.max_time_trailers
from	outpost_player_date,
		outpost_player
where	outpost_player.player_name = @player_name
and		outpost_player.player_name = outpost_player_date.player_name
and		screening_date = @screening_date
GO
