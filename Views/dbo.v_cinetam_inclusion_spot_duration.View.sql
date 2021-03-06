/****** Object:  View [dbo].[v_cinetam_inclusion_spot_duration]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_cinetam_inclusion_spot_duration]
GO
/****** Object:  View [dbo].[v_cinetam_inclusion_spot_duration]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
create view [dbo].[v_cinetam_inclusion_spot_duration]
as
select			inclusion_spot.inclusion_id, 
				duration 
from			inclusion_spot 
inner join		inclusion_cinetam_package on inclusion_spot.inclusion_id = inclusion_cinetam_package.inclusion_id
inner join		campaign_package on inclusion_cinetam_package.package_id = campaign_package.package_id
group by		inclusion_spot.inclusion_id, 
				duration 
GO
