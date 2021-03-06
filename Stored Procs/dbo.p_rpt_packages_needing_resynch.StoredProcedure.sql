/****** Object:  StoredProcedure [dbo].[p_rpt_packages_needing_resynch]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_rpt_packages_needing_resynch]
GO
/****** Object:  StoredProcedure [dbo].[p_rpt_packages_needing_resynch]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[p_rpt_packages_needing_resynch]

		@mode			int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	/*
		key
		1 = Digilites
	*/
	if @mode = 1
	begin
		select distinct cp.campaign_no,cp.package_desc, package_code, a.msg, a.screening_date 
		from(
		select 'No segments' as msg, spot_id, campaign_no, package_id, screening_date, cinelight_id 
		from cinelight_spot 
		where spot_id not in (select spot_id 
    						  from cinelight_spot_daily_segment 
							  where spot_id = cinelight_spot.spot_id) 
		and screening_date > '1-jul-2015' 
		union  
		select 'Segments do not match week' as msg, spot_id, campaign_no, package_id, screening_date, cinelight_id
		from cinelight_spot 
		where spot_id not in (select spot_id 
							  from cinelight_spot_daily_segment 
							  where spot_id = cinelight_spot.spot_id 
							  and start_date between cinelight_spot.screening_date and dateadd(ss, -1, dateadd(dd, 7, cinelight_spot.screening_date)) 
							  and end_date between cinelight_spot.screening_date and dateadd(ss, -1, dateadd(dd, 7, cinelight_spot.screening_date))) 
		and screening_date > '1-jul-2015') as a
		inner join cinelight_package as cp on cp.package_id = a.package_id and cp.campaign_no = a.campaign_no
		order by cp.campaign_no, package_code
	end
	else if @mode = 2
	begin
		select distinct cp.campaign_no,cp.package_desc, package_code, a.msg, a.screening_date 
		from(
		select 'No segments' as msg, spot_id, campaign_no, package_id, screening_date, outpost_panel_id 
		from outpost_spot 
		where spot_id not in (select spot_id 
							  from outpost_spot_daily_segment 
							  where spot_id = outpost_spot.spot_id) 
		and screening_date > '1-jul-2015' 
		and campaign_no in (select campaign_no from film_campaign where business_unit_id = 6 ) 
		union  
		select 'Segments do not match week' as msg, spot_id, campaign_no, package_id, screening_date, outpost_panel_id 
		from outpost_spot 
		where spot_id not in (select spot_id 
							  from outpost_spot_daily_segment 
							  where spot_id = outpost_spot.spot_id 
							  and start_date between outpost_spot.screening_date and dateadd(ss, -1, dateadd(dd, 7, outpost_spot.screening_date)) 
							  and end_date between outpost_spot.screening_date and dateadd(ss, -1, dateadd(dd, 7, outpost_spot.screening_date))) 
		and screening_date > '1-jul-2015'
		and campaign_no in (select campaign_no from film_campaign where business_unit_id = 6 ) ) as a
		inner join outpost_package as cp on cp.package_id = a.package_id and cp.campaign_no = a.campaign_no
		order by cp.campaign_no, package_code
	end 
END
GO
