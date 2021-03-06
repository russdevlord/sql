/****** Object:  StoredProcedure [dbo].[p_cinelight_certificate_makeups]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cinelight_certificate_makeups]
GO
/****** Object:  StoredProcedure [dbo].[p_cinelight_certificate_makeups]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create PROC [dbo].[p_cinelight_certificate_makeups] @cinelight_player_name			varchar(100),
                                 @screening_date	   datetime
as

/*
 * Declare Variables
 */

declare @film_market_no			        int,
    @complex_id    int,
		@bonus_allowed				char(1)

/*
 * Create Makeup Table
 */

create table #makeups
(
	campaign_no				int				null,
	campaign_start			datetime		null,
	makeup_deadline	    	datetime		null,
	spot_id					int				null,
    spot_status				char(1)			null,
	spot_type				char(1)			null,
    package_id				int				null,
    screening_date			datetime		null,
    makegood_rate           money           null,
    cinema_rate             money           null,
    charge_rate             money           null,
    same_complex            int             null,
    billing_date            datetime        null,
	campaign_type			int				null
)


select @film_market_no = film_market_no,
	   @bonus_allowed = bonus_allowed,
	   @complex_id = complex_id
  from complex
 where complex_id IN (SELECT complex_id
                      FROM cinelight as cl
                        INNER JOIN cinelight_dsn_player_xref as cddx on cl.cinelight_id = cddx.cinelight_id
                      WHERE player_name = @cinelight_player_name)


         
/*
 * Insert Unallocations, No Shows, Makeups and Manuals into table
 */

--insert into #makeups
--select 	fc.campaign_no,
--		fc.start_date,
--		fc.makeup_deadline,
--		spot.spot_id,
--		spot.spot_status,
--		spot.spot_type,
--		spot.package_id,
--		spot.screening_date,
--		spot.makegood_rate,
--		spot.cinema_rate,
--		spot.charge_rate,
--		0,--CASE c.complex_id WHEN @complex_id THEN 1 ELSE 2 END,
--		spot.billing_date,
--		fc.campaign_type
--from 	film_campaign fc,
--		cinelight_spot spot,
--		complex c,
--	    cinelight panel,
--	    cinelight_package pkg
-- where pkg.package_id = spot.package_id and
--		fc.start_date <= @screening_date and
--		fc.makeup_deadline >= @screening_date and
--		fc.campaign_status = 'L' and
--		fc.campaign_no = spot.campaign_no and
--		spot.cinelight_id = panel.cinelight_id and
--		c.film_market_no = @film_market_no and		c.film_market_no = @film_market_no and
--		fc.allow_market_makeups = 'Y' and
--		spot.screening_date < @screening_date and
--		spot.spot_redirect is null and
--		(spot.spot_status = 'U' or spot.spot_status = 'N') and
--		((@bonus_allowed = 'N' and
--		  c.complex_id IN (select cdp.complex_id from cinelight_dsn_players as cdp
--                        inner join cinelight_dsn_player_xref as cdpx on cdp.player_name = cdpx.player_name
--                        inner join cinelight as cl1 on cl1.cinelight_id = cdpx.cinelight_id
--                        where cdpx.player_name = @cinelight_player_name) )
--     or (@bonus_allowed = 'Y' and  c.bonus_allowed = 'Y' and
--		 c.complex_id IN (select DISTINCT cl.complex_id
--                      from cinelight_campaign_complex ccc, cinelight cl
--                      where ccc.campaign_no = fc.campaign_no and ccc.cinelight_id = cl.cinelight_id) ))
--group by
--		fc.campaign_no,
--		fc.start_date,
--		fc.makeup_deadline,
--		spot.spot_id,
--		spot.spot_status,
--		spot.spot_type,
--		spot.package_id,
--		spot.screening_date,
--		spot.makegood_rate,
--		spot.cinema_rate,
--		spot.charge_rate,
--		spot.billing_date,
--		fc.campaign_type
--having MIN(screening_date) = screening_date


insert into #makeups
select fc.campaign_no,
       fc.start_date,
       fc.makeup_deadline,
       spot.spot_id,
       spot.spot_status,
       spot.spot_type,
       spot.package_id,
       spot.screening_date,
       spot.makegood_rate,
       spot.cinema_rate,
       spot.charge_rate,
       1,
       spot.billing_date,
	   fc.campaign_type
  from film_campaign fc,
       cinelight_spot spot,
	   cinelight_package op
 where op.package_id = spot.package_id and
		fc.start_date <= @screening_date and
       fc.makeup_deadline >= @screening_date and
       fc.campaign_status = 'L' and
       fc.campaign_no = spot.campaign_no and
       spot.cinelight_id IN (select cinelight_id from cinelight_dsn_player_xref where player_name = @cinelight_player_name) and
       --fc.allow_market_makeups = 'N' and
       spot.screening_date < @screening_date and
       spot.spot_redirect is null and
     /*( spot.spot_status = 'U' or 
       spot.spot_status = 'N'  )*/
       spot.spot_status = '*'
group by fc.campaign_no,
       fc.start_date,
       fc.makeup_deadline,
       spot.spot_id,
       spot.spot_status,
       spot.spot_type,
       spot.package_id,
       spot.screening_date,
       spot.makegood_rate,
       spot.cinema_rate,
       spot.charge_rate,
       spot.billing_date,
	   fc.campaign_type
having MIN(screening_date) = screening_date

/*
 * Return Result Set
 */

select 		mk.campaign_no,
			mk.campaign_start,
			mk.makeup_deadline,
			mk.package_id,
			op.screening_position,
			'' AS movie_brief,
			op.school_holidays,
			fc.client_id,
			'' AS follow_film,
			op.client_clash,
			op.certificate_priority,
			null,
			op.media_product_id,
			mk.makegood_rate,
			mk.cinema_rate,
			mk.charge_rate,
			mk.spot_id,
			'' AS follow_film_restricted,
			fc.allow_pack_clashing,
			op.allow_product_clashing,
			mk.billing_date,
			fc.test_campaign,
			mk.same_complex,
			'' AS premium_screen_type,
			'' AS all_movies,
			'' AS cinema_exclusive,
			0 AS movie_band_variable,
			op.used_by_date,
			op.client_diff_product,
			op.start_date,
			op.screening_trailers,
			'' AS movie_mix,
			0 AS movie_bands,
			mk.campaign_type,
			0 as remove_row,
			spot.cinelight_id
from 		#makeups mk,
			film_campaign fc,
			cinelight_package op,
			cinelight_spot spot
where		mk.campaign_no = fc.campaign_no and
			fc.campaign_no = op.campaign_no and
			op.package_id = mk.package_id 
			and mk.spot_id = spot.spot_id
order by 	mk.same_complex,
			fc.campaign_no,
			op.package_id,
			mk.charge_Rate desc
GO
