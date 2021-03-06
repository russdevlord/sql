/****** Object:  StoredProcedure [dbo].[p_rpt_pipeline_summary_opportunity_data]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_rpt_pipeline_summary_opportunity_data]
GO
/****** Object:  StoredProcedure [dbo].[p_rpt_pipeline_summary_opportunity_data]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
create PROCEDURE [dbo].[p_rpt_pipeline_summary_opportunity_data]
	
	@rep_code		varchar(20)

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    
	 
	-- drop table #pipeline_prospects

	create table #pipeline_prospects (
	client_prospect_id		int,
	start_date				datetime,
	end_date				datetime,
	country_code			char(1),
	business_unit_id		int,
	business_unit_desc		varchar(50),
	agency_id				int,
	agency_name				varchar(50),
	client_id				int,
	client_name				varchar(50),
	client_product_id		int,
	client_product_name		varchar(50),
	rep_id					int,
	rep_name				varchar(50),
	branch_code				char(1),
	quarter					varchar(2),
	year					int,
	no_screens				int,
	charge_rate				decimal(16,2),
	total_value				decimal(16,2),
	opportunity_total		decimal(16,2)
	)

	declare @team_rep_mode			char(1),
			@mode_id				int,
			@rep_pos				int,
			@team_pos				int

	
	insert into #pipeline_prospects
	exec p_pipeline_prospects
	
	
	select @rep_pos = charindex('REPR', @rep_code, 1)
	select @team_pos = charindex('TEAM', @rep_code, 1)

	select 	@mode_id = convert(integer,substring(@rep_code, 5, 16))

	--if @rep_pos > 0
	--begin
	--	select 	@team_rep_mode = 'R'
	--end
	--else if @team_pos > 0
	--begin
	--	select 	@team_rep_mode = 'T'
	--end
	--else
	--begin
	--	return -1        
	--end
	

	select distinct client_name
		   ,client_product_name
		   ,total_value
		   ,opportunity_total
		   , case when opportunity_total = 0 then 0
				  else (total_value * opportunity_total)
				  end as net 
		   ,cpq.client_prospect_question_id
		   ,cpq.client_prospect_question_desc
		   ,cpqx.answer
		   ,cpqg.client_prospect_question_group_id
		   ,cpqg.percentage / 100 as percentage
	from #pipeline_prospects as pp
	inner join client_prospect_question_xref as cpqx on cpqx.client_prospect_id = pp.client_prospect_id
	inner join client_prospect_question as cpq on cpq.client_prospect_question_id = cpqx.client_prospect_question_id
	inner join client_prospect_question_group cpqg on cpqg.client_prospect_question_group_id = cpq.client_prospect_question_groups_id 
	where rep_id = @mode_id
	order by client_name
			 ,client_product_name
			 ,cpqg.client_prospect_question_group_id
			 ,cpq.client_prospect_question_id
END
GO
