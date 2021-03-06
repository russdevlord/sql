/****** Object:  StoredProcedure [dbo].[p_cl_certificate_gen_details]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cl_certificate_gen_details]
GO
/****** Object:  StoredProcedure [dbo].[p_cl_certificate_gen_details]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_cl_certificate_gen_details] 	@player_name			varchar(40),
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
		@complex_id				int

/*
 * Get Country and State of the Cinema Complex
 */

select @state_code = state.state_code,
       @country_code = state.country_code
  from complex,
       state,
	   cinelight_dsn_players
 where cinelight_dsn_players.player_name = @player_name and
	   complex.complex_id = cinelight_dsn_players.complex_id and
       complex.state_code = state.state_code

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
		cinelight_dsn_player_date.max_ads,
		cinelight_dsn_player_date.max_time,
		cinelight_dsn_players.presentation_format,
       	cinelight_dsn_players.player_name,
		cinelight_dsn_player_date.max_ads_trailers,
		cinelight_dsn_player_date.max_time_trailers,
		cinelight_dsn_player_date.min_ads
from	cinelight_dsn_player_date,
		cinelight_dsn_players
where	cinelight_dsn_players.player_name = @player_name
and		cinelight_dsn_players.player_name = cinelight_dsn_player_date.player_name
and		screening_date = @screening_date
GO
