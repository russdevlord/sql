USE [production]
GO
/****** Object:  StoredProcedure [dbo].[p_mycampaign_review_revision]    Script Date: 11/03/2021 2:30:34 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_mycampaign_review_revision]			@revision_no				int,
																												@package_id			int
																												
as 

declare			@error								int,
						@campaign_no			int,
						@new_revision_no		int

set nocount on

begin transaction

update	campaign_package_revision
set			revision_status_code = 'S'
where	revision_no = @revision_no
and			package_id = @package_id

--select * 

return 0
GO
