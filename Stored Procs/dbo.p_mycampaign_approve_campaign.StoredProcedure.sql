/****** Object:  StoredProcedure [dbo].[p_mycampaign_approve_campaign]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_mycampaign_approve_campaign]
GO
/****** Object:  StoredProcedure [dbo].[p_mycampaign_approve_campaign]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_mycampaign_approve_campaign]  @revision_no				int,
																												@package_id			int
																												
as 

declare			@error								int,
						@campaign_no			int,
						@new_revision_no		int

set nocount on

begin transaction

--Loop Packages of Campaign and copy any submitted revisions over to the live package and update the revision to approved

declare		submitted_revision_csr cursor for
select		package_id, 
					revision_no
from			campaign_package_revision
where		revision_status_code = 'S'
and				package_id in (select package_id from campaign_package where campaign_no in (select campaign_no from campaign_package where package_id = @package_id))



commit transaction
return 0
GO
