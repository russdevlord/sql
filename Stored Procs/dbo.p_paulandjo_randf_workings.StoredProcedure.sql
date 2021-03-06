/****** Object:  StoredProcedure [dbo].[p_paulandjo_randf_workings]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_paulandjo_randf_workings]
GO
/****** Object:  StoredProcedure [dbo].[p_paulandjo_randf_workings]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_paulandjo_randf_workings] @campaign_no			int

as

declare		@digitlite_attendance			int,
					@onscreen_not_at_digilite		int,
					@total_onscreen							int
					
create table #paulandjo
(
	digitlite_attendance					int,
	onscreen_not_at_digilite		int,
	total_onscreen							int
)					

select @digitlite_attendance = sum(attendance) from cinelight_attendance_digilite_actuals where campaign_no = @campaign_no  

select @onscreen_not_at_digilite = sum(attendance) from attendance_campaign_complex_actuals where campaign_no = @campaign_no   and complex_id not in (select complex_id from cinelight_spot, cinelight where campaign_no = @campaign_no  and cinelight_spot.cinelight_id  = cinelight.cinelight_id )

select @total_onscreen = sum(attendance) from attendance_campaign_complex_actuals where campaign_no = @campaign_no 

insert into #paulandjo values (@digitlite_attendance,@onscreen_not_at_digilite, @total_onscreen)

select * from #paulandjo

return 0
GO
