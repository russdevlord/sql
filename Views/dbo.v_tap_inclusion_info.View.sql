/****** Object:  View [dbo].[v_tap_inclusion_info]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP VIEW [dbo].[v_tap_inclusion_info]
GO
/****** Object:  View [dbo].[v_tap_inclusion_info]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO


create view [dbo].[v_tap_inclusion_info]
as
SELECT    distinct inclusion_cinetam_settings.inclusion_id, 
				inclusion_cinetam_settings.complex_id, 
				inclusion_spot.screening_date, 
				inclusion_cinetam_settings.cinetam_reporting_demographics_id , 
				inclusion_cinetam_package.package_id
FROM		inclusion_cinetam_settings,
				inclusion_cinetam_package,
				inclusion_spot,
				inclusion
where		inclusion_cinetam_settings.inclusion_id = inclusion_cinetam_package.inclusion_id
and			inclusion_spot.inclusion_id = inclusion_cinetam_package.inclusion_id
and			inclusion_spot.inclusion_id = inclusion_cinetam_settings.inclusion_id
and			inclusion_cinetam_settings.inclusion_id = inclusion.inclusion_id
and			inclusion_type = 24
and			spot_status = 'A'
GO
