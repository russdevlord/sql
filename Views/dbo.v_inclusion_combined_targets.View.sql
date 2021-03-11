USE [production]
GO
/****** Object:  View [dbo].[v_inclusion_combined_targets]    Script Date: 11/03/2021 2:30:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



create view [dbo].[v_inclusion_combined_targets]
as
select			inclusion_id,
					screening_date,
					complex_id,
					isnull(sum(original_target_attendance), 0) as original_target_attendance
from				inclusion_cinetam_targets
group by		inclusion_id,
					complex_id,
					screening_date
union all		
select			inclusion_id,
					screening_date,
					complex_id,
					isnull(sum(original_target_attendance), 0) as original_target_attendance
from				inclusion_cinetam_targets
group by		inclusion_id,
					complex_id,
					screening_date

GO
