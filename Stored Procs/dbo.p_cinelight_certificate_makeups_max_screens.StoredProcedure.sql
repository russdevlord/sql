/****** Object:  StoredProcedure [dbo].[p_cinelight_certificate_makeups_max_screens]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cinelight_certificate_makeups_max_screens]
GO
/****** Object:  StoredProcedure [dbo].[p_cinelight_certificate_makeups_max_screens]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create PROC [dbo].[p_cinelight_certificate_makeups_max_screens]	@player_name			varchar(100),
														@screening_date	   datetime
as

/*
 * Declare Variables
 */

declare @market_no             int,
		@bonus_allowed				char(1)

/*
 * Create Makeup Table
 */

create table #makeups
(
	campaign_no				int				null
)

select @market_no = film_market_no,
	   @bonus_allowed = bonus_allowed
  from complex, cinelight_dsn_players
 where cinelight_dsn_players.player_name = @player_name
  and  complex.complex_id = cinelight_dsn_players.complex_id
         
/*
 * Insert Unallocations, No Shows, Makeups and Manuals into table
 */

insert into #makeups
select 	distinct fc.campaign_no
from 	film_campaign fc,
		cinelight_spot spot,
		cinelight outpanel,
		complex outv
where 	fc.start_date <= @screening_date and
		fc.makeup_deadline >= @screening_date and
		fc.campaign_status = 'L' and
		fc.campaign_no = spot.campaign_no and
		spot.cinelight_id = outpanel.cinelight_id and
		outv.complex_id = outpanel.complex_id and
		outv.film_market_no = @market_no and
		fc.allow_market_makeups = 'Y' and
		spot.screening_date < @screening_date and
-- DH	spot.film_plan_id is null and
		spot.spot_redirect is null and
		(spot.spot_status = 'U' or
		spot.spot_status = 'N') and
		((@bonus_allowed = 'N' and
		  outv.complex_id IN (select complex_id from cinelight_dsn_players
                          where player_name = @player_name) ) or
		(@bonus_allowed = 'Y' and
		 outv.bonus_allowed = 'Y' and
		 outv.complex_id IN (select DISTINCT opnl.complex_id
                         from cinelight_campaign_complex ocp,
                              cinelight opnl
                         where ocp.campaign_no = fc.campaign_no
                         and opnl.cinelight_id = ocp.cinelight_id) ))
       
insert into #makeups
select distinct fc.campaign_no
  from film_campaign fc,
       cinelight_spot spot,
       cinelight outpanel
 where fc.start_date <= @screening_date and
       fc.makeup_deadline >= @screening_date and
       fc.campaign_status = 'L' and
       fc.campaign_no = spot.campaign_no and
       spot.cinelight_id = outpanel.cinelight_id and
	   outpanel.cinelight_id = (select MIN(cinelight_id) from cinelight_dsn_player_xref where player_name = @player_name) and
       fc.allow_market_makeups = 'N' and
       spot.screening_date < @screening_date and
       spot.spot_redirect is null and
-- DH  spot.film_plan_id is null and
     ( spot.spot_status = 'U' or 
       spot.spot_status = 'N'  )       

/*
 * Return Result Set
 */

select		#makeups.campaign_no,
			temp_table.package_id, 
			isnull(max(temp_table.no_spots),0)
FROM	(select 	cinelight_spot.campaign_no, 
					screening_date, 
					cinelight_spot.package_id,
					count(spot_id) as no_spots
		from 		cinelight_spot,
					#makeups
		where		cinelight_spot.campaign_no = #makeups.campaign_no
		and			cinelight_id IN (select MIN(cinelight_id) from cinelight_dsn_player_xref where player_name = @player_name)
		and			spot_type not in ('M','V')
		group by	cinelight_spot.campaign_no, 
					cinelight_spot.package_id,
					screening_date) as temp_table LEFT OUTER JOIN
					  #makeups ON #makeups.campaign_no = temp_table.campaign_no
group by 	#makeups.campaign_no,
			temp_table.package_id
GO
