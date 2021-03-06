/****** Object:  StoredProcedure [dbo].[p_schedule_inclusion_material_requirements]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_schedule_inclusion_material_requirements]
GO
/****** Object:  StoredProcedure [dbo].[p_schedule_inclusion_material_requirements]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_schedule_inclusion_material_requirements] @campaign_no	int
as
set nocount on 
/*
 * Declare Variables
 */

declare @first_spot					datetime,
        @first_screening			datetime



select 		min(inclusion_spot.screening_date),
			inclusion.inclusion_desc  
from		inclusion,
			inclusion_spot	
where       inclusion.campaign_no = @campaign_no
and			inclusion.inclusion_id = inclusion_spot.inclusion_id
and			inclusion.inclusion_type = 5
group by	inclusion.inclusion_desc



return
GO
