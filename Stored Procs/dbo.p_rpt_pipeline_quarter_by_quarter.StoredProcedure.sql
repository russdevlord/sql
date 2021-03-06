/****** Object:  StoredProcedure [dbo].[p_rpt_pipeline_quarter_by_quarter]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_rpt_pipeline_quarter_by_quarter]
GO
/****** Object:  StoredProcedure [dbo].[p_rpt_pipeline_quarter_by_quarter]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
create PROCEDURE [dbo].[p_rpt_pipeline_quarter_by_quarter]

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

	insert into #pipeline_prospects
	exec p_pipeline_prospects
	
	
	declare @team_rep_mode			char(1),
			@mode_id				int,
			@rep_pos				int,
			@team_pos				int


	select @rep_pos = charindex('REPR', @rep_code, 1)
	select @team_pos = charindex('TEAM', @rep_code, 1)

	select 	@mode_id = convert(integer,substring(@rep_code, 5, 16))


	select cpwq.year
		   ,cpwq.quarter
		   ,cpwq.year_quarter
		   ,a.client_prospect_id
		   ,a.client_name
		   ,a.start_date
		   ,a.total_value
		   ,a.opportunity_total
		   ,a.probable_revenue
	from (select distinct quarter
		  ,year(start_date) as year
		  ,cast(quarter as CHAR(2)) + ' ' + cast(YEAR(start_date) as CHAR(4)) as year_quarter  
		  from v_accounting_period_wth_qtr
		  where year(start_date) = year(getdate())
		  or (year(end_date) =  year(dateadd(yy, 1, getdate())) and period_no in (1,2,3,4,5,6))
		  or (year(end_date) =  year(dateadd(yy, -1 , getdate())) and period_no in (7,8,9,10,11,12) ) )  as cpwq
	left join (select	client_prospect_id 
			   ,client_name
			   ,start_date
			   ,total_value
			   ,opportunity_total
			   ,(total_value * opportunity_total) as probable_revenue  
			   ,year
			   ,quarter
			   ,cast(quarter as CHAR(2)) + ' ' + cast(YEAR(start_date) as CHAR(4)) as year_quarter
			   from #pipeline_prospects
			   where rep_id = @mode_id) as a on a.year_quarter = cpwq.year_quarter
	order by cpwq.year
			 ,cpwq.quarter
END
GO
