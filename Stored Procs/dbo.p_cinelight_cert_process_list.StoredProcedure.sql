/****** Object:  StoredProcedure [dbo].[p_cinelight_cert_process_list]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cinelight_cert_process_list]
GO
/****** Object:  StoredProcedure [dbo].[p_cinelight_cert_process_list]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_cinelight_cert_process_list] @screening_date	datetime,
													@filter				char(1),
													@name_id				char(50)
as

/*
 * Select List
 */

select 		cplx.complex_id, 
			cplx.complex_name,
			cdpd.cinelight_locked,
			cdpd.cinelight_generation_user,
			cdpd.cinelight_revision,
			'N' as print_cert,
			'N' as trans_cert,
			cplx.film_market_no,
			cplx.branch_code,
			cplx.state_code,
			cdp.player_name,
			cdp.ip_address,
			cdp.status,
           (select 	IsNull(max(revision),-1) 
			from 	cinelight_dsn_cert_history 
			where 	player_name = cdpd.player_name 
			and 	screening_date = @screening_date
			and 	status = 'S') as last_revision,
			cdp.mu_dcmedia_flag

from 		cinelight_dsn_player_date cdpd,
			cinelight_dsn_players cdp,
			complex cplx
where 		cdpd.screening_date = @screening_date and
			cdpd.cinelight_generation is not null and
			cdpd.player_name = cdp.player_name and
			cplx.complex_id = cdp.complex_id and
			(cdpd.cinelight_generation_status = 'G' or
			cdpd.cinelight_generation_status = 'E') and
			((@filter = 'U' and cdpd.cinelight_generation_user = @name_id) or
			(@filter = '@'))
order by 	cplx.film_market_no,
			cplx.complex_name
GO
