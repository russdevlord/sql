USE [production]
GO
/****** Object:  View [dbo].[v_cinelight_shell_certificate_item_distinct]    Script Date: 11/03/2021 2:30:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE VIEW [dbo].[v_cinelight_shell_certificate_item_distinct]
AS

    select      distinct shell_code,
				print_id,
				cinelight_id,
				screening_date
    from        cinelight_shell_certificate_xref,
				cinelight_certificate_item,
				cinelight_dsn_player_xref
	where		cinelight_shell_certificate_xref.certificate_item_id = cinelight_certificate_item.certificate_item_id
	and			cinelight_certificate_item.player_name = cinelight_dsn_player_xref.player_name
    group by    shell_code,
				print_id,
				cinelight_id,
				screening_date
GO
