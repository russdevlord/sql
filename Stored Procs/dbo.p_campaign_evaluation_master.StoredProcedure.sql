/****** Object:  StoredProcedure [dbo].[p_campaign_evaluation_master]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_campaign_evaluation_master]
GO
/****** Object:  StoredProcedure [dbo].[p_campaign_evaluation_master]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_campaign_evaluation_master]  	@campaign_no 			int,
											@movie_breakdown		char(1)

as 

declare		@onscreen_exists			char(1),
			@digilite_exists			char(1)

set nocount on

if exists (select 1 from campaign_spot where campaign_no = @campaign_no)
	select @onscreen_exists = 'Y'
else
	select @onscreen_exists = 'N'


if exists (select 1 from cinelight_spot where campaign_no = @campaign_no)
	select @digilite_exists = 'Y'
else
	select @digilite_exists = 'N'

select @campaign_no, @movie_breakdown, @onscreen_exists,@digilite_exists
return 0
GO
