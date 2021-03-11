USE [production]
GO
/****** Object:  View [dbo].[v_inclusion_cinetam_targets_no_complex]    Script Date: 11/03/2021 2:30:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


create view [dbo].[v_inclusion_cinetam_targets_no_complex]
as
select			inclusion_id,
					cinetam_reporting_demographics_id,
					screening_date,
					isnull(sum(target_attendance),0) as target_attendance,
					isnull(sum(achieved_attendance), 0) as achieved_attendance,
					isnull(sum(original_target_attendance), 0) as original_target_attendance
from				inclusion_cinetam_targets
group by		inclusion_id,
					cinetam_reporting_demographics_id,
					screening_date
GO
