/****** Object:  View [dbo].[v_cinetam_inclusion_info]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_cinetam_inclusion_info]
GO
/****** Object:  View [dbo].[v_cinetam_inclusion_info]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

create view [dbo].[v_cinetam_inclusion_info]
as
		SELECT        inclusion_cinetam_settings.inclusion_id, inclusion_cinetam_targets.complex_id, inclusion_cinetam_targets.screening_date, 
                          inclusion_cinetam_targets.cinetam_reporting_demographics_id , 
                          inclusion_cinetam_package.package_id, inclusion.campaign_no
FROM            inclusion_cinetam_settings INNER JOIN
                         inclusion_cinetam_targets ON inclusion_cinetam_settings.inclusion_id = inclusion_cinetam_targets.inclusion_id
						 inner join inclusion_cinetam_package on inclusion_cinetam_settings.inclusion_id = inclusion_cinetam_package.inclusion_id
						 inner join inclusion on inclusion_cinetam_settings.inclusion_id = inclusion.inclusion_id
GO
