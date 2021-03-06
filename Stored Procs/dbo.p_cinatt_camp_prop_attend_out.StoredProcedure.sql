/****** Object:  StoredProcedure [dbo].[p_cinatt_camp_prop_attend_out]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cinatt_camp_prop_attend_out]
GO
/****** Object:  StoredProcedure [dbo].[p_cinatt_camp_prop_attend_out]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_cinatt_camp_prop_attend_out] @campaign_no integer, @actual_attendance integer OUTPUT
as

/* Gets total estimated attendance for campaign proposal */

/*
 * Declare Variables
 */

declare @error        			integer,
        @rowcount     			integer,
        @errorode						integer,
        @errno						integer,
        @spot_csr_open			tinyint,
        @film_market_no			integer,
        @spot_id					integer,
        @complex_id				integer,
        @package_id				integer,
        @screening_date			datetime,
        @spot_status				char(1),
        @pack_code				char(1),
        @estimated_attendance	integer,
        @attendance				integer,
        @movie_id					integer,
        @actual					char(1),
        @regional_indicator     char(1)

select @actual_attendance = 0

/* do not process if analysis not allowed */
if exists
        (select 1
         from   film_campaign
         where  campaign_no = @campaign_no
         and    attendance_analysis = 'Y')
begin

    select  @actual_attendance = sum(attendance)
    from    film_cinatt_estimates
    where   campaign_no = @campaign_no

end


/*
 * Return Success
 */

return 0
GO
