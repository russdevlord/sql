/****** Object:  StoredProcedure [dbo].[p_add_cinead_instructions]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_add_cinead_instructions]
GO
/****** Object:  StoredProcedure [dbo].[p_add_cinead_instructions]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[p_add_cinead_instructions]

		@screening_date datetime
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	declare			@error			int,
					@rowcount		int
					
	select @rowcount = count(*)					
	from campaign_package_ins_xref
	where screening_date = @screening_date
	and package_id in (select package_id from film_campaign, campaign_package where film_campaign.campaign_no = campaign_package.campaign_no and business_unit_id = 9 )
	
	if @rowcount > 0 
	begin
		delete	campaign_package_ins_xref
		where	screening_date = @screening_date
		and		package_id in (	select	package_id 
								from	film_campaign, 
										campaign_package 
								where	film_campaign.campaign_no = campaign_package.campaign_no 
								and		business_unit_id = 9 )
	
		
	end

	insert into campaign_package_ins_xref
	select cp.package_id, @screening_date as screening_date, max(cpir.revision_no)as revison_no, 'A' as revision_status_code
	from film_campaign as fc
	inner join campaign_package as cp on cp.campaign_no = fc.campaign_no
	inner join campaign_package_ins_rev as cpir on cpir.package_id = cp.package_id
	where fc.business_unit_id = 9
	and fc.campaign_status = 'L'
	group by cp.package_id
	order by package_id
END
GO
